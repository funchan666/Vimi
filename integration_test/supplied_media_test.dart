import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/core/media_library.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/profile/profile_pages.dart';
import 'package:vimi/features/studio/media_library_pages.dart';
import 'package:vimi/features/studio/studio_pages.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'all supplied assets decode, play and persist through real journeys',
    (tester) async {
      requireQaFixtures();
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
      final catalog = await MediaLibrary.load();
      expect(catalog.clips, hasLength(10));
      expect(catalog.portraits, hasLength(55));
      for (final portrait in catalog.portraits) {
        final bytes = await rootBundle.load(portrait.asset);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0));
        frame.image.dispose();
        codec.dispose();
      }
      binding.reportData!['all_55_full_images_decode_on_android'] = 'passed';
      await press(tester, 'Explore the studio');
      await press(tester, 'Explore the dance video library');
      await waitFor(tester, () => find.text('10 clips').evaluate().isNotEmpty);
      await capture(binding, tester, 'supplied-video-library');
      for (final clip in catalog.clips) {
        await openTestPage(
          tester,
          ClipLibraryDetail(
            clip: clip,
            practiceBuilder: (value) => PracticeEditor(initialClip: value),
          ),
        );
        await waitFor(
          tester,
          () => find.byType(VideoPlayer).evaluate().isNotEmpty,
        );
        final player = tester
            .widget<VideoPlayer>(find.byType(VideoPlayer))
            .controller;
        expect(player.dataSource, clip.asset);
        expect(
          (player.value.duration.inMilliseconds - clip.duration * 1000).abs(),
          lessThan(200),
        );
        await reveal(tester, find.byTooltip('Play video'));
        await tester.tap(find.byTooltip('Play video'));
        await tester.pump(const Duration(milliseconds: 900));
        await waitFor(tester, () => player.value.position.inMilliseconds > 100);
        expect(player.value.hasError, isFalse);
        await player.pause();
        await goBack(tester);
      }
      binding.reportData!['all_10_bundled_videos_native_playback'] = 'passed';
      await press(tester, catalog.clips.first.title);
      await press(tester, 'Save clip');
      expect(
        appController(
          tester,
        ).studio.preferences.getStringList('library-saved.v1.guest'),
        contains(catalog.clips.first.id),
      );
      await press(tester, 'Mirror off');
      await press(tester, 'Loop off');
      await press(tester, '0.5×');
      await capture(binding, tester, 'supplied-clip-practice-controls');
      await press(tester, 'Add to a practice note');
      await enter(
        tester,
        'What clicked? What is next?',
        'Keep the weight shift clear.',
      );
      await press(tester, 'Save practice');
      final note = (await appController(tester).studio.load('guest')).first;
      expect(note.videoPath, catalog.clips.first.source);
      await waitFor(
        tester,
        () =>
            find.byType(PracticeEditor).evaluate().isEmpty &&
            find.byType(ClipLibraryDetail).evaluate().isNotEmpty,
        reason: 'Saving the note did not return to the clip detail.',
      );
      await goBack(tester);
      await waitFor(
        tester,
        () =>
            find.byType(ClipLibraryDetail).evaluate().isEmpty &&
            find.byType(MediaLibraryPage).evaluate().isNotEmpty,
        reason: 'Back from the clip did not return to the video library.',
      );
      // The grid retains its scroll position; return to the filters like a user.
      await tester.drag(find.byType(MediaLibraryPage), const ui.Offset(0, 900));
      await tester.pump(const Duration(milliseconds: 500));
      await press(tester, 'Saved');
      expect(find.text('1 clip'), findsOneWidget);
      await goBack(tester);
      await press(tester, 'Open practice');
      await waitFor(
        tester,
        () => find.byType(VideoPlayer).evaluate().isNotEmpty,
      );
      expect(
        tester
            .widget<VideoPlayer>(find.byType(VideoPlayer))
            .controller
            .dataSource,
        catalog.clips.first.asset,
      );
      await capture(binding, tester, 'supplied-note-reopened');
      await goBack(tester);
      binding.reportData!['saved_filter_and_bundled_practice_save_reopen'] =
          'passed';
      await appController(tester).removePractice(note.id);
      await appController(
        tester,
      ).studio.preferences.remove('library-saved.v1.guest');

      await openTestPage(tester, const AuthPage(signUp: false));
      await signIn(
        tester,
        email: const String.fromEnvironment('QA_EMAIL_C'),
        password: const String.fromEnvironment('QA_PASSWORD_C'),
      );
      await press(tester, 'Me');
      await press(tester, 'Edit dance profile');
      await press(tester, 'Browse profile images');
      await waitFor(
        tester,
        () => find.textContaining('Explore 55 images.').evaluate().isNotEmpty,
      );
      await capture(binding, tester, 'supplied-profile-image-library');
      await press(tester, catalog.portraits.last.title);
      await capture(binding, tester, 'supplied-profile-image-full-preview');
      await press(tester, 'Use this image');
      await waitFor(
        tester,
        () =>
            find.byType(PortraitPickerPage).evaluate().isEmpty &&
            find.byType(EditProfilePage).evaluate().isNotEmpty,
      );
      await press(tester, 'Save profile');
      await waitFor(
        tester,
        () => appController(tester).profile?.avatar != null,
      );
      await waitFor(
        tester,
        () => find.byType(EditProfilePage).evaluate().isEmpty,
      );
      final app = appController(tester);
      final sourceBytes = await rootBundle.load(catalog.portraits.last.asset);
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          Uri.parse(await app.repo!.mediaUrl(app.profile!.avatar!)),
        );
        final response = await request.close();
        expect(response.statusCode, 200);
        final uploaded = await consolidateHttpClientResponseBytes(response);
        expect(
          sha256.convert(uploaded).toString(),
          sha256
              .convert(
                sourceBytes.buffer.asUint8List(
                  sourceBytes.offsetInBytes,
                  sourceBytes.lengthInBytes,
                ),
              )
              .toString(),
        );
      } finally {
        client.close(force: true);
      }
      await capture(binding, tester, 'supplied-profile-image-saved');
      binding.reportData!['last_of_55_images_selected_and_real_upload_bytes_verified'] =
          'passed';
      await openTestPage(tester, const DeleteAccountPage());
      await enter(
        tester,
        'Current password',
        const String.fromEnvironment('QA_PASSWORD_C'),
      );
      await press(tester, 'Delete account permanently');
      await press(tester, 'Delete my account');
      await waitFor(
        tester,
        () => find.byType(WelcomePage).evaluate().isNotEmpty,
      );
      binding.reportData!['temporary_actor_and_uploaded_avatar_deleted'] =
          'passed';
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
