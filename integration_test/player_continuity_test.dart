import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/core/dance_repository.dart';
import 'package:vimi/core/models.dart';
import 'history_flows_test.dart' as history;
import 'package:vimi/design/vimi_ui.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/studio/rehearsal_player.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native inbox paging and full-screen rehearsal continuity',
    (tester) async {
      requireQaFixtures(social: true);
      binding.reportData = {};
      await vimi.main();
      await waitFor(tester, () => find.byType(VimiScope).evaluate().isNotEmpty);
      if (appController(tester).signedIn) await appController(tester).signOut();
      await waitFor(
        tester,
        () => find.byType(WelcomePage).evaluate().isNotEmpty,
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await press(tester, 'Sign in');
      await signIn(
        tester,
        email: const String.fromEnvironment('QA_EMAIL_A'),
        password: const String.fromEnvironment('QA_PASSWORD_A'),
      );
      await press(tester, 'Inbox');
      await history.loaded<Json>(tester, 25);
      await history.more(tester, 'Earlier conversations');
      await history.loaded<Json>(tester, 32);
      expect(
        history
            .footer<Json>(tester)
            .pager
            .items
            .map((row) => jsonMap(row['peer'])['id'])
            .toSet(),
        hasLength(32),
      );
      binding.reportData!['native_32_inbox_conversations'] = 'passed';
      await capture(binding, tester, 'history-inbox-conversations');
      final peer = SupabaseClient(
        const String.fromEnvironment('SUPABASE_URL'),
        const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(peer.dispose);
      await peer.auth.signInWithPassword(
        email: const String.fromEnvironment('QA_EMAIL_B'),
        password: const String.fromEnvironment('QA_PASSWORD_B'),
      );
      final url = await DanceRepository(
        peer,
      ).mediaUrl(const String.fromEnvironment('QA_VIDEO'));
      await openTestPage(
        tester,
        VPage(
          title: 'QA rehearsal continuity',
          child: SingleChildScrollView(
            child: RehearsalPlayer(source: url, network: true, practice: true),
          ),
        ),
      );
      await waitFor(
        tester,
        () => find.byType(VideoPlayer).evaluate().isNotEmpty,
      );
      final player = tester
          .widget<VideoPlayer>(find.byType(VideoPlayer))
          .controller;
      expect(player.value.duration.inSeconds, 12);
      await press(tester, 'Mirror off');
      await press(tester, 'Loop off');
      await press(tester, '1.0×');
      await press(tester, '0.5×');
      await press(tester, '+5s');
      await reveal(tester, find.byTooltip('Play video'));
      await tester.tap(find.byTooltip('Play video'));
      await tester.pump(const Duration(seconds: 1));
      expect(player.value.position.inMilliseconds, greaterThanOrEqualTo(5000));
      await press(tester, 'Full screen');
      await waitFor(
        tester,
        () => find.byType(VideoPlayer).evaluate().isNotEmpty,
      );
      expect(
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
        same(player),
      );
      expect(player.value.isPlaying, isFalse);
      expect(player.value.isLooping, isTrue);
      expect(player.value.playbackSpeed, .5);
      expect(find.byTooltip('Mirror on'), findsOneWidget);
      final retained = player.value.position;
      await press(tester, 'Mirror on');
      await press(tester, '0.5×');
      await press(tester, '0.75×');
      await reveal(tester, find.byTooltip('Play video'));
      await tester.tap(find.byTooltip('Play video'));
      await tester.pump(const Duration(seconds: 1));
      expect(player.value.position, greaterThan(retained));
      await capture(binding, tester, 'player-fullscreen-continuity');
      await goBack(tester);
      expect(
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
        same(player),
      );
      expect(player.value.isPlaying, isFalse);
      expect(player.value.isLooping, isTrue);
      expect(player.value.playbackSpeed, .75);
      expect(find.byTooltip('Mirror off'), findsOneWidget);
      expect(player.value.position, greaterThan(retained));
      await capture(binding, tester, 'player-returned-continuity');
      binding.reportData!.addAll({
        'real_native_network_decoder': 'passed',
        'full_screen_shared_controller_position_speed_loop_mirror': 'passed',
        'return_preserves_changes_and_pauses': 'passed',
      });
      await goBack(tester);
      await tester.pump(const Duration(seconds: 1));
      final app = appController(tester);
      for (final owner in [
        const String.fromEnvironment('QA_USER_A'),
        const String.fromEnvironment('QA_USER_B'),
      ]) {
        await app.studio.clear(owner);
        for (final key
            in app.studio.preferences
                .getKeys()
                .where((key) => key.contains(owner))
                .toList()) {
          await app.studio.preferences.remove(key);
        }
      }
      await app.signOut();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
