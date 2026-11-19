import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/core/models.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/profile/profile_pages.dart';
import 'package:vimi/features/profile/moderation_pages.dart';
import 'support.dart';
import 'history_flows_test.dart' as history;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native public safety text, child-safety queue and restricted-account deletion',
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
      await press(tester, 'Child safety');
      await waitFor(
        tester,
        () => find.byType(SelectableText).evaluate().isNotEmpty,
      );
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        contains('Child Safety Standards'),
      );
      await capture(binding, tester, 'play-child-safety-public');
      await goBack(tester);
      binding.reportData!['child_safety_readable_without_login'] = 'passed';
      await press(tester, 'Sign in');
      await signIn(
        tester,
        email: const String.fromEnvironment('QA_REVIEWER_EMAIL'),
        password: const String.fromEnvironment('QA_REVIEWER_PASSWORD'),
      );
      await openTestPage(tester, const ModerationPage());
      await press(tester, 'Reports');
      await press(tester, 'Child safety');
      await history.loaded<Json>(tester, 3);
      await capture(binding, tester, 'play-child-safety-review-filter');
      binding.reportData!['child_safety_filter_on_real_reports'] = 'passed';
      await appController(tester).signOut();
      await waitFor(
        tester,
        () => find.byType(WelcomePage).evaluate().isNotEmpty,
      );
      await press(tester, 'Sign in');
      // A is a deliberately suspended disposable actor from check_play_safety_backend.py.
      await enter(tester, 'Email', const String.fromEnvironment('QA_EMAIL_A'));
      await enter(
        tester,
        'Password',
        const String.fromEnvironment('QA_PASSWORD_A'),
      );
      await tester.tap(find.byTooltip('Accept Terms and Privacy Policy'));
      await press(tester, 'Sign in');
      await waitFor(
        tester,
        () =>
            appController(tester).signedIn &&
            appController(tester).accountStatus == 'suspended',
      );
      await waitFor(
        tester,
        () => find.text('Delete account').evaluate().isNotEmpty,
      );
      await press(tester, 'Delete account');
      await waitFor(
        tester,
        () => find.byType(DeleteAccountPage).evaluate().isNotEmpty,
      );
      await capture(binding, tester, 'play-restricted-account-delete');
      await enter(
        tester,
        'Current password',
        const String.fromEnvironment('QA_PASSWORD_A'),
      );
      await press(tester, 'Delete account permanently');
      await press(tester, 'Delete my account');
      await waitFor(
        tester,
        () => find.byType(WelcomePage).evaluate().isNotEmpty,
      );
      binding.reportData!['suspended_actor_native_account_deletion'] = 'passed';
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
