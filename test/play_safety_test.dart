import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/core/local_studio.dart';
import 'package:vimi/design/vimi_ui.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/main.dart';

class RestrictedController extends AppController {
  RestrictedController(LocalStudio studio) : super(studio: studio);
  @override
  bool get signedIn => true;
  @override
  String get account => 'restricted-qa';
}

void main() {
  testWidgets(
    'child safety standards remain readable without a signed-in account',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final app = AppController(
        studio: LocalStudio(await SharedPreferences.getInstance()),
      );
      await tester.pumpWidget(
        VimiScope(
          controller: app,
          child: MaterialApp(
            theme: vimiTheme(),
            home: const LegalPage('Child safety standards', 'child-safety'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final text = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .data!;
      expect(text, contains('child sexual abuse and exploitation'));
      expect(text, contains('funchan7777777@gmail.com'));
      expect(text, contains('Do not attach'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    },
  );
  testWidgets('an unavailable account can still reach account deletion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = RestrictedController(
      LocalStudio(await SharedPreferences.getInstance()),
    )..accountStatus = 'suspended';
    await tester.pumpWidget(
      VimiScope(
        controller: app,
        child: VimiApp(controller: app),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delete account'), findsOneWidget);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account permanently'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Current password',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
