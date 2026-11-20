import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
    'welcome photos, account gate, registration consent and public policies',
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
      expect(find.text('Explore the studio'), findsNothing);
      expect(find.byType(DanceShell), findsNothing);

      await press(tester, 'Join the crew');
      expect(tester.widget<AuthPage>(find.byType(AuthPage)).signUp, isTrue);
      expect(input('Display name'), findsOneWidget);
      await capture(binding, tester, 'native-sign-up');
      await press(tester, 'Create account');
      expect(find.text('Agreement required'), findsOneWidget);
      await press(tester, 'Review agreement');
      expect(find.text('Agreement required'), findsNothing);
      await enter(tester, 'Display name', 'Dance tester');
      await enter(tester, 'Email', 'consent-check@example.invalid');
      await enter(tester, 'Password', 'only-a-local-ui-check');
      await enter(tester, 'Date of birth', '2020-01-01');
      await press(tester, 'Create account');
      expect(find.text('Agreement required'), findsOneWidget);
      expect(appController(tester).signedIn, isFalse);
      await press(tester, 'Review agreement');
      expect(find.text('Agreement required'), findsNothing);
      await press(tester, 'Community Guidelines');
      expect(
        tester.widget<LegalPage>(find.byType(LegalPage)).file,
        'community',
      );
      await goBack(tester);
      final agree = find.byTooltip(
        'Agree to Terms of Use and Community Guidelines',
      );
      await reveal(tester, agree);
      await tester.tap(agree);
      await tester.pumpAndSettle();
      await capture(binding, tester, 'native-sign-up-agreement');
      results['signup_blocks_unaccepted_terms_and_rules'] = 'passed';
      await press(tester, 'Create account');
      expect(
        find.text('You’re not eligible to create an account.'),
        findsOneWidget,
      );
      expect(appController(tester).signedIn, isFalse);
      results['age_screen_blocks_ineligible_signup'] = 'passed';
      await goBack(tester);
      await press(tester, 'Sign in');
      expect(tester.widget<AuthPage>(find.byType(AuthPage)).signUp, isFalse);
      expect(input('Email'), findsOneWidget);
      expect(agree, findsNothing);
      await capture(binding, tester, 'native-sign-in');
      await press(tester, 'Forgot password?');
      expect(find.byType(RecoverAccountPage), findsOneWidget);
      await goBack(tester);
      await goBack(tester);
      results['signup_and_signin_routes'] = 'passed';

      await press(tester, 'Terms of Use');
      expect(tester.widget<LegalPage>(find.byType(LegalPage)).file, 'terms');
      await goBack(tester);
      await press(tester, 'Privacy Policy');
      expect(find.byType(LegalPage), findsOneWidget);
      expect(find.textContaining('privacy', findRichText: true), findsWidgets);
      await goBack(tester);
      await press(tester, 'Child safety');
      expect(find.byType(LegalPage), findsOneWidget);
      expect(find.text('Child safety standards'), findsOneWidget);
      await goBack(tester);
      results['terms_privacy_and_child_safety_readable_without_account'] =
          'passed';

      await press(tester, 'Sign in to preview the duet');
      expect(tester.widget<AuthPage>(find.byType(AuthPage)).signUp, isFalse);
      expect(find.byType(ClipLibraryDetail), findsNothing);
      expect(find.byType(DanceShell), findsNothing);
      await goBack(tester);
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(appController(tester).signedIn, isFalse);
      results['signed_out_duet_requires_account_and_supports_back'] = 'passed';
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
