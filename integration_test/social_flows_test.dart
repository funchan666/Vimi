import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vimi/main.dart' as vimi;
import 'package:vimi/core/dance_repository.dart';
import 'package:vimi/core/app_controller.dart';
import 'package:vimi/features/auth/auth_pages.dart';
import 'package:vimi/features/auth/account_security_pages.dart';
import 'package:vimi/features/community/community_pages.dart';
import 'package:vimi/features/community/publish_page.dart';
import 'package:vimi/features/community/content_editor.dart';
import 'package:vimi/features/profile/profile_pages.dart';
import 'package:vimi/features/profile/help_pages.dart';
import 'package:vimi/features/profile/moderation_pages.dart';
import 'package:vimi/features/studio/studio_pages.dart';
import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real Android publishing, social, review, journal and deletion',
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
      await press(tester, 'Discover');
      await press(tester, 'Challenges');
      final first = find.byTooltip('Open challenge').first;
      await tester.ensureVisible(first);
      await tester.tap(first);
      await tester.pump(const Duration(milliseconds: 600));
      await press(tester, 'Share your take');
      await waitFor(
        tester,
        () => find.byType(PublishPage).evaluate().isNotEmpty,
        reason: 'The selected challenge did not open the publisher.',
      );
      final app = appController(tester), repo = appController(tester).repo!;
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
      final peerId = const String.fromEnvironment('QA_USER_A');
      final ownId = repo.account;
      results['signed_in_challenge_publisher'] = 'passed';
      await capture(binding, tester, 'native-publish-challenge');
      // This is the genuine Android photo picker, with a single labelled QA image
      // imported by the host. No app picker or upload API is mocked.
      // ignore: avoid_print
      print('VIMI_QA_PICK_PHOTO');
      await press(tester, 'Photo library');
      await waitFor(
        tester,
        () => find
            .byWidgetPredicate((w) => w is Image && w.image is FileImage)
            .evaluate()
            .isNotEmpty,
        timeout: const Duration(minutes: 3),
        reason: 'Native photo selection did not return.',
      );
      final caption =
          'Vimi QA native cover ${const String.fromEnvironment('QA_RUN')}';
      await enter(tester, 'What did you work on?', caption);
      final rights = find.byTooltip('Confirm media and music rights');
      await reveal(tester, rights);
      await tester.tap(rights);
      await press(tester, 'Submit for review');
      await waitFor(
        tester,
        () => find.byType(PublishPage).evaluate().isEmpty,
        reason: 'The real media upload or post submission failed.',
      );
      final pending = (await repo.feed(
        author: ownId,
      )).singleWhere((p) => p.caption == caption);
      expect(pending.status, 'pending');
      expect(await peer.post(pending.id), isNull);
      final ownUrl = await repo.mediaUrl(pending.mediaPath);
      final http = HttpClient();
      final response = await (await http.getUrl(Uri.parse(ownUrl))).close();
      expect(response.statusCode, 200);
      expect(
        (await response.fold<int>(0, (n, bytes) => n + bytes.length)),
        greaterThan(1000),
      );
      http.close();
      results['native_picker_storage_publish_pending'] = 'passed';
      await repo.follow(peerId, followed: true);
      await peer.follow(ownId, followed: true);
      await app.refreshAccount();
      await tester.pump(const Duration(seconds: 1));
      await openTestPage(tester, DancerPage(id: peerId));
      await waitFor(tester, () => action('Message').evaluate().isNotEmpty);
      await press(tester, 'Message');
      await waitFor(
        tester,
        () => find.byTooltip('Send message').evaluate().isNotEmpty,
      );
      await enter(
        tester,
        'Your message',
        'QA message sent from the Android screen',
      );
      await tester.tap(find.byTooltip('Send message'));
      await waitFor(
        tester,
        () => tester
            .widget<TextField>(input('Your message'))
            .controller!
            .text
            .isEmpty,
      );
      expect(
        (await peer.thread(ownId)).single['body'],
        'QA message sent from the Android screen',
      );
      await peer.markRead(ownId);
      await waitFor(
        tester,
        () => find.text(' · Read').evaluate().isNotEmpty,
        reason: 'The sender did not receive the real read receipt.',
      );
      await peer.send(
        ownId,
        'QA reply from the second authenticated dancer',
        const Uuid().v4(),
      );
      await waitFor(
        tester,
        () => find
            .text('QA reply from the second authenticated dancer')
            .evaluate()
            .isNotEmpty,
        reason: 'A real incoming message did not arrive through Realtime.',
      );
      await capture(binding, tester, 'native-chat-realtime');
      results['mutual_follow_chat_realtime_read_receipt'] = 'passed';
      await goBack(tester);
      await goBack(tester);
      // Verify the ordinary account cannot invoke the reviewer API.
      await expectLater(
        repo.client.functions.invoke(
          'moderate-content',
          body: {'action': 'queue'},
        ),
        throwsA(isA<FunctionException>()),
      );
      await peerClient.functions.invoke(
        'moderate-content',
        body: {'kind': 'post', 'id': pending.id, 'status': 'approved'},
      );
      final approved = (await repo.post(pending.id))!;
      expect((await peer.post(pending.id))!.status, 'approved');
      await openTestPage(tester, PostDetailPage(post: approved));
      await waitFor(tester, () => find.byType(PostTile).evaluate().isNotEmpty);
      final save = find.byTooltip('Save post');
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pump(const Duration(seconds: 1));
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
      await openTestPage(tester, DancerPage(id: peerId));
      await waitFor(tester, () => action('Block dancer').evaluate().isNotEmpty);
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
