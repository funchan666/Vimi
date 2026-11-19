import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dance_repository.dart';
import 'local_studio.dart';
import 'models.dart';

class AppController extends ChangeNotifier {
  AppController({required this.studio, this.repo});
  final LocalStudio studio;
  final DanceRepository? repo;
  List<ChoreographyPrompt> challenges = [];
  List<PracticeSession> practices = [];
  Dancer? profile;
  int coins = 0;
  int reversalDebt = 0;
  String accountStatus = 'active';
  bool recoveringPassword = false;
  Set<String> unlocked = {};
  bool exploring = false, authBusy = false;
  bool resumingGuestAction = false;
  String? journalError;
  String? cloudError;
  int revision = 0, _generation = 0;
  bool _disposed = false;
  StreamSubscription<AuthState>? _auth;
  RealtimeChannel? _channel;
  bool get signedIn => repo?.client.auth.currentSession != null;
  String get account => repo?.client.auth.currentUser?.id ?? 'guest';
  bool get isModerator =>
      repo?.client.auth.currentUser?.appMetadata['vimi_role'] == 'moderator';
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    challenges = jsonRows(
      jsonDecode(await rootBundle.loadString('assets/data/challenges.json')),
    ).map(ChoreographyPrompt.fromJson).toList();
    _auth = repo?.client.auth.onAuthStateChange.listen(
      (event) {
        if (event.event == AuthChangeEvent.signedOut) {
          exploring = false;
          recoveringPassword = false;
        }
        if (event.event == AuthChangeEvent.passwordRecovery) {
          recoveringPassword = true;
          _emit();
        }
        if (event.event == AuthChangeEvent.signedOut ||
            event.event == AuthChangeEvent.signedIn ||
            event.event == AuthChangeEvent.userUpdated) {
          unawaited(
            refreshAccount().catchError((Object e) {
              cloudError = readableError(e);
              _emit();
            }),
          );
        }
      },
      onError: (Object error, StackTrace stack) {
        cloudError = readableError(error);
        _emit();
      },
    );
    await refreshAccount();
  }

  Future<void> refreshAccount() async {
    final generation = ++_generation;
    final owner = account;
    profile = null;
    coins = 0;
    reversalDebt = 0;
    accountStatus = 'active';
    unlocked = {};
    practices = [];
    revision++;
    final old = _channel;
    _channel = null;
    if (old != null) await repo?.client.removeChannel(old);
    _emit();
    try {
      final saved = await studio.load(owner);
      if (generation != _generation) return;
      practices = saved;
      journalError = null;
    } catch (e) {
      journalError =
          'Your journal could not be opened. Your saved data has been kept.';
    }
    if (signedIn) {
      try {
        final repository = repo!;
        final status = await repository.client.rpc('account_status');
        if (generation != _generation || owner != account) return;
        accountStatus = status as String? ?? 'unavailable';
        if (accountStatus != 'active') {
          _emit();
          return;
        }
        final values = await Future.wait<dynamic>([
          repository.dancer(owner),
          repository.balance(),
          repository.unlocks(),
          repository.reversalDebt(),
        ]);
        if (generation != _generation || owner != account) return;
        profile = values[0] as Dancer?;
        coins = values[1] as int;
        unlocked = values[2] as Set<String>;
        reversalDebt = values[3] as int;
        _channel = repository.client
            .channel('vimi-inbox-$owner')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'recipient_id',
                value: owner,
              ),
              callback: (_) => changed(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'sender_id',
                value: owner,
              ),
              callback: (_) => changed(),
            )
            .subscribe();
        cloudError = null;
      } catch (error) {
        cloudError = readableError(error);
      }
    }
    if (generation == _generation) _emit();
  }

  void explore() {
    exploring = true;
    _emit();
  }

  void changed() {
    revision++;
    _emit();
  }

  Future<void> refreshWallet() async {
    if (!signedIn) return;
    final owner = account;
    final values = await Future.wait<dynamic>([
      repo!.balance(),
      repo!.unlocks(),
      repo!.reversalDebt(),
    ]);
    if (owner != account) return;
    coins = values[0] as int;
    unlocked = values[1] as Set<String>;
    reversalDebt = values[2] as int;
    _emit();
  }

  Future<void> savePractice(PracticeSession session) async {
    if (journalError != null)
      throw StateError('Journal recovery is required before saving.');
    final owner = account;
    final updated = await studio.update(
      owner,
      (saved) => [session, ...saved.where((p) => p.id != session.id)],
    );
    if (owner == account) {
      practices = updated;
      _emit();
    }
  }

  Future<void> removePractice(String id) async {
    if (journalError != null) {
      throw StateError('Journal recovery is required before deleting.');
    }
    final owner = account;
    final updated = await studio.update(
      owner,
      (saved) => saved.where((p) => p.id != id).toList(),
    );
    if (owner == account) {
      practices = updated;
      _emit();
    }
  }

  Future<void> signOut() async {
    await repo!.client.auth.signOut();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _auth?.cancel();
    if (_channel != null) repo?.client.removeChannel(_channel!);
    super.dispose();
  }
}

class VimiScope extends InheritedNotifier<AppController> {
  const VimiScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VimiScope>()!.notifier!;
}
