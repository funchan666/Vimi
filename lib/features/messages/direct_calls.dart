import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_controller.dart';
import '../../core/models.dart';
import 'call_media.dart';

class DirectCall {
  DirectCall({
    required this.peer,
    required this.video,
    required this.incoming,
    required this.owner,
    this.id,
  });

  final Dancer peer;
  final bool video, incoming;
  final String owner;
  String? id;
  String status = 'ringing';
  String? outcome;
  CallMedia? media;
  CallConnectionState connection = CallConnectionState.connecting;
  bool preparing = false;
  bool _polling = false;
  Json? _localDescription;
  bool _offerSent = false;
  bool _answered = false;
  int _lastSignal = 0;
  final List<Json> _candidates = [];
  DateTime? _startedConnecting;
  DateTime? _lastHeartbeat;
  DateTime? _lostServer;

  String get kind => video ? 'Video call' : 'Voice call';
  bool get finished => outcome != null;
}

class DirectCalls extends ChangeNotifier {
  DirectCalls(this.app);

  static const _requestTimeout = Duration(seconds: 8);
  final AppController app;
  DirectCall? current;
  RealtimeChannel? _incoming;
  Timer? _poll, _background;
  Future<void>? _releasingMedia;
  String? _owner, _dismissedId;
  bool _incomingChanged = false;
  bool _foreground = true, _disposed = false, _checkingIncoming = false;
  SupabaseClient? get _client => app.repo?.client;

