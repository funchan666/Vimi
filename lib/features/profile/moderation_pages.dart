import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../core/pagination.dart';
import '../../design/page_footer.dart';
import '../../design/vimi_ui.dart';
import '../studio/rehearsal_player.dart';

class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});
  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  CursorPager<Json>? pager;
  String section = 'Posts';
  bool childSafetyOnly = false;
  String? owner;
  int revision = -1;
  void select(String value) {
    final app = VimiScope.of(context);
    pager?.dispose();
    owner = app.account;
    final currentOwner = owner;
    final target = value.toLowerCase();
    final urgentOnly = value == 'Reports' && childSafetyOnly;
    setState(() {
      section = value;
      pager = CursorPager(
        fetch: (cursor) => app.repo!.reviewPage(
          target,
          cursor: cursor,
          childSafetyOnly: urgentOnly,
        ),
        identity: (row) => row['id'] as String,
        ascending: true,
        isCurrent: () => app.isModerator && app.account == currentOwner,
      );
    });
    unawaited(pager!.refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (app.isModerator && (pager == null || owner != app.account)) {
      revision = app.revision;
      select(section);
    } else if (app.isModerator && revision != app.revision) {
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
  Widget build(BuildContext context) {
    if (!VimiScope.of(context).isModerator)
      return const VPage(
        title: 'Content review',
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyNote(
            'Reviewer access required.',
            'This page is available to an assigned content reviewer.',
          ),
        ),
      );
    return VPage(
      title: 'Content review',
      actions: [
        VIconButton(
          Glyph.refresh,
          label: 'Refresh review queue',
          onPressed: reload,
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Review the actual content before deciding. Decisions are recorded; nothing is approved automatically.',
          ),
          const SizedBox(height: 24),
          ChoiceStrip(
            options: const ['Posts', 'Comments', 'Reports'],
            value: section,
            onChanged: select,
          ),
          if (section == 'Reports') ...[
            const SizedBox(height: 16),
            ChoiceStrip(
              options: const ['All reports', 'Child safety'],
              value: childSafetyOnly ? 'Child safety' : 'All reports',
              onChanged: (value) {
                childSafetyOnly = value == 'Child safety';
                select('Reports');
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Check child safety concerns promptly. Remove confirmed violations and follow the child safety response procedure.',
            ),
          ],
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: pager!,
            builder: (context, _) {
              final items = pager!.items;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (pager!.loaded && items.isEmpty && pager!.error == null)
                    const EmptyNote(
                      'Queue is clear.',
                      'New items awaiting review will appear here.',
                    ),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SurfacePanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (item['caption'] ??
                                      item['body'] ??
                                      '${item['target_type']} · ${item['reason']}')
                                  as String,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              displayDate(
                                DateTime.parse(item['created_at'] as String),
                              ),
                              style: const TextStyle(color: VimiColors.muted),
                            ),
                            const SizedBox(height: 12),
                            VButton(
                              'Review item',
                              onPressed: () => openPage(
                                context,
                                ReviewItemPage(
                                  kind: section == 'Posts'
                                      ? 'post'
                                      : section == 'Comments'
                                      ? 'comment'
                                      : 'report',
                                  item: item,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  PageFooter(
                    pager: pager!,
                    moreLabel: 'More review items',
                    loadingLabel: 'Opening the review queue…',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ReviewItemPage extends StatefulWidget {
  const ReviewItemPage({super.key, required this.kind, required this.item});
  final String kind;
  final Json item;
  @override
  State<ReviewItemPage> createState() => _ReviewItemPageState();
}

class _ReviewItemPageState extends State<ReviewItemPage> {
  bool busy = false;
  bool mediaReady = false;
  String? error;
  void markMediaReady() {
    if (!mediaReady && mounted) setState(() => mediaReady = true);
  }

  Future<void> decide(String status, {String? kind, String? id}) async {
    if (busy) return;
    final targetKind = kind ?? widget.kind;
    final action = status == 'removed'
        ? targetKind == 'user'
              ? 'Clear profile'
              : 'Remove content permanently'
        : status == 'approved'
        ? 'Approve'
        : status == 'rejected'
        ? 'Reject'
        : status == 'suspended'
        ? 'Suspend account'
        : status == 'active'
        ? 'Restore account'
        : 'Complete review';
    if (!await confirmAction(
          context,
          title: '$action?',
          body: status == 'removed'
              ? targetKind == 'user'
                    ? 'The display name, bio and avatar will be cleared. Use Suspend reported account to restrict access as well.'
                    : 'This content and its attached media will be deleted. This cannot be undone.'
              : targetKind == 'user'
              ? 'This changes the dancer’s access to the community.'
              : 'Your decision will be saved to the moderation record.',
          action: action,
        ) ||
        !mounted)
      return;
    setState(() {
      busy = true;
      error = null;
    });
    final app = VimiScope.of(context);
    try {
      await app.repo!.client.functions.invoke(
        'moderate-content',
        body: {
          'kind': targetKind,
          'id': id ?? widget.item['id'],
          'status': status,
        },
      );
      app.changed();
      if (mounted) {
        Navigator.pop(context);
        feedback(context, 'Review decision saved.');
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final target = widget.kind == 'report' ? item['target'] as Map? : item;
    final mediaUrl = target?['review_url'] as String?;
    final author = widget.kind == 'report'
        ? (target?['review_author_id'] as String?)
        : null;
    return VPage(
      title: 'Review ${widget.kind}',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.kind == 'report') ...[
            Text(
              '${item['target_type']} · ${item['reason']}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
          ],
          if (target == null)
            const ErrorNote(
              'This item is no longer available. You can still complete the report review.',
            ),
          if (target?['display_name'] != null)
            Text(
              target!['display_name'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          if (target?['caption'] != null ||
              target?['body'] != null ||
              target?['bio'] != null)
            SurfacePanel(
              illuminated: true,
              child: Text(
                (target?['caption'] ?? target?['body'] ?? target?['bio'])
                    as String,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          const SizedBox(height: 20),
          if (mediaUrl != null)
            target?['media_kind'] == 'video'
                ? RehearsalPlayer(
                    source: mediaUrl,
                    network: true,
                    onReady: markMediaReady,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Image.network(
                        mediaUrl,
                        fit: BoxFit.contain,
                        frameBuilder: (context, child, frame, synchronous) {
                          if (frame != null || synchronous) {
                            if (!mediaReady)
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => markMediaReady(),
                              );
                            return child;
                          }
                          return const Center(
                            child: Text('Opening review media…'),
                          );
                        },
                        errorBuilder: (_, __, ___) => const ErrorNote(
                          'Review media could not be opened. Retry from the queue.',
                        ),
                      ),
                    ),
                  )
          else if (widget.kind == 'post' || target?['media_path'] != null)
            const ErrorNote(
              'This media is unavailable. Return to the queue to retry, or reject it if it cannot be reviewed.',
            ),
          const SizedBox(height: 24),
          if (error != null) ErrorNote(error!),
          if (widget.kind != 'report') ...[
            VButton(
              'Approve content',
              glyph: Glyph.check,
              busy: busy,
              onPressed:
                  widget.kind == 'post' && (mediaUrl == null || !mediaReady)
                  ? null
                  : () => decide('approved'),
            ),
            const SizedBox(height: 12),
            VButton(
              'Reject content',
              glyph: Glyph.close,
              tonal: true,
              onPressed: busy ? null : () => decide('rejected'),
            ),
            const SizedBox(height: 12),
            VButton(
              'Remove content permanently',
              glyph: Glyph.delete,
              quiet: true,
              onPressed: busy ? null : () => decide('removed'),
            ),
          ] else ...[
            if (target != null) ...[
              VButton(
                item['target_type'] == 'user'
                    ? 'Clear reported profile'
                    : 'Remove reported content permanently',
                glyph: Glyph.delete,
                quiet: true,
                onPressed: busy
                    ? null
                    : () => decide(
                        'removed',
                        kind: item['target_type'] as String,
                        id: item['target_id'] as String,
                      ),
              ),
              const SizedBox(height: 12),
              const Text('After taking action, complete the report review.'),
              const SizedBox(height: 12),
            ],
            VButton(
              'Complete report review',
              busy: busy,
              onPressed: () => decide('resolved'),
            ),
            if (author != null) ...[
              const SizedBox(height: 12),
              VButton(
                'Suspend reported account',
                quiet: true,
                onPressed: busy
                    ? null
                    : () => decide('suspended', kind: 'user', id: author),
              ),
              VButton(
                'Restore reported account',
                quiet: true,
                onPressed: busy
                    ? null
                    : () => decide('active', kind: 'user', id: author),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
