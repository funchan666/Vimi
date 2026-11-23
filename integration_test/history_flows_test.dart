import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/core/dance_repository.dart';
import 'package:vimi/core/models.dart';
import 'package:vimi/design/page_footer.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/community/community_pages.dart';
import 'package:vimi/features/messages/inbox_pages.dart';
import 'package:vimi/features/profile/profile_pages.dart';
import 'package:vimi/features/profile/help_pages.dart';
import 'package:vimi/features/profile/moderation_pages.dart';
import 'support.dart';

Finder mainScroll() {
  final list = find.byType(ListView);
  if (list.evaluate().isEmpty) return find.byWidgetPredicate((_) => false);
  return find
      .descendant(of: list.last, matching: find.byType(Scrollable))
      .first;
}

PageFooter<T> footer<T>(WidgetTester tester) =>
    tester.widget<PageFooter<T>>(find.byType(PageFooter<T>).last);
Future<void> loaded<T>(WidgetTester tester, int count) async {
  final finder = find.byType(PageFooter<T>);
  final end = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(end)) {
    if (finder.evaluate().isNotEmpty) {
      final pager = footer<T>(tester).pager;
      if (pager.items.length == count && !pager.loading && pager.error == null)
        return;
      if (pager.error != null)
        throw TestFailure('History page failed: ${pager.error}');
    } else {
      final list = mainScroll();
      if (list.evaluate().isNotEmpty) {
        final reverse =
            tester.widget<Scrollable>(list).axisDirection == AxisDirection.up;
        await tester.drag(list, Offset(0, reverse ? 600 : -600));
      }
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
  throw TestFailure(
    'Expected a real $T page containing $count entries; footer=${finder.evaluate().length}.',
  );
}

Future<void> more(
  WidgetTester tester,
  String label, {
  bool reverse = false,
}) async {
  final target = action(label);
  final scrollable = mainScroll();
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      600,
      scrollable: scrollable,
      maxScrolls: 160,
    );
  }
  await tester.ensureVisible(target.last);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(target.last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> top(WidgetTester tester) async {
  final scrollable = mainScroll();
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android stable history, search, relationships, draft continuity and reviewer queues',
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
      await press(tester, 'Sign in');
      await signIn(
        tester,
        email: const String.fromEnvironment('QA_EMAIL_A'),
        password: const String.fromEnvironment('QA_PASSWORD_A'),
      );
      final app = appController(tester), repo = appController(tester).repo!;
      final peerClient = SupabaseClient(
        const String.fromEnvironment('SUPABASE_URL'),
        const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(peerClient.dispose);
      await peerClient.auth.signInWithPassword(
        email: const String.fromEnvironment('QA_EMAIL_B'),
        password: const String.fromEnvironment('QA_PASSWORD_B'),
      );
      final peer = DanceRepository(peerClient);
      await openTestPage(tester, const DancerDirectory());
      await enter(tester, 'Search dancer names', 'History QA');
      await press(tester, 'Find dancers');
      await loaded<Dancer>(tester, 25);
      await more(tester, 'More dancers');
      await loaded<Dancer>(tester, 32);
      expect(footer<Dancer>(tester).pager.hasMore, isFalse);
      await top(tester);
      await enter(tester, 'Search dancer names', 'History QA Dancer 30');
      await press(tester, 'Find dancers');
      await loaded<Dancer>(tester, 1);
      expect(
        footer<Dancer>(tester).pager.items.single.name,
        'History QA Dancer 30',
      );
      binding.reportData!['directory_paging_and_query_reset'] = 'passed';
      await capture(binding, tester, 'history-directory-search');
      await goBack(tester);
      for (final followers in [true, false]) {
        await openTestPage(
          tester,
          RelationsPage(id: repo.account, followers: followers),
        );
        await loaded<Dancer>(tester, 25);
        await more(tester, 'More dancers');
        await loaded<Dancer>(tester, 32);
        await goBack(tester);
      }
      binding.reportData!['followers_and_following_paging'] = 'passed';
      final dancer = (await repo.dancer(peer.account))!;
      await openTestPage(tester, DancerPage(id: dancer.id));
      await loaded<DancePost>(tester, 20);
      await more(tester, 'More from the floor');
      await loaded<DancePost>(tester, 40);
      await more(tester, 'More from the floor');
      await loaded<DancePost>(tester, 41);
      expect(
        footer<DancePost>(tester).pager.items.map((p) => p.id).toSet(),
        hasLength(41),
      );
      app.changed();
      await loaded<DancePost>(tester, 41);
      binding.reportData!['post_archive_paging_and_refresh_preserves_depth'] =
          'passed';
      await goBack(tester);
      await openTestPage(
        tester,
        PostDetailPage(
          post: (await repo.post(const String.fromEnvironment('QA_POST')))!,
        ),
      );
      await loaded<Json>(tester, 25);
      await more(tester, 'Earlier comments');
      await loaded<Json>(tester, 50);
      await more(tester, 'Earlier comments');
      await loaded<Json>(tester, 61);
      await enter(
        tester,
        'Add a comment',
        'Keep this native comment draft during refresh.',
      );
      app.changed();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.widget<TextField>(input('Add a comment')).controller!.text,
        'Keep this native comment draft during refresh.',
      );
      await loaded<Json>(tester, 61);
      binding.reportData!['comment_history_and_unsent_draft'] = 'passed';
      await capture(binding, tester, 'history-comments-draft');
      await goBack(tester);
      await openTestPage(tester, ChatPage(peer: dancer));
      await loaded<Json>(tester, 50);
      await more(tester, 'Earlier messages', reverse: true);
      await loaded<Json>(tester, 100);
      await more(tester, 'Earlier messages', reverse: true);
      await loaded<Json>(tester, 127);
      await enter(tester, 'Your message', 'Keep this native message draft.');
      const reply = 'History QA live reply after loading 127 messages';
      await peer.send(repo.account, reply, const Uuid().v4());
      await loaded<Json>(tester, 128);
      expect(
        tester.widget<TextField>(input('Your message')).controller!.text,
        'Keep this native message draft.',
      );
      expect(
        footer<Json>(tester).pager.items.where((row) => row['body'] == reply),
        hasLength(1),
      );
      expect(
        footer<Json>(tester).pager.items.map((row) => row['id']).toSet(),
        hasLength(128),
      );
      await capture(binding, tester, 'history-chat-realtime-draft');
      binding.reportData!['127_message_history_live_arrival_and_draft'] =
          'passed';
      await goBack(tester);
      await openTestPage(tester, const MyReportsPage());
      await loaded<Json>(tester, 25);
      await more(tester, 'Earlier reports');
      await loaded<Json>(tester, 31);
      binding.reportData!['private_report_history'] = 'passed';
      await goBack(tester);
      var forbidden = false;
      try {
        await repo.reviewPage('comments');
      } on FunctionException catch (e) {
        forbidden = e.status == 403;
      }
      expect(forbidden, isTrue);
      await app.signOut();
      await waitFor(
        tester,
        () => find.byType(WelcomePage).evaluate().isNotEmpty,
      );
      await press(tester, 'Sign in');
      await signIn(
        tester,
        email: const String.fromEnvironment('QA_REVIEWER_EMAIL'),
        password: const String.fromEnvironment('QA_REVIEWER_PASSWORD'),
      );
      await openTestPage(tester, const ModerationPage());
      await press(tester, 'Comments');
      await loaded<Json>(tester, 25);
      await more(tester, 'More review items');
      await loaded<Json>(tester, 35);
      await top(tester);
      await press(tester, 'Reports');
      await loaded<Json>(tester, 25);
      await more(tester, 'More review items');
      await loaded<Json>(tester, 31);
      binding.reportData!['review_queue_paging_section_reset_and_role_denial'] =
          'passed';
      await capture(binding, tester, 'history-review-queue');
      await app.signOut();
      await tester.pump(const Duration(seconds: 1));
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