  void syncAccount() {
    final owner =
        app.signedIn && app.accountStatus == 'active' && !app.recoveringPassword
        ? app.account
        : null;
    if (owner == _owner) return;
    _unsubscribe();
    _owner = owner;
    _dismissedId = null;
    if (current case final call?) {
      unawaited(_finish(call, 'Call closed.'));
    }
    if (owner == null) return;
    final client = _client!;
    _incoming = client
        .channel('vimi-calls-$owner')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'direct_calls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'callee_id',
            value: owner,
          ),
          callback: (_) => unawaited(_checkIncoming()),
        )
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            unawaited(_checkIncoming());
          }
        });
    unawaited(_checkIncoming());
  }

  void _unsubscribe() {
    final channel = _incoming;
    _incoming = null;
    if (channel != null) unawaited(_client!.removeChannel(channel));
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    _background?.cancel();
    if (foreground) {
      unawaited(_checkIncoming());
    } else {
      _scheduleBackgroundClose();
    }
  }

  void _scheduleBackgroundClose() {
    _background?.cancel();
    _background = Timer(const Duration(seconds: 2), () {
      final call = current;
      if (!_foreground && call != null && !call.preparing) {
        unawaited(
          _finish(call, 'Call ended when you left the app.', notifyPeer: true),
        );
      }
    });
  }

  bool _isCurrent(DirectCall call) =>
      !_disposed &&
      identical(current, call) &&
      _owner == call.owner &&
      app.signedIn &&
      app.account == call.owner &&
      !call.finished;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<dynamic> _rpc(String name, [Json? params]) =>
      _client!.rpc(name, params: params);

  Future<void> _checkIncoming() async {
    final owner = _owner;
    if (!_foreground || _disposed || owner == null || current != null) return;
    if (_checkingIncoming) {
      _incomingChanged = true;
      return;
    }
    _checkingIncoming = true;
    _incomingChanged = false;
    try {
      final raw = await _rpc('get_active_call').timeout(_requestTimeout);
      if (raw == null || _owner != owner) return;
      final row = jsonMap(raw);
      if (row['status'] != 'ringing' ||
          row['callee_id'] != owner ||
          row['id'] == _dismissedId)
        return;
      final peer = await app.repo!
          .dancer(row['caller_id'] as String)
          .timeout(_requestTimeout);
      if (peer == null ||
          _disposed ||
          !_foreground ||
          _owner != owner ||
          app.account != owner ||
          current != null)
        return;
      final call = DirectCall(
        peer: peer,
        video: row['kind'] == 'video',
        incoming: true,
        owner: owner,
        id: row['id'] as String,
      );
      current = call;
      _watch(call);
      _emit();
    } catch (_) {
      // Signing in and reconnecting to Realtime both trigger another lookup.
    } finally {
      _checkingIncoming = false;
      if (!_disposed && (_incomingChanged || _owner != owner)) {
        unawaited(_checkIncoming());
      }
    }
  }

  bool start(Dancer peer, {required bool video}) {
    final owner = _owner;
    if (current != null || owner == null || !_foreground) return false;
    final call = DirectCall(
      peer: peer,
      video: video,
      incoming: false,
      owner: owner,
    );
    current = call;
    unawaited(_prepare(call));
    return true;
  }

  Future<void> accept(DirectCall call) async {
    if (!_isCurrent(call) ||
        !call.incoming ||
        call.preparing ||
        !_foreground ||
        call.status != 'ringing')
      return;
    await _prepare(call);
  }

  Future<void> _prepare(DirectCall call) async {
    call.preparing = true;
    _emit();
    try {
      await _releasingMedia;
      if (!_isCurrent(call)) return;
      const iceFunction = String.fromEnvironment('VIMI_CALL_ICE_FUNCTION');
      List<Json>? servers;
      if (iceFunction.isNotEmpty) {
        final response = await _client!.functions
            .invoke(iceFunction)
            .timeout(_requestTimeout);
        servers = jsonRows(jsonMap(response.data)['iceServers']);
      }
      if (!_isCurrent(call)) return;
      final media = CallMedia(
        video: call.video,
        iceServers: servers,
        onCandidate: (candidate) {
          if (_isCurrent(call) && call._candidates.length < 128) {
            call._candidates.add(candidate);
          }
        },
        onConnectionState: (state) {
          if (!_isCurrent(call)) return;
          if (call.connection == CallConnectionState.connected &&
              state == CallConnectionState.disconnected) {
            call._startedConnecting = DateTime.now();
          }
          call.connection = state;
          _emit();
          if (state == CallConnectionState.failed ||
              state == CallConnectionState.closed) {
            unawaited(
              _finish(
                call,
                'Couldn’t connect the call. Check your connection and try again.',
                notifyPeer: true,
              ),
            );
          }
        },
      );
      call.media = media;
      await media.start();
      if (!_isCurrent(call)) return;

      if (!_foreground) {
        // Android can complete a permission request just before its resume event.
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!_isCurrent(call)) return;
        if (!_foreground) {
          await _finish(
            call,
            'Call ended when you left the app.',
            notifyPeer: true,
          );
          return;
        }
      }

      if (call.incoming) {
        final row = await _update(call, 'accept')
            .then((row) {
              if (!_isCurrent(call) &&
                  row?['status'] == 'accepted' &&
                  app.account == call.owner) {
                unawaited(_quietUpdate(call, 'end'));
              }
              return row;
            })
            .timeout(_requestTimeout);
        if (!_isCurrent(call)) return;
        if (row == null) {
          await _finish(call, 'This call is no longer available.');
          return;
        }
        _applyState(call, row);
      } else {
        final row =
            await _rpc('start_call', {
                  'p_peer': call.peer.id,
                  'p_kind': call.video ? 'video' : 'audio',
                })
                .then((raw) {
                  final row = jsonMap(raw);
                  call.id = row['id'] as String;
                  if (!_isCurrent(call) && app.account == call.owner) {
                    unawaited(_quietUpdate(call, 'cancel'));
                  }
                  return row;
                })
                .timeout(_requestTimeout);
        if (!_isCurrent(call)) return;
        _applyState(call, row);
        _watch(call);
      }
      if (_isCurrent(call)) unawaited(_pollCall(call));
    } on CallMediaException catch (error) {
      if (_isCurrent(call)) {
        await _finish(call, error.message, notifyPeer: true);
      }
    } on PostgrestException catch (error) {
      if (_isCurrent(call)) {
        await _finish(call, _callError(error), notifyPeer: true);
      }
    } catch (_) {
      if (_isCurrent(call)) {
        await _finish(
          call,
          'The call could not start. Please try again.',
          notifyPeer: true,
        );
      }
    } finally {
      call.preparing = false;
      if (identical(current, call)) {
        _emit();
        if (!_foreground) _scheduleBackgroundClose();
      }
    }
  }

  String _callError(PostgrestException error) {
    if (error.code == 'P0001') return error.message;
    if (error.code == '42501')
      return 'Calls are available between mutual follows.';
    if (error.code == 'PGRST202') return 'Calling is temporarily unavailable.';
    return 'The call could not start. Please try again.';
  }

  void _watch(DirectCall call) {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isCurrent(call)) unawaited(_pollCall(call));
    });
  }

  Future<void> _pollCall(DirectCall call) async {
    if (!_isCurrent(call) || call._polling || call.id == null) return;
    call._polling = true;
    try {
      final now = DateTime.now();
      final heartbeat =
          call.status == 'accepted' &&
          (call._lastHeartbeat == null ||
              now.difference(call._lastHeartbeat!) >=
                  const Duration(seconds: 24));
      final raw = await _rpc(heartbeat ? 'touch_call' : 'get_call', {
        'p_call': call.id,
      }).timeout(_requestTimeout);
      if (!_isCurrent(call)) return;
      if (raw == null) {
        await _finish(call, 'This call is no longer available.');
        return;
      }
      if (heartbeat) call._lastHeartbeat = now;
      _applyState(call, jsonMap(raw));
      if (!_isCurrent(call) ||
          call.status != 'accepted' ||
          call.media?.ready != true) {
        call._lostServer = null;
        return;
      }
      if (call.connection != CallConnectionState.connected &&
          now.difference(call._startedConnecting!) >
              const Duration(seconds: 28)) {
        await _finish(
          call,
          'Couldn’t connect the call. Please try again.',
          notifyPeer: true,
        );
        return;
      }
      await _exchange(call);
      call._lostServer = null;
    } on PostgrestException catch (error) {
      if (_isCurrent(call) && error.code == '42501') {
        await _finish(
          call,
          'This call is no longer available.',
          notifyPeer: true,
        );
      } else {
        await _networkLost(call);
      }
    } catch (_) {
      await _networkLost(call);
    } finally {
      call._polling = false;
    }
  }

  Future<void> _networkLost(DirectCall call) async {
    if (!_isCurrent(call)) return;
    final now = DateTime.now();
    call._lostServer ??= now;
    if (now.difference(call._lostServer!) > const Duration(seconds: 10)) {
      await _finish(call, 'The call lost its connection.', notifyPeer: true);
    }
  }

  void _applyState(DirectCall call, Json row) {
    final status = row['status'] as String;
    if (status == call.status ||
        (call.status == 'accepted' && status == 'ringing'))
      return;
    final wasAccepted = call.status == 'accepted';
    call.status = status;
    if (status == 'accepted') {
      call._startedConnecting = DateTime.now();
      _emit();
      return;
    }
    final outcome = switch (status) {
      'expired' =>
        wasAccepted
            ? 'The call lost its connection.'
            : 'The call went unanswered.',
      'declined' =>
        call.incoming
            ? 'Call declined.'
            : '${call.peer.name} declined the call.',
      'canceled' => 'Call canceled.',
      _ => 'Call ended.',
    };
    unawaited(_finish(call, outcome));
  }

  Future<void> _exchange(DirectCall call) async {
    final media = call.media!;
    if (!call.incoming && !call._offerSent) {
      final offer = call._localDescription ??= await media.createOffer();
      if (!_isCurrent(call)) return;
      await _signal(call, 'offer', offer);
      call._offerSent = true;
    }

    final signals = jsonRows(
      await _rpc('get_call_signals', {
        'p_call': call.id,
        'p_after': call._lastSignal,
      }).timeout(_requestTimeout),
    );
    for (final signal in signals) {
      if (!_isCurrent(call)) return;
      final payload = jsonMap(signal['payload']);
      switch (signal['kind']) {
        case 'offer':
          if (call.incoming && !call._answered) {
            final answer = call._localDescription ??= await media.acceptOffer(
              payload,
            );
            if (!_isCurrent(call)) return;
            await _signal(call, 'answer', answer);
            call._answered = true;
          }
        case 'answer':
          if (!call.incoming && !call._answered) {
            await media.acceptAnswer(payload);
            call._answered = true;
          }
        case 'ice':
          await media.addCandidate(payload);
      }
      call._lastSignal = (signal['id'] as num).toInt();
    }
    if (call.incoming ? !call._answered : !call._offerSent) return;
    for (
      var index = 0;
      index < 12 && _isCurrent(call) && call._candidates.isNotEmpty;
      index++
    ) {
      await _signal(call, 'ice', call._candidates.first);
      call._candidates.removeAt(0);
    }
  }

  Future<void> _signal(DirectCall call, String kind, Json payload) async {
    await _rpc('send_call_signal', {
      'p_call': call.id,
      'p_kind': kind,
      'p_payload': payload,
    }).timeout(_requestTimeout);
  }

  Future<Json?> _update(DirectCall call, String action) async {
    final raw = await _rpc('update_call', {
      'p_call': call.id,
      'p_action': action,
    });
    return raw == null ? null : jsonMap(raw);
  }

  Future<void> _quietUpdate(DirectCall call, String action) async {
    try {
      await _update(call, action).timeout(_requestTimeout);
    } catch (_) {
      // The server also expires missing heartbeats or unanswered calls.
    }
  }

  Future<void> end(DirectCall call) => _finish(
    call,
    call.status == 'ringing'
        ? (call.incoming ? 'Call declined.' : 'Call canceled.')
        : 'Call ended.',
    notifyPeer: true,
  );

  Future<void> _finish(
    DirectCall call,
    String outcome, {
    bool notifyPeer = false,
  }) async {
    if (!identical(current, call) || call.finished) return;
    final action = call.status == 'accepted'
        ? 'end'
        : (call.incoming ? 'decline' : 'cancel');
    final media = call.media;
    call.media = null;
    call.outcome = outcome;
    _poll?.cancel();
    _emit();
    if (notifyPeer &&
        call.id != null &&
        app.signedIn &&
        app.account == call.owner) {
      unawaited(_quietUpdate(call, action));
    }
    if (media != null) {
      final release = media.dispose().catchError((Object _) {});
      _releasingMedia = release;
      await release;
      if (identical(_releasingMedia, release)) _releasingMedia = null;
    }
  }

  void dismiss(DirectCall call) {
    if (!identical(current, call)) return;
    if (!call.finished) unawaited(end(call));
    _dismissedId = call.id;
    current = null;
    _emit();
    unawaited(_checkIncoming());
  }

  @override
  void dispose() {
    if (current case final call?) {
      unawaited(_finish(call, 'Call closed.', notifyPeer: true));
    }
    _disposed = true;
    _poll?.cancel();
    _background?.cancel();
    _unsubscribe();
    super.dispose();
  }
}

class DirectCallScope extends InheritedWidget {
  const DirectCallScope({required this.calls, required super.child, super.key});
  final DirectCalls calls;

  static DirectCalls? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DirectCallScope>()?.calls;

  @override
  bool updateShouldNotify(DirectCallScope oldWidget) =>
      oldWidget.calls != calls;
}
