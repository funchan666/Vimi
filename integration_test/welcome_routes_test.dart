import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/core/media_library.dart';
import 'package:vimi/design/library_image.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/shell.dart';
import 'package:vimi/features/studio/media_library_pages.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'welcome photos, real preview and every entry route',
    (tester) async {
      final results = <String, Object?>{};
      binding.reportData = results;
      await vimi.main();
      await waitFor(
        tester,
        () => find.byType(WelcomePage).evaluate().isNotEmpty,
      );
      expect(appController(tester).signedIn, isFalse);
      await binding.convertFlutterSurfaceToImage();
      final library = await MediaLibrary.load();
      final failures = <Object>[];
      final context = tester.element(find.byType(WelcomePage));
      await tester.runAsync(() async {
        for (final id in ['street-style-group', 'holiday-duet']) {
          final clip = library.clips.singleWhere((clip) => clip.id == id);
          await precacheImage(
            NetworkImage(clip.thumbnail),
            context,
            onError: (error, _) => failures.add(error),
          );
        }
      });
      expect(failures, isEmpty, reason: 'Actual cover bytes must decode.');
      await tester.pumpAndSettle();
      expect(find.byType(LibraryImage), findsNWidgets(2));
      expect(find.byTooltip('Retry image'), findsNothing);
      await capture(binding, tester, 'native-welcome');
      results['both_cloud_performance_covers_decoded'] = 'passed';

      await press(tester, 'Join the crew');
      expect(tester.widget<AuthPage>(find.byType(AuthPage)).signUp, isTrue);
      expect(input('Display name'), findsOneWidget);
      await goBack(tester);
      await press(tester, 'Sign in');
      expect(tester.widget<AuthPage>(find.byType(AuthPage)).signUp, isFalse);
      expect(input('Email'), findsOneWidget);
      await goBack(tester);
      results['signup_and_signin_routes'] = 'passed';

      await press(tester, 'Privacy Policy');
      expect(find.byType(LegalPage), findsOneWidget);
      expect(find.textContaining('privacy', findRichText: true), findsWidgets);
      await goBack(tester);
      await press(tester, 'Child safety');
      expect(find.byType(LegalPage), findsOneWidget);
      expect(find.text('Child safety standards'), findsOneWidget);
      await goBack(tester);
      results['privacy_and_child_safety_readable_without_account'] = 'passed';

      await press(tester, 'Preview a duet');
      expect(
        tester
            .widget<ClipLibraryDetail>(find.byType(ClipLibraryDetail))
            .clip
            .id,
        'holiday-duet',
      );
      await waitFor(
        tester,
        () => find.byType(VideoPlayer).evaluate().isNotEmpty,
      );
      final player = tester
          .widget<VideoPlayer>(find.byType(VideoPlayer))
          .controller;
      expect(player.value.isInitialized, isTrue);
      await press(tester, 'Play');
      await waitFor(tester, () => player.value.position.inMilliseconds > 1000);
      await press(tester, 'Pause video');
      await capture(binding, tester, 'native-welcome-duet-preview');
      results['duet_native_stream_play_pause'] = 'passed';
      await goBack(tester);

      await press(tester, 'Explore the studio');
      expect(find.byType(DanceShell), findsOneWidget);
      expect(tester.widget<DanceShell>(find.byType(DanceShell)).initialTab, 1);
      expect(appController(tester).signedIn, isFalse);
      results['guest_studio_route'] = 'passed';
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
