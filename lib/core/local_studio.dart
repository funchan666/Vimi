import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class LocalStudio {
  LocalStudio(this.preferences);
  final SharedPreferences preferences;
  Future<void> _journalWork = Future.value();
  Future<void> _draftWork = Future.value();

  Future<T> _journal<T>(Future<T> Function() action) {
    final next = _journalWork.then((_) => action());
    _journalWork = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return next;
  }

  Future<void> _draft(Future<void> Function() action) {
    final next = _draftWork.then((_) => action());
    _draftWork = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Json? readDraft(String key) {
    final raw = preferences.getString(key);
    return raw == null ? null : jsonMap(jsonDecode(raw));
  }

  Future<void> writeDraft(String key, Json data) {
    final encoded = jsonEncode(data);
    return _draft(() async {
      if (!await preferences.setString(key, encoded)) {
        throw const FileSystemException(
          'Your draft could not be saved. Please try again.',
        );
      }
    });
  }

  Future<void> removeDraft(String key) => _draft(() async {
    if (!await preferences.remove(key)) {
      throw const FileSystemException(
        'Your draft could not be cleared. Please try again.',
      );
    }
  });

  Future<List<PracticeSession>> update(
    String account,
    List<PracticeSession> Function(List<PracticeSession>) change,
  ) => _journal(() async {
    // Read inside the queue so concurrent saves never merge against stale data.
    final updated = change(await load(account));
    await save(account, updated);
    return updated;
  });

  List<Json> recoveryCopies(String account) {
    final copies = <Json>[];
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith('practice-backup.v1.$account.'),
    )) {
      final stored = preferences.get(key);
      try {
        final copy = jsonMap(jsonDecode(stored as String));
        if (copy['raw'] is! String ||
            copy['created_at'] is! String ||
            DateTime.tryParse(copy['created_at'] as String) == null)
          throw const FormatException();
        copies.add({...copy, 'key': key});
      } catch (_) {
        // One damaged envelope must not hide the other copies or erase its bytes.
        copies.add({
          'key': key,
          'raw': stored?.toString() ?? '',
          'created_at': DateTime.fromMillisecondsSinceEpoch(
            0,
            isUtc: true,
          ).toIso8601String(),
          'damaged': true,
        });
      }
    }
    return copies..sort(
      (a, b) => DateTime.parse(
        b['created_at'] as String,
      ).compareTo(DateTime.parse(a['created_at'] as String)),
    );
  }

  Future<void> _backupCurrent(String account) async {
    final raw = preferences.getString('practice.v1.$account');
    if (raw == null || raw == '[]') return;
    final now = DateTime.now().toUtc();
    final key = 'practice-backup.v1.$account.${now.microsecondsSinceEpoch}';
    if (!await preferences.setString(
      key,
      jsonEncode({'key': key, 'raw': raw, 'created_at': now.toIso8601String()}),
    )) {
      throw const FileSystemException(
        'The recovery copy could not be saved. Your current journal was kept.',
      );
    }
  }

  Future<void> backupAndReset(String account) => _journal(() async {
    await _backupCurrent(account);
    await save(account, []);
  });

  Future<void> restoreBackup(String account, String key) => _journal(() async {
    if (!key.startsWith('practice-backup.v1.$account.')) {
      throw const FileSystemException(
        'Choose a recovery copy from this account.',
      );
    }
    final copy = jsonMap(jsonDecode(preferences.getString(key)!));
    final notes = jsonRows(
      jsonDecode(copy['raw'] as String),
    ).map(PracticeSession.fromJson).toList();
    await _backupCurrent(account);
    await save(account, notes);
  });
  Future<List<PracticeSession>> load(String account) async {
    final raw = preferences.getString('practice.v1.$account');
    if (raw == null) return [];
    // A corrupt file is preserved, never silently replaced with an empty journal.
    return jsonRows(jsonDecode(raw)).map(PracticeSession.fromJson).toList();
  }

  Future<void> save(String account, List<PracticeSession> sessions) async {
    final ok = await preferences.setString(
      'practice.v1.$account',
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
    if (!ok)
      throw const FileSystemException(
        'Your practice could not be saved. Please try again.',
      );
  }

  Future<String> retainVideo(String account, String source) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/practice/$account');
    await directory.create(recursive: true);
    final suffix = source.toLowerCase().endsWith('.mov') ? 'mov' : 'mp4';
    return (await File(source).copy(
      '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.$suffix',
    )).path;
  }

  Future<void> clear(String account) => _journal(() async {
    await _draftWork;
    await preferences.remove('practice.v1.$account');
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/practice/$account');
    if (await directory.exists()) await directory.delete(recursive: true);
    final drafts = Directory('${root.path}/drafts/$account');
    if (await drafts.exists()) await drafts.delete(recursive: true);
  });
}
