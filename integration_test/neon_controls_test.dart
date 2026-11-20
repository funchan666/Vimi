import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/core/local_studio.dart';
import 'package:vimi/core/media_library.dart';
import 'package:vimi/core/models.dart';
import 'package:vimi/design/vimi_ui.dart';
import 'package:vimi/features/community/publish_page.dart';
import 'package:vimi/features/profile/profile_pages.dart';
import 'package:vimi/features/shell.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native icon navigation and rehearsal controls retain their actions',
    (tester) async {
      binding.reportData = {
        'scope':
            'Local guest UI; no server connection, account or content writes',
      };
      final app = AppController(
        studio: LocalStudio(await SharedPreferences.getInstance()),
      );
      await app.initialize();
      await tester.pumpWidget(
        VimiScope(
          controller: app,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: vimiTheme(),
            home: const DanceShell(initialTab: 1),
          ),
        ),
      );
      await tester.pump();
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      try {
        for (final label in ['Floor', 'Inbox', 'Me', 'Studio']) {
          final destination = find.byTooltip(label);
          expect(
            find.descendant(of: destination, matching: find.text(label)),
            findsNothing,
          );
          await tester.tap(destination);
          await tester.pump(const Duration(milliseconds: 500));
          expect(
            tester
                .widget<VIconButton>(
                  find.ancestor(
                    of: destination,
                    matching: find.byType(VIconButton),
                  ),
                )
                .selected,
            isTrue,
          );
        }
        await capture(binding, tester, 'icon-only-studio');
        binding.reportData!['four_icon_destinations_and_selection'] = 'passed';
        await press(tester, 'Dance video library');
        final catalog = await MediaLibrary.load();
        await press(tester, catalog.clips.first.title);
        await waitFor(
          tester,
          () => find.byType(VideoPlayer).evaluate().isNotEmpty,
        );
        final player = tester
            .widget<VideoPlayer>(find.byType(VideoPlayer))
            .controller;
        await press(tester, 'Mirror off');
        await press(tester, 'Loop off');
        await press(tester, '1.0×');
        await press(tester, '0.5×');
        expect(player.value.playbackSpeed, .5);
        expect(player.value.isLooping, isTrue);
        await press(tester, '+5s');
        expect(player.value.position.inSeconds, greaterThanOrEqualTo(4));
        await press(tester, '−5s');
        await press(tester, 'Go to time');
        await enter(
          tester,
          'Go to second · 0–${player.value.duration.inSeconds}',
          '2',
        );
        await press(tester, 'Go');
        expect(player.value.position.inSeconds, 2);
        await press(tester, 'Play video');
        await tester.pump(const Duration(milliseconds: 800));
        expect(player.value.position.inMilliseconds, greaterThan(2000));
        await press(tester, 'Pause video');
        await tester.drag(find.byType(VideoPlayer), const Offset(0, 600));
        await tester.pump(const Duration(milliseconds: 500));
        await capture(binding, tester, 'compact-rehearsal-controls');
        final retained = player.value.position;
        await press(tester, 'Full screen');
        await waitFor(
          tester,
          () => find.byType(VideoPlayer).evaluate().isNotEmpty,
        );
        expect(
          tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
          same(player),
        );
        expect(find.byTooltip('Mirror on'), findsOneWidget);
        expect(player.value.playbackSpeed, .5);
        expect(player.value.isLooping, isTrue);
        await press(tester, 'Mirror on');
        await goBack(tester);
        expect(
          tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
          same(player),
        );
        expect(player.value.position, retained);
        expect(find.byTooltip('Mirror off'), findsOneWidget);
        binding.reportData!['native_play_seek_speed_loop_mirror_and_shared_fullscreen'] =
            'passed';
        await goBack(tester);
        await goBack(tester);
        await openTestPage(tester, const PublishPage());
        await press(tester, 'Capture dance');
        expect(find.text('Take photo'), findsOneWidget);
        expect(find.text('Record video'), findsOneWidget);
        Navigator.pop(tester.element(find.text('Take photo')));
        await tester.pump(const Duration(milliseconds: 600));
        await capture(binding, tester, 'publisher-icon-tools');
        await goBack(tester);
        await openTestPage(
          tester,
          const EditProfilePage(
            profile: Dancer(id: 'ui-fixture-only', name: 'UI preview'),
          ),
        );
        await press(tester, 'Browse profile images');
        await waitFor(
          tester,
          () => find.textContaining('Explore 55 images.').evaluate().isNotEmpty,
        );
        await press(tester, catalog.portraits.first.title);
        await press(tester, 'Use this image');
        await capture(binding, tester, 'profile-edit-icon-tools-local-fixture');
        await goBack(tester);
        binding.reportData!['photo_picker_55_and_capture_source_sheet'] =
            'passed';
        await openTestPage(tester, const SettingsPage());
        await press(tester, 'Help & safety');
        await press(tester, 'Child safety standards');
        expect(find.text('Child safety standards'), findsWidgets);
        binding.reportData!['settings_help_and_child_safety_routes'] = 'passed';
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      }
    },
  );
}
