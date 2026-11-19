import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/core/local_studio.dart';
import 'package:vimi/core/models.dart';

PracticeSession note(String id) => PracticeSession(
  id: id,
  routine: 'Chorus $id',
  style: 'K-pop',
  minutes: 20,
  counts: 4,
  bpm: 100,
  notes: 'Repeat the transition.',
  createdAt: DateTime.utc(2026, 11, 19),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'guest account refresh preserves the active studio after picker resume',
    () async {
      SharedPreferences.setMockInitialValues({});
      final app = AppController(
        studio: LocalStudio(await SharedPreferences.getInstance()),
      )..exploring = true;
      addTearDown(app.dispose);
      await app.refreshAccount();
      expect(app.exploring, isTrue);
      expect(app.account, 'guest');
    },
  );

  test(
    'corrupt journal is backed up before reset and cannot overwrite good notes on restore',
    () async {
      SharedPreferences.setMockInitialValues({'practice.v1.guest': '{broken'});
      final store = LocalStudio(await SharedPreferences.getInstance());
      await store.backupAndReset('guest');
      final copy = store.recoveryCopies('guest').single;
      expect(copy['raw'], '{broken');
      expect(await store.load('guest'), isEmpty);
      await store.save('guest', [note('good')]);
      await expectLater(
        store.restoreBackup('guest', copy['key'] as String),
        throwsFormatException,
      );
      expect((await store.load('guest')).single.id, 'good');
    },
  );

  test(
    'valid recovery restores all fields and rejects another account copy',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalStudio(await SharedPreferences.getInstance());
      await store.save('a', [note('original')]);
      await store.backupAndReset('a');
      final key = store.recoveryCopies('a').single['key'] as String;
      await expectLater(
        store.restoreBackup('b', key),
        throwsA(isA<FileSystemException>()),
      );
      await store.restoreBackup('a', key);
      expect(
        (await store.load('a')).single.toJson(),
        note('original').toJson(),
      );
    },
  );

  test(
    'one damaged recovery envelope preserves valid copies and its original bytes',
    () async {
      const broken = 'practice-backup.v1.a.1';
      SharedPreferences.setMockInitialValues({broken: '{broken-envelope'});
      final store = LocalStudio(await SharedPreferences.getInstance());
      await store.save('a', [note('original')]);
      await store.backupAndReset('a');
      final copies = store.recoveryCopies('a');
      expect(copies, hasLength(2));
      expect(copies.first['damaged'], isNot(true));
      expect(copies.last['damaged'], isTrue);
      expect(copies.last['raw'], '{broken-envelope');
      expect(store.preferences.getString(broken), '{broken-envelope');
      await store.restoreBackup('a', copies.first['key'] as String);
      expect((await store.load('a')).single.id, 'original');
    },
  );

  test('concurrent note saves retain both notes on reopening', () async {
    SharedPreferences.setMockInitialValues({});
    final studio = LocalStudio(await SharedPreferences.getInstance());
    final app = AppController(studio: studio);
    addTearDown(app.dispose);
    await Future.wait([
      app.savePractice(note('one')),
      app.savePractice(note('two')),
    ]);
    final reopened = await studio.load('guest');
    expect(reopened.map((p) => p.id).toSet(), {'one', 'two'});
    expect(app.practices.map((p) => p.id).toSet(), {'one', 'two'});
  });

  test('deleting a note cannot overwrite a corrupt journal', () async {
    SharedPreferences.setMockInitialValues({'practice.v1.guest': '{broken'});
    final prefs = await SharedPreferences.getInstance();
    final app = AppController(studio: LocalStudio(prefs))
      ..journalError = 'Journal recovery required.';
    addTearDown(app.dispose);
    await expectLater(app.removePractice('one'), throwsStateError);
    expect(prefs.getString('practice.v1.guest'), '{broken');
  });

  test(
    'practice changes stay isolated by account and keep complete fields',
    () async {
      SharedPreferences.setMockInitialValues({});
      final studio = LocalStudio(await SharedPreferences.getInstance());
      await studio.save('a', [note('a')]);
      await studio.save('b', [note('b')]);
      expect((await studio.load('a')).single.toJson(), note('a').toJson());
      expect((await studio.load('b')).single.id, 'b');
      expect(
        jsonDecode(studio.preferences.getString('practice.v1.a')!),
        hasLength(1),
      );
    },
  );
}
