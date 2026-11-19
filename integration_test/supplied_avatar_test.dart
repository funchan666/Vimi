import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/core/media_library.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/profile/profile_pages.dart';
import 'package:vimi/features/studio/media_library_pages.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'saved library avatar reaches an actual rendered network frame',
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
      await press(tester, 'Sign in');
      await signIn(
        tester,
        email: const String.fromEnvironment('QA_EMAIL_C'),
        password: const String.fromEnvironment('QA_PASSWORD_C'),
      );
      await press(tester, 'Me');
      await press(tester, 'Edit dance profile');
      await press(tester, 'Browse profile images');
      final portrait = (await MediaLibrary.load()).portraits.first;
      await press(tester, portrait.title);
      await press(tester, 'Use this image');
      await waitFor(
        tester,
        () => find.byType(PortraitPickerPage).evaluate().isEmpty,
      );
      await press(tester, 'Save profile');
      await waitFor(
        tester,
        () => find.byType(EditProfilePage).evaluate().isEmpty,
      );
      final images = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url.contains('/avatar/'),
      );
      await waitFor(tester, () => images.evaluate().isNotEmpty);
      final image = tester.widget<Image>(images.first);
      await precacheImage(image.image, tester.element(images.first));
      await tester.pump(const Duration(seconds: 1));
      final pixels = find.descendant(
        of: images.first,
        matching: find.byType(RawImage),
      );
      await waitFor(
        tester,
        () =>
            pixels.evaluate().isNotEmpty &&
            tester.widget<RawImage>(pixels.first).image != null,
      );
      final rendered = tester.widget<RawImage>(pixels.first).image!;
      expect(rendered.width, greaterThan(500));
      expect(rendered.height, greaterThan(500));
    expect(rendered.width, lessThan(rendered.height));
      await capture(binding, tester, 'supplied-avatar-rendered');
      binding.reportData!['saved_avatar_network_frame_rendered'] = 'passed';
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
      binding.reportData!['temporary_render_actor_deleted'] = 'passed';
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
