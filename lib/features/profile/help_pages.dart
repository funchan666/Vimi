import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../design/vimi_ui.dart';
import '../auth/auth_pages.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});
  @override
  Widget build(BuildContext context) {
    const support = String.fromEnvironment('SUPPORT_URL');
    const email = String.fromEnvironment('SUPPORT_EMAIL');
    return VPage(
      title: 'Help & safety',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SurfacePanel(
            illuminated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep the floor kind.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Share your own work, respect other dancers and choose what you make public.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          for (final answer in const [
            (
              'Where is my post or comment?',
              'New posts, comments and edits enter review. Your own posts and their review states are in Me. Approved work appears in the community; rejected work stays visible to you so you can edit or remove it.',
            ),
            (
              'How do messages work?',
              'Follow each other to send a message. Messages and follows are free. Blocking removes both follows and hides your conversations from each other.',
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
              'What do coins unlock?',
              'Coins unlock the listed practice-planning packs. The everyday journal and social features remain free. Prices are supplied by Google Play when purchases are configured and available.',
            ),
            (
              'Can I use a commercial song?',
              'Only share media and audio you have permission to use, including permission from people shown. Vimi does not supply or license K-pop songs or choreography videos.',
            ),
          ]) ...[
            Text(answer.$1, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(answer.$2),
            const SizedBox(height: 24),
          ],
          if (VimiScope.of(context).signedIn)
            VButton(
              'Your reports',
              glyph: Glyph.report,
              onPressed: () => openPage(context, const MyReportsPage()),
            ),
          VButton(
            'Community guidelines',
            quiet: true,
            onPressed: () => openPage(
              context,
              const LegalPage('Community guidelines', 'community'),
            ),
          ),
          if (support.isNotEmpty || email.isNotEmpty)
            VButton(
              'Contact support',
              quiet: true,
              onPressed: () async {
                final uri = support.isNotEmpty
                    ? Uri.tryParse(support)
                    : Uri(
                        scheme: 'mailto',
                        path: email,
                        queryParameters: {'subject': 'Vimi support'},
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
            VButton(
              'Copy support email',
              quiet: true,
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

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});
  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  Future<List<Json>>? future;
  int revision = -1;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (app.signedIn && revision != app.revision) {
      revision = app.revision;
      future = app.repo!.reports();
    }
  }

  void reload() =>
      setState(() => future = VimiScope.of(context).repo!.reports());
  @override
  Widget build(BuildContext context) => VPage(
    title: 'Your reports',
    actions: [
      VIconButton(Glyph.refresh, label: 'Refresh reports', onPressed: reload),
    ],
    child: FutureBuilder<List<Json>>(
      future: future,
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Your reports are private. Reported items stay hidden for you after a review is completed.',
          ),
          const SizedBox(height: 24),
          if (snapshot.hasError)
            ErrorNote(readableError(snapshot.error!), onRetry: reload)
          else if (snapshot.connectionState != ConnectionState.done)
            const Text('Opening your reports…')
          else if (snapshot.data!.isEmpty)
            const EmptyNote(
              'Nothing to review.',
              'Reports you submit from the community appear here.',
            )
          else
            for (final report in snapshot.data!)
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
        ],
      ),
    ),
  );
}
