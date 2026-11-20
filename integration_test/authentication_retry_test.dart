import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'wrong password can be corrected on the same sign-in screen',
    (tester) async {
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
      await enter(
        tester,
        'Email',
        const String.fromEnvironment('QA_REVIEWER_EMAIL'),
      );
      await enter(tester, 'Password', 'wrong-password-for-this-fixture');
      await press(tester, 'Sign in');
      await waitFor(
        tester,
        () => find.text('Invalid login credentials').evaluate().isNotEmpty,
      );
      expect(appController(tester).signedIn, isFalse);
      await enter(
        tester,
        'Password',
        const String.fromEnvironment('QA_REVIEWER_PASSWORD'),
      );
      await press(tester, 'Sign in');
      await waitFor(
        tester,
        () =>
            appController(tester).signedIn &&
            appController(tester).profile != null,
      );
      expect(appController(tester).isModerator, isTrue);
      binding.reportData!['same_screen_wrong_password_correction'] = 'passed';
      await appController(tester).signOut();
      await tester.pump(const Duration(seconds: 1));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
