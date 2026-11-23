import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_controller.dart';
import '../../core/models.dart';
import '../../core/pagination.dart';
import '../../design/page_footer.dart';
import '../../design/vimi_ui.dart';
import '../auth/auth_pages.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key, this.libraryItem});
  final String? libraryItem;
  @override
  Widget build(BuildContext context) {
    const support = String.fromEnvironment('SUPPORT_URL');
    const email = String.fromEnvironment('SUPPORT_EMAIL');
    return VPage(
      title: '',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SurfacePanel(
            illuminated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help & safety',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Get help with your covers, conversations or account.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (libraryItem != null) ...[
            Text(
              'Library item: $libraryItem',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Use Contact support to report a concern about this item. Include a short description; do not attach suspected illegal imagery.',
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Common questions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final answer in const [
            (
              'Where is my post or comment?',
              'New posts, comments and edits enter review. Your own posts and their review states are in Me. Approved work appears in the community; rejected work stays visible to you so you can edit or remove it.',
            ),
            (
              'How do messages work?',
              'You can open a dancer’s conversation and write a draft. Sending messages and starting voice or video calls require mutual follows. Blocking removes both follows and hides your conversations from each other.',
            ),
            (
              'What happens to a report?',
              'The reported item is hidden for you and sent for review. Your reports shows whether each review is still open or completed. Blocking is a separate action.',
            ),
            (
              'Where is my private practice?',
              'Practice notes, drafts and personal rehearsal videos stay on this device in the account where you made them. They are not posted or synced to another device automatically.',
            ),
            (
              'How do practice plans work?',
              'Open a plan from Studio, check off drills as you go and start a practice note from the plan. Your checklist and notes stay on this device.',
            ),
            (
              'Can I use a commercial song?',
              'Only share media and audio you have permission to use, including permission from people shown. The included clip library is for viewing and private rehearsal; it does not grant permission to republish someone else’s performance or music.',
            ),
          ])
            _HelpTopic(question: answer.$1, answer: answer.$2),
          const SizedBox(height: 20),
          VActionRow(
            'Child safety standards',
            glyph: Glyph.report,
            onPressed: () => openPage(
              context,
              const LegalPage('Child safety standards', 'child-safety'),
            ),
          ),
          VActionRow(
            'Account deletion & data',
            glyph: Glyph.delete,
            onPressed: () => openPage(
              context,
              const LegalPage('Account deletion & data', 'deletion'),
            ),
          ),
          if (VimiScope.of(context).signedIn)
            VActionRow(
              'Your reports',
              glyph: Glyph.report,
              onPressed: () => openPage(context, const MyReportsPage()),
            ),
          VActionRow(
            'Community guidelines',
            glyph: Glyph.person,
            onPressed: () => openPage(
              context,
              const LegalPage('Community guidelines', 'community'),
            ),
          ),
          if (support.isNotEmpty || email.isNotEmpty)
            VActionRow(
              'Contact support',
              glyph: Glyph.inbox,
              onPressed: () async {
                final uri = support.isNotEmpty
                    ? Uri.tryParse(support)
                    : Uri(
                        scheme: 'mailto',
                        path: email,
                        queryParameters: {
                          'subject': libraryItem == null
                              ? 'Vimi support'
                              : 'Vimi library content concern',
                          if (libraryItem != null)
                            'body': 'Library item: $libraryItem\n\nConcern:\n',
                        },
                      );
                if (uri == null || !['https', 'mailto'].contains(uri.scheme)) {
                  if (context.mounted)
                    feedback(context, 'Support is currently unavailable.');
                  return;
                }
                try {
                  if (!await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      ) &&
                      context.mounted) {
                    feedback(
                      context,
                      'Support could not be opened. Please try again.',
                    );
                  }
                } catch (_) {
                  if (context.mounted)
                    feedback(
                      context,
                      'Support could not be opened. Please try again.',
                    );
                }
              },
            )
          else
            const Text(
              'Direct support contact is not available yet. Community reports can be submitted from any post, comment, message or dancer profile.',
              style: TextStyle(color: VimiColors.muted),
            ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 12),
            const SelectableText(email),
            VActionRow(
              'Copy support email',
              glyph: Glyph.share,
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: email));
                if (context.mounted) feedback(context, 'Support email copied.');
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _HelpTopic extends StatefulWidget {
  const _HelpTopic({required this.question, required this.answer});

  final String question, answer;

  @override
  State<_HelpTopic> createState() => _HelpTopicState();
}

class _HelpTopicState extends State<_HelpTopic> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        expanded: _expanded,
        child: TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          style: TextButton.styleFrom(
            foregroundColor: VimiColors.ink,
            minimumSize: const Size(48, 50),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
          child: Row(
            children: [
              Expanded(child: Text(widget.question)),
              const SizedBox(width: 10),
              VIcon(
                _expanded ? Glyph.close : Glyph.add,
                size: 18,
                color: VimiColors.cyan,
              ),
            ],
          ),
        ),
      ),
      if (_expanded)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 14, 14),
          child: Text(
            widget.answer,
            style: const TextStyle(color: VimiColors.muted, height: 1.5),
          ),
        ),
      const Divider(height: 1, color: VimiColors.tonal),
    ],
  );
}

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});
  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  CursorPager<Json>? pager;
  String? owner;
  int revision = -1;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (app.signedIn && (pager == null || owner != app.account)) {
      pager?.dispose();
      owner = app.account;
      final currentOwner = owner;
      pager = CursorPager(
        fetch: (cursor) => app.repo!.reportPage(cursor: cursor),
        identity: (row) => row['id'] as String,
        isCurrent: () => app.signedIn && app.account == currentOwner,
      );
    }
    if (pager != null && revision != app.revision) {
      revision = app.revision;
      unawaited(pager!.refresh());
    }
  }

  void reload() => unawaited(pager!.refresh());
  @override
  void dispose() {
    pager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: 'Your reports',
    actions: [
      VIconButton(Glyph.refresh, label: 'Refresh reports', onPressed: reload),
    ],
    child: AnimatedBuilder(
      animation: pager!,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Your reports are private. Reported items stay hidden for you after a review is completed.',
          ),
          const SizedBox(height: 24),
          if (pager!.loaded && pager!.items.isEmpty && pager!.error == null)
            const EmptyNote(
              'Nothing to review.',
              'Reports you submit from the community appear here.',
            ),
          for (final report in pager!.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SurfacePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report['target_type']} · ${report['reason']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report['status'] == 'resolved'
                          ? 'Review completed'
                          : 'Submitted · awaiting review',
                      style: const TextStyle(color: VimiColors.cyan),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayDate(
                        DateTime.parse(report['created_at'] as String),
                      ),
                      style: const TextStyle(color: VimiColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          PageFooter(
            pager: pager!,
            moreLabel: 'Earlier reports',
            loadingLabel: 'Opening your reports…',
          ),
        ],
      ),
    ),
  );
}
