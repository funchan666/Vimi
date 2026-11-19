import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/core/dance_repository.dart';
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/auth/account_security_pages.dart';
import 'package:vimi/features/community/community_pages.dart';
import 'package:vimi/features/community/content_editor.dart';
import 'package:vimi/features/profile/profile_pages.dart';
import 'package:vimi/features/profile/help_pages.dart';
import 'package:vimi/features/profile/moderation_pages.dart';
import 'package:vimi/features/studio/studio_pages.dart';
import 'package:vimi/features/wallet/wallet_page.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android post details, editing, safety, review and account deletion',
    (tester) async {
      requireQaFixtures(social: true);
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
      await press(tester, 'Sign in');
      await signIn(
        tester,
        email: const String.fromEnvironment('QA_EMAIL_B'),
        password: const String.fromEnvironment('QA_PASSWORD_B'),
      );
      final app = appController(tester), repo = appController(tester).repo!;
      final ownId = repo.account,
          peerId = const String.fromEnvironment('QA_USER_A');
      final peerClient = SupabaseClient(
        const String.fromEnvironment('SUPABASE_URL'),
        const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(peerClient.dispose);
      await peerClient.auth.signInWithPassword(
        email: const String.fromEnvironment('QA_EMAIL_A'),
        password: const String.fromEnvironment('QA_PASSWORD_A'),
      );
      final peer = DanceRepository(peerClient);
      final pending = (await repo.feed(author: ownId)).first;
      final caption = pending.caption;
      await repo.block(peerId, false);
      await repo.follow(peerId, followed: true);
      await peer.follow(ownId, followed: true);
      await peerClient.functions.invoke(
        'moderate-content',
        body: {'kind': 'post', 'id': pending.id, 'status': 'approved'},
      );
      for (final comment in await repo.comments(pending.id)) {
        if (comment['author_id'] == ownId)
          await repo.deleteComment(comment['id'] as String);
      }
      await app.studio.clear(ownId);
      for (final key
          in app.studio.preferences
              .getKeys()
              .where((k) => k.startsWith('practice-draft.v1.$ownId.'))
              .toList()) {
        await app.studio.preferences.remove(key);
      }
      await app.refreshAccount();
      await tester.pump();
      final approved = (await repo.post(pending.id))!;
      expect((await peer.post(pending.id))!.status, 'approved');
      await openTestPage(tester, PostDetailPage(post: approved));
      await waitFor(tester, () => find.byType(PostTile).evaluate().isNotEmpty);
      if (!(await repo.post(pending.id))!.saved) {
        final save = find.byTooltip('Save post');
        await reveal(tester, save);
        await tester.tap(save);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(
        (await repo.feed(saved: true)).any((p) => p.id == pending.id),
        isTrue,
      );
      await enter(
        tester,
        'Add a comment',
        'QA comment from the actual comment editor',
      );
      await press(tester, 'Submit comment');
      await waitFor(
        tester,
        () => tester
            .widget<TextField>(input('Add a comment'))
            .controller!
            .text
            .isEmpty,
      );
      final comment = (await repo.comments(pending.id)).single;
      expect(comment['status'], 'pending');
      await peerClient.functions.invoke(
        'moderate-content',
        body: {'kind': 'comment', 'id': comment['id'], 'status': 'approved'},
      );
      await repo.postAction(pending.id, 'like', selected: true);
      expect((await repo.post(pending.id))!.likes, 1);
      await capture(binding, tester, 'native-post-comments');
      results['review_visibility_save_like_comment'] = 'passed';
      await goBack(tester);
      await openTestPage(
        tester,
        EditContentPage(
          kind: 'post',
          id: pending.id,
          text: caption,
          style: 'K-pop',
        ),
      );
      await enter(tester, 'Caption', '$caption edited');
      await press(tester, 'Save for review');
      await waitFor(
        tester,
        () => find.byType(EditContentPage).evaluate().isEmpty,
      );
      expect((await repo.post(pending.id))!.status, 'pending');
      results['edit_returns_to_review'] = 'passed';
      await openTestPage(tester, EditProfilePage(profile: app.profile!));
      await enter(
        tester,
        'A little about your dancing',
        'QA profile saved from Android',
      );
      await press(tester, 'Save profile');
      await waitFor(
        tester,
        () => find.byType(EditProfilePage).evaluate().isEmpty,
      );
      expect((await repo.dancer(ownId))!.bio, 'QA profile saved from Android');
      results['profile_edit_persisted'] = 'passed';
      await openTestPage(tester, const PracticeEditor());
      await enter(tester, 'Routine or song', 'QA native rehearsal');
      await enter(
        tester,
        'What clicked? What is next?',
        'Fix the last transition',
      );
      await press(tester, 'Save practice');
      await waitFor(
        tester,
        () => find.byType(PracticeEditor).evaluate().isEmpty,
      );
      expect(
        (await app.studio.load(ownId)).single.routine,
        'QA native rehearsal',
      );
      await openTestPage(tester, PracticeEditor(session: app.practices.single));
      await enter(tester, 'Minutes', '35');
      await press(tester, 'Save practice');
      await waitFor(
        tester,
        () => find.byType(PracticeEditor).evaluate().isEmpty,
      );
      expect((await app.studio.load(ownId)).single.minutes, 35);
      results['native_practice_save_reopen_edit'] = 'passed';
      await openTestPage(tester, const WalletPage());
      await waitFor(tester, () => find.text('0').evaluate().isNotEmpty);
      await capture(binding, tester, 'native-wallet-unconfigured-store');
      await goBack(tester);
      await openTestPage(tester, DancerPage(id: peerId));
      await waitFor(
        tester,
        () => action('Block dancer').evaluate().isNotEmpty,
      );
      await press(tester, 'Block dancer');
      await press(tester, 'Block dancer');
      await waitFor(tester, () => find.byType(DancerPage).evaluate().isEmpty);
      expect(await repo.canMessage(peerId), isFalse);
      expect((await repo.blocked()).single.id, peerId);
      await repo.block(peerId, false);
      expect(await repo.canMessage(peerId), isFalse);
      expect((await repo.dancer(peerId))!.isFollowing, isFalse);
      results['block_unblock_no_automatic_follow'] = 'passed';
      // Clear private routes before testing real account switching.
      await app.signOut();
      await waitFor(
        tester,
        () => find.byType(WelcomePage).evaluate().isNotEmpty,
      );
      await press(tester, 'Sign in');
      await signIn(
        tester,
        email: const String.fromEnvironment('QA_EMAIL_A'),
        password: const String.fromEnvironment('QA_PASSWORD_A'),
      );
      await openTestPage(tester, const ModerationPage());
      await waitFor(
        tester,
        () => find.text('Review item').evaluate().isNotEmpty,
      );
      await press(tester, 'Review item');
      await waitFor(
        tester,
        () => find.text('Approve content').evaluate().isNotEmpty,
      );
      await capture(binding, tester, 'native-content-review');
      await press(tester, 'Approve content');
      await press(tester, 'Approve');
      await waitFor(
        tester,
        () => find.byType(ReviewItemPage).evaluate().isEmpty,
      );
      expect((await peer.post(pending.id))!.status, 'approved');
      await goBack(tester);
      await openTestPage(
        tester,
        PostDetailPage(post: (await peer.post(pending.id))!),
      );
      await waitFor(
        tester,
        () =>
            find.byType(PostDetailPage).evaluate().isNotEmpty &&
            find.byType(PostTile).evaluate().isNotEmpty,
      );
      await reveal(tester, find.byTooltip('Post options'));
      await tester.tap(find.byTooltip('Post options'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await press(tester, 'Report this post');
      await press(tester, 'Other');
      await press(tester, 'Send report');
      await waitFor(
        tester,
        () => find
            .text('Report sent. This item is now hidden for you.')
            .evaluate()
            .isNotEmpty,
      );
      final reports = await appController(tester).repo!.reports();
      expect(reports.single['target_id'], pending.id);
      expect(await peer.post(pending.id), isNull);
      results['report_hides_content'] = 'passed';
      await goBack(tester);
      await openTestPage(tester, const MyReportsPage());
      await waitFor(
        tester,
        () => find.text('Submitted · awaiting review').evaluate().isNotEmpty,
      );
      await capture(binding, tester, 'native-report-status');
      await goBack(tester);
      await peerClient.functions.invoke(
        'moderate-content',
        body: {
          'kind': 'report',
          'id': reports.single['id'],
          'status': 'resolved',
        },
      );
      results['report_status_resolve'] = 'passed';
      await openTestPage(tester, const ChangePasswordPage());
      await enter(
        tester,
        'Current password',
        const String.fromEnvironment('QA_PASSWORD_A'),
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
      await press(tester, 'Update password');
      await waitFor(
        tester,
        () => find.byType(ChangePasswordPage).evaluate().isEmpty,
      );
      await peerClient.auth.signInWithPassword(
        email: const String.fromEnvironment('QA_EMAIL_A'),
        password: const String.fromEnvironment('QA_NEXT_PASSWORD'),
      );
      results['reauthenticated_password_change'] = 'passed';
      // Delete only the two uniquely labelled QA actors, including actual uploads.
      await openTestPage(tester, const DeleteAccountPage());
      await enter(
        tester,
        'Current password',
        const String.fromEnvironment('QA_NEXT_PASSWORD'),
      );
      await press(tester, 'Delete account permanently');
      await press(tester, 'Delete my account');
      await waitFor(
        tester,
        () => find.byType(WelcomePage).evaluate().isNotEmpty,
      );
      results['native_account_delete'] = 'passed';
      await repo.client.auth.signInWithPassword(
        email: const String.fromEnvironment('QA_EMAIL_B'),
        password: const String.fromEnvironment('QA_PASSWORD_B'),
      );
      await repo.client.functions.invoke(
        'delete-account',
        body: {'confirm_user_id': ownId},
      );
      await app.studio.clear(ownId);
      await repo.client.auth.signOut();
      results['temporary_actors_cleaned'] = 'passed';
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 18)),
  );
}
