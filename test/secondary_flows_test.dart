import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/core/local_studio.dart';
import 'package:vimi/core/models.dart';
import 'package:vimi/design/vimi_ui.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/shell.dart';
import 'package:vimi/features/auth/account_security_pages.dart';
import 'package:vimi/features/community/publish_page.dart';
import 'package:vimi/features/profile/help_pages.dart';
import 'package:vimi/features/profile/profile_pages.dart';
import 'package:vimi/features/profile/moderation_pages.dart';
import 'package:vimi/features/studio/studio_pages.dart';
import 'package:vimi/features/studio/media_library_pages.dart';

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);
Future<void> show(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty)
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  await tester.ensureVisible(target.last);
  await tester.pumpAndSettle();
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
}

Future<void> tap(WidgetTester tester, String label) async {
  final target = find.byWidgetPredicate(
    (w) =>
        (w is Text && w.data == label) || (w is Tooltip && w.message == label),
  );
  await show(tester, target);
  await tester.tap(target.last);
  await tester.pumpAndSettle();
}

Future<AppController> controller() async {
  SharedPreferences.setMockInitialValues({});
  final app = AppController(
    studio: LocalStudio(await SharedPreferences.getInstance()),
  );
  app.challenges = jsonRows(
    jsonDecode(File('assets/data/challenges.json').readAsStringSync()),
  ).map(ChoreographyPrompt.fromJson).toList();
  return app;
}

Future<void> mount(
  WidgetTester tester,
  AppController app,
  Widget page, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    VimiScope(
      controller: app,
      child: MaterialApp(
        theme: vimiTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'practice draft reopens, saves, edits and deletes actual stored note',
    (tester) async {
      final app = await controller();
      await mount(tester, app, const StudioPage());
      await tap(tester, 'Start a practice note');
      await tester.enterText(field('Routine or song'), 'QA chorus transition');
      await tester.tap(find.byTooltip('Go back'));
      await tester.pumpAndSettle();
      await tap(tester, 'Start a practice note');
      expect(
        tester.widget<TextField>(field('Routine or song')).controller!.text,
        'QA chorus transition',
      );
      await tap(tester, 'Save practice');
      expect(
        (await app.studio.load('guest')).single.routine,
        'QA chorus transition',
      );
      await tap(tester, 'Open practice');
      await show(tester, field('Minutes'));
      await tester.enterText(field('Minutes'), '35');
      await tap(tester, 'Save practice');
      expect((await app.studio.load('guest')).single.minutes, 35);
      expect(app.practices, hasLength(1));
      await tap(tester, 'Open practice');
      await tap(tester, 'Delete practice note');
      await tap(tester, 'Delete note');
      expect(await app.studio.load('guest'), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    },
  );

  testWidgets(
    'publisher restores challenge and caption, and discard clears real draft',
    (tester) async {
      final app = await controller();
      final challenge = app.challenges.first;
      await app.studio.writeDraft('publish.v1.guest', {
        'caption': 'A saved eight-count',
        'style': 'K-pop',
        'challenge': challenge.id,
        'client_id': 'e5555555-5555-4555-8555-555555555519',
        'rights': true,
      });
      await mount(tester, app, const PublishPage());
      await show(tester, field('What did you work on?'));
      expect(
        tester
            .widget<TextField>(field('What did you work on?'))
            .controller!
            .text,
        'A saved eight-count',
      );
      expect(
        tester.widgetList<ChoiceStrip>(find.byType(ChoiceStrip)).last.value,
        challenge.title,
      );
      await tap(tester, 'Discard draft');
      await tap(tester, 'Discard draft');
      expect(app.studio.readDraft('publish.v1.guest'), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    },
  );

  testWidgets(
    'icon-only navigation keeps labels, selected state and all destinations',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final app = await controller();
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      try {
        for (final size in [const Size(320, 740), const Size(900, 700)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          await mount(tester, app, const DanceShell(), scale: 1.3);
          for (final label in ['Floor', 'Studio', 'Inbox', 'Me']) {
            final icon = find.byTooltip(label);
            expect(
              find.descendant(of: icon, matching: find.text(label)),
              findsNothing,
              reason: 'Navigation captions stay hidden',
            );
            expect(icon, findsOneWidget);
            final bounds = tester.getSize(icon);
            expect(bounds.width, greaterThanOrEqualTo(48));
            expect(bounds.height, greaterThanOrEqualTo(48));
            await tester.tap(icon);
            await tester.pumpAndSettle();
            final button = tester.widget<VIconButton>(
              find.ancestor(of: icon, matching: find.byType(VIconButton)),
            );
            expect(button.selected, isTrue);
            expect(
              tester.getSemantics(
                find.ancestor(of: icon, matching: find.byType(VIconButton)),
              ),
              matchesSemantics(
                label: label,
                isButton: true,
                hasSelectedState: true,
                isSelected: true,
                hasEnabledState: true,
                isEnabled: true,
                isFocusable: true,
                hasTapAction: true,
              ),
            );
            expect(tester.takeException(), isNull, reason: '$label at $size');
          }
          await tester.pumpWidget(const SizedBox());
        }
      } finally {
        app.dispose();
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'secondary neon pages fit narrow and expanded layouts with larger type',
    (tester) async {
      final app = await controller();
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      for (final size in [const Size(320, 740), const Size(900, 700)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        for (final page in <Widget>[
          const WelcomePage(),
          const AuthPage(signUp: true),
          const AuthPage(signUp: false),
          const RecoverAccountPage(),
          const EmailConfirmationPage(email: 'qa@example.invalid'),
          const ChangePasswordPage(),
          const HelpCenterPage(),
          const SettingsPage(),
          const EditProfilePage(
            profile: Dancer(id: 'layout-fixture', name: 'Layout preview'),
          ),
          const ModerationPage(),
          const PracticeEditor(),
          MediaLibraryPage(
            practiceBuilder: (clip) => PracticeEditor(initialClip: clip),
          ),
          const PortraitPickerPage(),
          const PublishPage(),
        ]) {
          await mount(tester, app, page, scale: 1.3);
          if (page is MediaLibraryPage) {
            expect(find.text('10 clips'), findsOneWidget);
          }
          if (page is PortraitPickerPage) {
            expect(find.textContaining('Explore 55 images.'), findsOneWidget);
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '${page.runtimeType} at $size',
          );
        }
      }
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    },
  );
}
