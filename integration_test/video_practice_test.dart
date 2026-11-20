import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/core/local_studio.dart';
import 'package:vimi/design/vimi_ui.dart';
import 'package:vimi/features/shell.dart';
import 'package:vimi/features/studio/rehearsal_player.dart';
import 'package:vimi/features/studio/studio_pages.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real video picker, decoder, practice controls and retained file',
    (tester) async {
      final app = AppController(
        studio: LocalStudio(await SharedPreferences.getInstance()),
      );
      addTearDown(app.dispose);
      await app.initialize();
      final owner = app.account;
      final practiceFolder = '/practice/$owner/';
      for (final note in await app.studio.load(owner)) {
        if (note.routine == 'QA native video rehearsal') {
          await app.removePractice(note.id);
          await app.studio.removeDraft('practice-draft.v1.$owner.${note.id}');
          if (note.videoPath?.contains(practiceFolder) == true &&
              await File(note.videoPath!).exists())
            await File(note.videoPath!).delete();
        }
      }
      await tester.pumpWidget(
        VimiScope(
          controller: app,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: vimiTheme(),
            navigatorObservers: [PlaybackRouteObserver()],
            home: const DanceShell(initialTab: 1),
          ),
        ),
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await press(tester, 'Start a practice note');
      await enter(tester, 'Routine or song', 'QA native video rehearsal');
      // ignore: avoid_print
      print('VIMI_QA_PICK_VIDEO');
      await press(tester, 'Add your rehearsal video');
      await waitFor(
        tester,
        () => find.byType(VideoPlayer).evaluate().isNotEmpty,
        timeout: const Duration(minutes: 3),
      );
      final player = tester
          .widget<VideoPlayer>(find.byType(VideoPlayer))
          .controller;
      expect(player.value.isInitialized, isTrue);
      expect(player.value.duration.inSeconds, 12);
      await press(tester, 'Mirror off');
      expect(find.byTooltip('Mirror on'), findsOneWidget);
      await press(tester, 'Loop off');
      expect(player.value.isLooping, isTrue);
      await press(tester, '1.0×');
      await press(tester, '0.5×');
      expect(player.value.playbackSpeed, 0.5);
      await reveal(tester, find.byTooltip('Play video'));
      await tester.tap(find.byTooltip('Play video'));
      await tester.pump(const Duration(seconds: 2));
      expect(player.value.isPlaying, isTrue);
      expect(player.value.position, greaterThan(Duration.zero));
      await capture(binding, tester, 'native-video-practice-controls');
      await press(tester, 'Full screen');
      expect(player.value.isPlaying, isFalse);
      await goBack(tester);
      await press(tester, 'Save practice');
      await waitFor(
        tester,
        () => find.byType(PracticeEditor).evaluate().isEmpty,
      );
      final saved = (await app.studio.load(
        owner,
      )).singleWhere((n) => n.routine == 'QA native video rehearsal');
      expect(await File(saved.videoPath!).exists(), isTrue);
      expect(saved.videoPath, contains(practiceFolder));
      await openTestPage(tester, PracticeEditor(session: saved));
      await waitFor(
        tester,
        () => find.byType(VideoPlayer).evaluate().isNotEmpty,
      );
      expect(
        tester
            .widget<VideoPlayer>(find.byType(VideoPlayer))
            .controller
            .value
            .isInitialized,
        isTrue,
      );
      await capture(binding, tester, 'native-practice-reopened');
      await press(tester, 'Delete practice note');
      await press(tester, 'Delete note');
      await waitFor(
        tester,
        () => find.byType(PracticeEditor).evaluate().isEmpty,
      );
      expect(
        (await app.studio.load(owner)).where((n) => n.id == saved.id),
        isEmpty,
      );
      if (await File(saved.videoPath!).exists())
        await File(saved.videoPath!).delete();
      expect(find.byType(StudioPage), findsOneWidget);
      // Record real wider-container and larger-text rendering on Android.
      // The host changes actual Android display overrides, then restores them.
      // ignore: avoid_print
      print('VIMI_QA_RESIZE_STUDIO');
      await waitFor(
        tester,
        () =>
            tester.getSize(find.byType(Scaffold).last).width > 760 &&
            MediaQuery.textScalerOf(
                  tester.element(find.byType(StudioPage)),
                ).scale(10) >=
                12.9,
        timeout: const Duration(minutes: 2),
      );
      await capture(binding, tester, 'native-expanded-studio');
      // ignore: avoid_print
      print('VIMI_QA_RESTORE_DISPLAY');
      await waitFor(
        tester,
        () =>
            tester.getSize(find.byType(Scaffold).last).width < 760 &&
            MediaQuery.textScalerOf(
                  tester.element(find.byType(StudioPage)),
                ).scale(10) <=
                10.1,
        timeout: const Duration(minutes: 2),
      );
      binding.reportData ??= {};
      binding.reportData!.addAll({
        'native_video_pick_play_speed_mirror_loop_retention': 'passed',
        'practice_reopen_delete': 'passed',
        'expanded_larger_type': 'passed',
      });
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
