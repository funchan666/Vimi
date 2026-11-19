import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/shell.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native recovery email returns to the real password form',
    (tester) async {
      await vimi.main();
      await waitFor(
        tester,
        () => find.byType(WelcomePage).evaluate().isNotEmpty,
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await press(tester, 'Sign in');
      await press(tester, 'Forgot password?');
      await enter(
        tester,
        'Email',
        const String.fromEnvironment('QA_REGISTRATION_EMAIL'),
      );
      await press(tester, 'Send recovery link');
      await waitFor(
        tester,
        () => find
            .text(
              'If an account uses this email, a recovery link is on its way.',
            )
            .evaluate()
            .isNotEmpty,
      );
      await capture(binding, tester, 'native-recovery-email-request');
      // ignore: avoid_print
      print('VIMI_QA_RECOVERY_AWAITING_EMAIL');
      await waitFor(
        tester,
        () => find.byType(UpdatePasswordPage).evaluate().isNotEmpty,
        timeout: const Duration(minutes: 6),
      );
      await enter(
        tester,
        'New password',
        const String.fromEnvironment('QA_NEXT_PASSWORD'),
      );
      await enter(
        tester,
        'Confirm new password',
        const String.fromEnvironment('QA_NEXT_PASSWORD'),
      );
      await capture(binding, tester, 'native-password-recovery');
      await press(tester, 'Save password');
      await waitFor(
        tester,
        () => find.byType(DanceShell).evaluate().isNotEmpty,
      );
      final auth = appController(tester).repo!.client.auth;
      final email = auth.currentUser!.email!;
      await appController(tester).signOut();
      final result = await auth.signInWithPassword(
        email: email,
        password: const String.fromEnvironment('QA_NEXT_PASSWORD'),
      );
      expect(result.user!.email, email);
      await auth.signOut();
      binding.reportData ??= {};
      binding.reportData!.addAll({
        'password_recovery_email_callback_update_reauthentication': 'passed',
      });
    },
    timeout: const Timeout(Duration(minutes: 9)),
  );
}
