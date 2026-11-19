import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/design/vimi_ui.dart';

Finder input(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

void requireQaFixtures({bool social = false}) {
  const emailC = String.fromEnvironment('QA_EMAIL_C');
  const emailA = String.fromEnvironment('QA_EMAIL_A');
  const emailB = String.fromEnvironment('QA_EMAIL_B');
  final valid = social
      ? emailA.startsWith('vimi-qa-a-') &&
            emailA.endsWith('@example.invalid') &&
            emailB.startsWith('vimi-qa-b-') &&
            emailB.endsWith('@example.invalid')
      : emailC.startsWith('vimi-qa-direct-') &&
            emailC.endsWith('@example.invalid');
  if (!valid)
    throw StateError(
      'These destructive acceptance tests require labelled temporary QA accounts. Do not use member or operator accounts as fixtures.',
    );
}

Future<void> waitFor(
  WidgetTester tester,
  bool Function() ready, {
  String reason = 'The next screen did not become ready.',
  Duration timeout = const Duration(seconds: 45),
}) async {
  final end = DateTime.now().add(timeout);
  while (!ready() && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  if (!ready() && find.byType(VimiScope).evaluate().isNotEmpty) {
    final app = appController(tester);
    debugPrint(
      'Vimi QA wait: signedIn=${app.signedIn}; profile=${app.profile != null}; status=${app.accountStatus}; cloudError=${app.cloudError}',
    );
    if (WidgetsBinding.instance is IntegrationTestWidgetsFlutterBinding) {
      await (WidgetsBinding.instance as IntegrationTestWidgetsFlutterBinding)
          .takeScreenshot('native-failure');
    }
  }
  expect(ready(), isTrue, reason: reason);
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  final scrollable = find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .hitTestable();
  if (target.evaluate().isEmpty) {
    await waitFor(
      tester,
      () => target.evaluate().isNotEmpty || scrollable.evaluate().isNotEmpty,
    );
  }
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      230,
      scrollable: scrollable.last,
      maxScrolls: 35,
    );
  }
  await tester.ensureVisible(target.last);
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> press(WidgetTester tester, String label) async {
  final target = find.text(label);
  await reveal(tester, target);
  final button = find.ancestor(of: target.last, matching: find.byType(VButton));
  if (button.evaluate().isNotEmpty) {
    await waitFor(tester, () {
      final value = tester.widget<VButton>(button.last);
      return !value.busy && value.onPressed != null;
    }, reason: 'The $label action stayed unavailable.');
  }
  await waitFor(
    tester,
    () => target.last.hitTestable().evaluate().isNotEmpty,
    reason: 'The $label action is covered by another surface.',
  );
  await tester.tap(target.last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> enter(WidgetTester tester, String label, String value) async {
  final target = input(label);
  await reveal(tester, target);
  await waitFor(
    tester,
    () => find
        .descendant(of: target, matching: find.byType(EditableText))
        .evaluate()
        .isNotEmpty,
    reason: 'The $label editor did not become editable.',
  );
  await waitFor(
    tester,
    () => tester.widget<TextField>(target).enabled != false,
  );
  // Let Android's real IME attach before replacing an existing secure field.
  // Closing it immediately can send its older editing value back to Flutter.
  for (var attempt = 0; attempt < 2; attempt++) {
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(target, value);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    if (tester.widget<TextField>(target).controller!.text == value) return;
  }
  expect(
    tester.widget<TextField>(target).controller!.text == value,
    isTrue,
    reason: 'The $label field did not retain the entered value.',
  );
}

AppController appController(WidgetTester tester) =>
    tester.widget<VimiScope>(find.byType(VimiScope)).notifier!;

Future<void> capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 700));
  await binding.takeScreenshot(name);
}

Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Go back').last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> signIn(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await enter(tester, 'Email', email);
  await enter(tester, 'Password', password);
  final consent = find.byTooltip('Accept Terms and Privacy Policy');
  await reveal(tester, consent);
  await tester.tap(consent);
  await press(tester, 'Sign in');
  await waitFor(tester, () => appController(tester).signedIn);
  await waitFor(tester, () => appController(tester).profile != null);
  await tester.pump(const Duration(seconds: 1));
}

Future<void> openTestPage(WidgetTester tester, Widget page) async {
  final context = tester.element(find.byType(Scaffold).last);
  openPage(context, page);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}
