import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/models.dart';
import '../../core/pagination.dart';
import '../../design/page_footer.dart';
import '../../design/vimi_ui.dart';
import '../community/community_pages.dart';
import '../community/publish_page.dart';

/// The signed-in dancer's own work, including posts awaiting review.
class PersonalActivity extends StatefulWidget {
  const PersonalActivity({super.key});

  @override
  State<PersonalActivity> createState() => _PersonalActivityState();
}

class _PersonalActivityState extends State<PersonalActivity> {
  CursorPager<DancePost>? archive;
  String? owner;
  int revision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    final repo = app.repo;
    final account = app.signedIn && repo != null ? app.account : null;
    if (account != owner) {
      archive?.dispose();
      owner = account;
      revision = -1;
      archive = account == null || repo == null
          ? null
          : CursorPager(
              fetch: (cursor) => repo.feedPage(author: account, cursor: cursor),
              identity: (post) => post.id,
              isCurrent: () => app.signedIn && app.account == account,
            );
    }
    final current = archive;
    if (current != null && revision != app.revision) {
      revision = app.revision;
      unawaited(current.refresh());
    }
  }

  @override
  void dispose() {
    archive?.dispose();
    super.dispose();
  }

  void _publish() => openPage(context, const PublishPage());

  @override
  Widget build(BuildContext context) {
    final current = archive;
    if (current == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: current,
      builder: (context, _) {
        final posts = current.items
            .where((post) => post.author.id == owner)
            .toList();
        final empty = current.loaded && current.error == null && posts.isEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'My covers',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                if (!empty)
                  VIconButton(
                    Glyph.add,
                    label: 'Post a cover',
                    color: VimiColors.accent,
                    onPressed: _publish,
                  ),
              ],
            ),
            if (empty) ...[
              const SizedBox(height: 10),
              SurfacePanel(
                padding: const EdgeInsets.all(4),
                illuminated: true,
                child: VActionRow(
                  'Post a cover',
                  glyph: Glyph.video,
                  detail: 'Add a dance photo or video.',
                  onPressed: _publish,
                ),
              ),
            ] else if (posts.isNotEmpty)
              _CoverRail(key: ValueKey(owner), posts: posts),
            PageFooter(
              pager: current,
              moreLabel: 'Earlier covers',
              loadingLabel: 'Opening your covers…',
            ),
          ],
        );
      },
    );
  }
}

class _CoverRail extends StatelessWidget {
  const _CoverRail({super.key, required this.posts});
  final List<DancePost> posts;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth * .46).clamp(128.0, 198.0).toDouble();
      final mediaHeight = width * .70;
      final scaler = MediaQuery.textScalerOf(context);
      final captionHeight =
          scaler.scale(14) * 1.3 + scaler.scale(12) * 1.3 + 22;
      return SizedBox(
        height: mediaHeight + captionHeight,
        child: ListView.separated(
          primary: false,
          scrollDirection: Axis.horizontal,
          itemCount: posts.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final post = posts[index];
            return SizedBox(
              width: width,
              child: _OwnCoverTile(
                key: ValueKey((post.id, post.mediaPath)),
                post: post,
                mediaHeight: mediaHeight,
              ),
            );
          },
        ),
      );
    },
  );
}

class _OwnCoverTile extends StatelessWidget {
  const _OwnCoverTile({
    super.key,
    required this.post,
    required this.mediaHeight,
  });
  final DancePost post;
  final double mediaHeight;

  @override
  Widget build(BuildContext context) {
    final (status, color) = switch (post.status) {
      'approved' => ('Published', VimiColors.cyan),
      'pending' => ('In review', VimiColors.violet),
      _ => ('Not approved', VimiColors.danger),
    };
    final clip = post.kind == 'video';
    final title = post.caption.isNotEmpty
        ? post.caption
        : '${post.style} cover';
    return Material(
      color: VimiColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: () => openPage(context, PostDetailPage(post: post)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: mediaHeight,
                    child: clip
                        ? const ColoredBox(
                            color: VimiColors.tonal,
                            child: Center(
                              child: VIcon(
                                Glyph.play,
                                color: VimiColors.cyan,
                                size: 26,
                              ),
                            ),
                          )
                        : _OwnPhotoPreview(path: post.mediaPath),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: 6,
            end: 6,
            child: VIconButton(
              Glyph.more,
              label: 'Cover options',
              filled: true,
              onPressed: () => postOptions(context, post),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnPhotoPreview extends StatefulWidget {
  const _OwnPhotoPreview({required this.path});
  final String path;

  @override
  State<_OwnPhotoPreview> createState() => _OwnPhotoPreviewState();
}

class _OwnPhotoPreviewState extends State<_OwnPhotoPreview> {
  late Future<String>? url;
  String? owner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (owner == app.account) return;
    owner = app.account;
    url = app.signedIn ? app.repo?.mediaUrl(widget.path) : null;
  }

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: VimiColors.tonal,
      child: Center(child: VIcon(Glyph.photo, color: VimiColors.violet)),
    );
    return FutureBuilder<String>(
      key: ValueKey(owner),
      future: url,
      builder: (context, snapshot) {
        final source = snapshot.data;
        if (source == null) return placeholder;
        return Image.network(
          source,
          fit: BoxFit.cover,
          cacheWidth: 400,
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, _) =>
              frame == null ? placeholder : child,
          errorBuilder: (context, error, stack) => placeholder,
        );
      },
    );
  }
}
