import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/profile/profile_pages.dart';
import 'package:vimi/features/profile/moderation_pages.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'existing member login deletion and fixed operator access',
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
      binding.reportData!['existing_member_password_signin'] = 'passed';
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
      binding.reportData!['native_delete_account'] = 'passed';
      await press(tester, 'Sign in');
      await signIn(
        tester,
        email: const String.fromEnvironment('QA_REVIEWER_EMAIL'),
        password: const String.fromEnvironment('QA_REVIEWER_PASSWORD'),
      );
      expect(appController(tester).isModerator, isTrue);
      await press(tester, 'Me');
      await tester.tap(find.byTooltip('Open settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await press(tester, 'Content review');
      await waitFor(
        tester,
        () => find.byType(ModerationPage).evaluate().isNotEmpty,
      );
      await capture(binding, tester, 'native-fixed-reviewer-queue');
      binding.reportData!['fixed_reviewer_settings_moderation_access'] =
          'passed';
      await appController(tester).signOut();
      await tester.pump(const Duration(seconds: 1));
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
