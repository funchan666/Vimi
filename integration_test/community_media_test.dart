import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:vimi/design/library_image.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/community/community_pages.dart';
import 'package:vimi/features/community/cover_video_canvas.dart';
import 'package:vimi/features/profile/profile_pages.dart';
import 'package:vimi/features/shell.dart';
import 'package:vimi/features/studio/media_library_pages.dart';
import 'package:vimi/features/studio/studio_pages.dart';
import 'package:vimi/features/wallet/wallet_page.dart';
import 'package:vimi/main.dart' as vimi;
import 'support.dart';

int decodedCovers() => find
    .descendant(
      of: find.byType(LibraryImage),
      matching: find.byWidgetPredicate((widget) {
        // The loading and retry glyphs use the 1774px bundled atlas.
        return widget is RawImage && (widget.image?.width ?? 1774) < 1200;
      }),
    )
    .evaluate()
    .length;

Future<void> returnTo(WidgetTester tester, Finder destination) async {
  final back = find.byTooltip('Go back').hitTestable();
  await waitFor(tester, () => back.evaluate().length == 1);
  await tester.tap(back);
  await tester.pump();
  await waitFor(
    tester,
    () => destination.hitTestable().evaluate().isNotEmpty,
    reason: 'Back did not return to the expected screen.',
  );
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'signed-in tabs expose real photos, video and dance actions',
    (tester) async {
      final report = <String, Object?>{};
      binding.reportData = report;
      final support = await getApplicationSupportDirectory();
      final file = File('${support.path}/community-qa-login.json');
      Map<String, dynamic>? credentials;
      // Credentials are passed through the debug sandbox once, outside the APK.
      if (await file.exists()) {
        try {
          credentials =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        } finally {
          await file.delete();
        }
      }
      await vimi.main();
      await waitFor(
        tester,
        () =>
            find.byType(WelcomePage).evaluate().isNotEmpty ||
            find.byType(DanceShell).evaluate().isNotEmpty,
      );
      if (!appController(tester).signedIn) {
        expect(
          credentials,
          isNotNull,
          reason: 'Set a test sign-in in the debug sandbox first.',
        );
        await press(tester, 'Sign in');
        await signIn(
          tester,
          email: credentials!['email'] as String,
          password: credentials['password'] as String,
        );
      }
      await waitFor(tester, () => appController(tester).profile != null);
      await binding.convertFlutterSurfaceToImage();
      final activeCover = find.byWidgetPredicate(
        (widget) => widget is CoverVideoCanvas && widget.active,
      );
      final feedPlayer = find.descendant(
        of: activeCover,
        matching: find.byType(VideoPlayer),
      );
      await waitFor(tester, () => feedPlayer.evaluate().isNotEmpty);
      final firstSource = tester.widget<CoverVideoCanvas>(activeCover).sourceId;
      final firstPlayer = tester.widget<VideoPlayer>(feedPlayer).controller;
      await waitFor(
        tester,
        () => firstPlayer.value.position.inMilliseconds > 500,
      );
      await capture(binding, tester, 'short-covers');
      await tester.fling(activeCover, const Offset(0, -480), 1200);
      await waitFor(tester, () {
        final active = activeCover.evaluate();
        return active.length == 1 &&
            (active.single.widget as CoverVideoCanvas).sourceId != firstSource;
      });
      await waitFor(tester, () => feedPlayer.evaluate().isNotEmpty);
      final nextPlayer = tester.widget<VideoPlayer>(feedPlayer).controller;
      await waitFor(
        tester,
        () => nextPlayer.value.position.inMilliseconds > 500,
      );
      report['short_covers'] = 'vertical swipe opens and plays the next source';

      await press(tester, 'Discover');
      await waitFor(tester, () => decodedCovers() >= 3);
      await capture(binding, tester, 'discover');
      report['discover'] = 'actual cloud covers decoded';

      final featured = find.byTooltip('Play Holiday duet').first;
      await reveal(tester, featured);
      await tester.tap(featured);
      await tester.pump(const Duration(milliseconds: 500));
      await waitFor(
        tester,
        () => find.byType(VideoPlayer).evaluate().isNotEmpty,
      );
      expect(
        tester
            .widget<ClipLibraryDetail>(find.byType(ClipLibraryDetail))
            .clip
            .id,
        'holiday-duet',
      );
      final player = tester
          .widget<VideoPlayer>(find.byType(VideoPlayer))
          .controller;
      await press(tester, 'Play');
      await waitFor(tester, () => player.value.position.inMilliseconds > 500);
      await press(tester, 'Pause video');
      await capture(binding, tester, 'real-video');
      await press(tester, 'Add to a practice note');
      expect(
        tester
            .widget<PracticeEditor>(find.byType(PracticeEditor))
            .initialClip
            ?.id,
        'holiday-duet',
      );
      report['play_and_practice'] =
          'actual video advanced and opened a note with its clip';
      await returnTo(tester, find.byType(ClipLibraryDetail));
      await returnTo(tester, find.byType(FloorPage));

      final challenges = find.byTooltip('Challenges');
      await reveal(tester, challenges);
      await tester.tap(challenges.hitTestable());
      await tester.pump();
      await waitFor(
        tester,
        () => find.byType(ChallengesPage).hitTestable().evaluate().isNotEmpty,
      );
      expect(find.byType(ChallengesPage), findsOneWidget);
      await reveal(tester, find.byTooltip('Open challenge').first);
      await tester.tap(find.byTooltip('Open challenge').first);
      await waitFor(
        tester,
        () =>
            find.byTooltip('Play practice reference').evaluate().isNotEmpty &&
            decodedCovers() >= 1,
      );
      expect(find.byType(ChallengePage), findsOneWidget);
      expect(find.byTooltip('Share your take'), findsOneWidget);
      await capture(binding, tester, 'challenge');
      report['challenges'] = 'challenge opens its real practice reference';
      await returnTo(tester, find.byType(ChallengesPage));
      await returnTo(tester, find.byType(FloorPage));

      await press(tester, 'Browse dance portraits');
      expect(
        tester
            .widget<PortraitPickerPage>(find.byType(PortraitPickerPage))
            .browseOnly,
        isTrue,
      );
      await waitFor(tester, () => decodedCovers() >= 3);
      await capture(binding, tester, 'photo-gallery');
      await press(tester, 'Portrait 55');
      expect(
        tester
            .widget<PortraitPreviewPage>(find.byType(PortraitPreviewPage))
            .portrait
            .id,
        'portrait-055',
      );
      await waitFor(tester, () => decodedCovers() >= 1);
      report['photos'] = 'gallery decoded and opened its 55th item';
      await returnTo(tester, find.byType(PortraitPickerPage));
      await returnTo(tester, find.byType(FloorPage));
      await returnTo(tester, find.byType(DanceShell));

      await press(tester, 'Studio');
      await waitFor(tester, () => decodedCovers() >= 2);
      await capture(binding, tester, 'studio');
      await press(tester, 'Saved clips');
      expect(
        tester
            .widget<MediaLibraryPage>(find.byType(MediaLibraryPage))
            .showSaved,
        isTrue,
      );
      await goBack(tester);
      report['studio'] = 'inline video shelf decoded and saved clips opened';

      await press(tester, 'Inbox');
      final chatSearch = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search chats',
      );
      await waitFor(
        tester,
        () =>
            chatSearch.evaluate().isNotEmpty &&
            find.byTooltip('New conversation').evaluate().isNotEmpty,
      );
      await press(tester, 'Unread');
      await waitFor(
        tester,
        () =>
            find.text('No unread chats').evaluate().isNotEmpty ||
            find.byType(SignedAvatar).evaluate().isNotEmpty,
      );
      await press(tester, 'All');
      await tester.tap(chatSearch);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.enterText(
        chatSearch,
        'Missing QA chat ${DateTime.now().microsecondsSinceEpoch}',
      );
      await waitFor(
        tester,
        () => find.text('No matching chats').evaluate().isNotEmpty,
      );
      await press(tester, 'Clear chat search');
      expect(tester.widget<TextField>(chatSearch).controller!.text, isEmpty);
      await waitFor(
        tester,
        () =>
            find.text('No conversations yet').evaluate().isNotEmpty ||
            find.byType(SignedAvatar).evaluate().isNotEmpty,
      );
      await capture(binding, tester, 'inbox');
      await press(tester, 'New conversation');
      expect(find.text('New conversation'), findsOneWidget);
      await goBack(tester);
      report['inbox'] =
          'unread filter, chat search and real conversation picker';

      await press(tester, 'Me');
      await waitFor(
        tester,
        () => find.byTooltip('Change profile photo').evaluate().isNotEmpty,
      );
      expect(find.byType(SignedAvatar), findsWidgets);
      expect(find.text('Photo library'), findsNothing);
      await capture(binding, tester, 'me');
      await press(tester, 'Open coin wallet');
      expect(find.byType(WalletPage), findsOneWidget);
      await returnTo(tester, find.byType(MePage));
      await press(tester, 'Practice history');
      expect(find.byType(PracticeHistoryPage), findsOneWidget);
      await returnTo(tester, find.byType(MePage));
      await press(tester, 'Change profile photo');
      await press(tester, 'Browse profile images');
      expect(
        tester
            .widget<PortraitPickerPage>(find.byType(PortraitPickerPage))
            .browseOnly,
        isFalse,
      );
      await returnTo(tester, find.byType(EditProfilePage));
      await returnTo(tester, find.byType(MePage));
      report['profile'] =
          'profile avatar, coin wallet, practice history and photo picker opened';
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
