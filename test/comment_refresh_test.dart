import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/core/dance_repository.dart';
import 'package:vimi/core/local_studio.dart';
import 'package:vimi/core/models.dart';
import 'package:vimi/design/vimi_ui.dart';
import 'package:vimi/features/community/community_pages.dart';

class RefreshRepository extends DanceRepository {
  RefreshRepository()
    : super(
        SupabaseClient(
          'https://example.invalid',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  final waiting = Completer<DancePost?>();
  int reads = 0;
  final sample = DancePost(
    id: 'post',
    author: const Dancer(id: 'author', name: 'QA Author'),
    caption: 'QA post',
    style: 'K-pop',
    mediaPath: 'unavailable',
    kind: 'image',
    createdAt: DateTime.utc(2026),
  );
  @override
  Future<DancePost?> post(String id) =>
      reads++ == 0 ? Future.value(sample) : waiting.future;
  @override
  Future<List<Json>> comments(String id) async => [];
  @override
  Future<String> mediaUrl(String path) async =>
      throw StateError('No fixture media.');
}

void main() {
  testWidgets('pending post refresh preserves the comment editor and focus', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = (await tester.runAsync(() async => RefreshRepository()))!;
    final app = AppController(
      studio: LocalStudio(await SharedPreferences.getInstance()),
      repo: repo,
    );
    await tester.pumpWidget(
      VimiScope(
        controller: app,
        child: MaterialApp(
          theme: vimiTheme(),
          home: PostDetailPage(post: repo.sample),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Add a comment',
    );
    await tester.scrollUntilVisible(
      field,
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.enterText(field, 'Keep this unfinished thought.');
    await tester.pump();
    final focus = FocusManager.instance.primaryFocus;
    app.changed();
    await tester.pump();
    expect(field, findsOneWidget);
    expect(
      tester.widget<TextField>(field).controller!.text,
      'Keep this unfinished thought.',
    );
    expect(FocusManager.instance.primaryFocus, same(focus));
    repo.waiting.complete(repo.sample);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field).controller!.text,
      'Keep this unfinished thought.',
    );
    await tester.pumpWidget(const SizedBox());
    app.dispose();
    await tester.runAsync(repo.client.dispose);
  });
}
