import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/profile/profile_pages.dart';
import 'package:vimi/features/profile/moderation_pages.dart';
import 'package:vimi/features/shell.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'direct registration, password validation and separate fixed reviewer',
    (tester) async {
      requireQaFixtures();
      final results = <String, Object?>{};
      binding.reportData = results;
      await vimi.main();
      await waitFor(tester, () => find.byType(VimiScope).evaluate().isNotEmpty);
      if (appController(tester).signedIn) await appController(tester).signOut();
      await waitFor(
        tester,
        () => find.byType(WelcomePage).evaluate().isNotEmpty,
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await press(tester, 'Join the crew');
      await enter(tester, 'Display name', 'Vimi QA Direct Registration');
      await enter(tester, 'Email', const String.fromEnvironment('QA_EMAIL_C'));
      await enter(
        tester,
        'Password',
        const String.fromEnvironment('QA_PASSWORD_C'),
      );
      await enter(tester, 'Date of birth · YYYY-MM-DD', '2000-01-01');
      await reveal(tester, find.byTooltip('Accept Terms and Privacy Policy'));
      await tester.tap(find.byTooltip('Accept Terms and Privacy Policy'));
      await press(tester, 'Create account');
      await waitFor(
        tester,
        () => find.byType(DanceShell).evaluate().isNotEmpty,
        reason: 'Registration still requires an email confirmation.',
      );
      final app = appController(tester);
      await waitFor(tester, () => app.profile != null);
      expect(
        app.repo!.client.auth.currentUser!.email,
        const String.fromEnvironment('QA_EMAIL_C'),
      );
      expect(app.isModerator, isFalse);
      results['native_signup_without_verification'] = 'passed';
      await capture(binding, tester, 'native-direct-registration');
      await app.signOut();
      await waitFor(
        tester,
        () => find.byType(WelcomePage).evaluate().isNotEmpty,
      );
      await press(tester, 'Sign in');
      await enter(tester, 'Email', const String.fromEnvironment('QA_EMAIL_C'));
      await enter(tester, 'Password', 'wrong-password-for-this-fixture');
      await reveal(tester, find.byTooltip('Accept Terms and Privacy Policy'));
      await tester.tap(find.byTooltip('Accept Terms and Privacy Policy'));
      await press(tester, 'Sign in');
      await waitFor(
        tester,
        () => find.text('Invalid login credentials').evaluate().isNotEmpty,
      );
      expect(app.signedIn, isFalse);
      results['wrong_password_rejected'] = 'passed';
      await enter(
        tester,
        'Password',
        const String.fromEnvironment('QA_PASSWORD_C'),
      );
      await press(tester, 'Sign in');
      await waitFor(tester, () => app.signedIn && app.profile != null);
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
      results['direct_signup_fixture_deleted'] = 'passed';
      await press(tester, 'Sign in');
      await signIn(
        tester,
        email: const String.fromEnvironment('QA_REVIEWER_EMAIL'),
        password: const String.fromEnvironment('QA_REVIEWER_PASSWORD'),
      );
      expect(app.isModerator, isTrue);
      expect(
        app.repo!.client.auth.currentUser!.email,
        isNot('funchan7777777@gmail.com'),
      );
      await press(tester, 'Me');
      await tester.tap(find.byTooltip('Open settings'));
      await tester.pump(const Duration(milliseconds: 700));
      await press(tester, 'Content review');
      await waitFor(
        tester,
        () => find.byType(ModerationPage).evaluate().isNotEmpty,
      );
      await capture(binding, tester, 'native-fixed-reviewer-queue');
      results['separate_fixed_reviewer_signin_settings_queue'] = 'passed';
      await app.signOut();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
