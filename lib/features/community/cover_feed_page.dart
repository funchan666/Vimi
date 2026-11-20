import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/media_library.dart';
import '../../core/models.dart';
import '../../core/pagination.dart';
import '../../design/library_image.dart';
import '../../design/vimi_ui.dart';
import '../auth/auth_pages.dart';
import '../profile/help_pages.dart';
import '../profile/profile_pages.dart';
import '../studio/media_library_pages.dart';
import '../studio/studio_pages.dart';
import 'community_pages.dart';
import 'cover_video_canvas.dart';
import 'publish_page.dart';

class CoverFeedPage extends StatefulWidget {
  const CoverFeedPage({super.key, required this.active});

  final bool active;

  @override
  State<CoverFeedPage> createState() => _CoverFeedPageState();
}

class _CoverFeedPageState extends State<CoverFeedPage> {
  final pages = PageController(keepPage: false);
  final saving = <String>{};
  CursorPager<DancePost>? members;
  List<LibraryClip> clips = [];
  List<_CoverEntry> entries = [];
  String? account;
  int revision = -1;
  int page = 0;
  bool muted = true;
  bool loadingClips = true;
  bool failedClips = false;
  bool changingPages = false;

  @override
  void initState() {
    super.initState();
    unawaited(loadClips());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (account != app.account) {
      members?.dispose();
      account = app.account;
      revision = -1;
      final repo = app.repo;
      final owner = account;
      members = app.signedIn && repo != null
          ? CursorPager(
              fetch: (cursor) =>
                  repo.feedPage(approvedVideosOnly: true, cursor: cursor),
              identity: (post) => post.id,
              isCurrent: () => app.signedIn && app.account == owner,
            )
          : null;
      members?.addListener(rebuildEntries);
    }
    if (revision != app.revision) {
      revision = app.revision;
      final feed = members;
      if (feed != null) unawaited(feed.refresh());
    }
  }

  Future<void> loadClips() async {
    try {
      final library = await MediaLibrary.load();
      if (!mounted) return;
      clips = [
        ...library.clips.where((clip) => clip.id == 'holiday-duet'),
        ...library.clips.where((clip) => clip.id != 'holiday-duet'),
      ];
      failedClips = false;
    } catch (_) {
      if (!mounted) return;
      failedClips = true;
    } finally {
      if (mounted) {
        loadingClips = false;
        rebuildEntries();
      }
    }
  }

  void rebuildEntries() {
    if (!mounted) return;
    final current = entries.elementAtOrNull(page)?.id;
    final atEnd = entries.isNotEmpty && page == entries.length;
    final previousIds = atEnd ? entries.map((entry) => entry.id).toSet() : null;
    final posts = members?.items ?? [];
    final next = [
      if (clips.isNotEmpty) _CoverEntry.library(clips.first),
      for (final post in posts) _CoverEntry.member(post),
      for (final clip in clips.skip(1)) _CoverEntry.library(clip),
    ];
    final index = next.indexWhere((entry) => entry.id == current);
    final newMember = previousIds == null
        ? -1
        : next.indexWhere(
            (entry) => entry.post != null && !previousIds.contains(entry.id),
          );
    final selected = index >= 0
        ? index
        : newMember >= 0
        ? newMember
        : atEnd && canLoadMore
        ? next.length
        : page.clamp(0, next.isEmpty ? 0 : next.length - 1).toInt();
    final move = selected != page && pages.hasClients;
    setState(() {
      entries = next;
      page = selected;
      if (move) changingPages = true;
    });
    if (move) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (pages.hasClients) pages.jumpToPage(page);
        setState(() => changingPages = false);
      });
    }
  }

  @override
  void dispose() {
    members?.dispose();
    pages.dispose();
    super.dispose();
  }

  Future<void> memberAction(DancePost post, String action) async {
    final app = VimiScope.of(context);
    final repo = app.repo;
    if (repo == null || !saving.add(post.id)) return;
    final owner = app.account;
    setState(() {});
    try {
      await repo.postAction(
        post.id,
        action,
        selected: action == 'like' ? !post.liked : !post.saved,
      );
      if (!mounted || app.account != owner) return;
      app.changed();
      revision = app.revision;
      final feed = members;
      if (feed != null) await feed.refresh();
    } catch (error) {
      if (mounted && app.account == owner) {
        feedback(context, readableError(error));
      }
    } finally {
      saving.remove(post.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> toggleSaved(LibraryClip clip) async {
    final app = VimiScope.of(context);
    final owner = app.account;
    if (!saving.add(clip.source)) return;
    setState(() {});
    try {
      await app.studio.toggleLibraryClip(owner, clip.id);
    } catch (error) {
      if (mounted && app.account == owner) {
        feedback(context, readableError(error));
      }
    } finally {
      saving.remove(clip.source);
      if (mounted) setState(() {});
    }
  }

  void openPractice(LibraryClip clip) => openPage(
    context,
    ClipLibraryDetail(
      clip: clip,
      practiceBuilder: (clip) => PracticeEditor(initialClip: clip),
    ),
  );

  void retry() {
    if (failedClips && !loadingClips) {
      setState(() => loadingClips = true);
      unawaited(loadClips());
    }
    final feed = members;
    if (feed?.error != null) unawaited(feed!.retry());
  }

  bool get canLoadMore {
    final feed = members;
    return feed != null && (feed.hasMore || feed.loading || feed.error != null);
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final here = ModalRoute.isCurrentOf(context) != false;
    final feed = members;
    final hasMore = canLoadMore;
    final slides = entries;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Row(
                children: [
                  VIconButton(
                    Glyph.library,
                    label: 'Discover',
                    onPressed: () => openPage(
                      context,
                      const VPage(title: 'Discover', child: FloorPage()),
                    ),
                  ),
                  VIconButton(
                    Glyph.search,
                    label: 'Find dancers',
                    onPressed: () => openPage(context, const DancerDirectory()),
                  ),
                  const Spacer(),
                  VIconButton(
                    muted ? Glyph.mute : Glyph.sound,
                    label: muted ? 'Turn on video sound' : 'Mute videos',
                    color: muted ? VimiColors.muted : VimiColors.cyan,
                    onPressed: () => setState(() => muted = !muted),
                  ),
                  VIconButton(
                    Glyph.add,
                    label: 'Post',
                    color: VimiColors.cyan,
                    filled: true,
                    onPressed: () async {
                      if (await requireSignIn(context) && context.mounted) {
                        await openPage(context, const PublishPage());
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: slides.isEmpty && !hasMore
                    ? Center(
                        child: loadingClips
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : failedClips
                            ? ErrorNote(
                                'Covers could not load.',
                                onRetry: retry,
                              )
                            : const Text('No video covers yet.'),
                      )
                    : PageView.builder(
                        controller: pages,
                        scrollDirection: Axis.vertical,
                        allowImplicitScrolling: true,
                        onPageChanged: (index) {
                          if (changingPages) return;
                          setState(() => page = index);
                          if (feed != null &&
                              feed.loaded &&
                              feed.hasMore &&
                              feed.error == null &&
                              index >= slides.length - 2 &&
                              !feed.loading) {
                            unawaited(feed.loadMore());
                          }
                        },
                        itemCount: slides.length + (hasMore ? 1 : 0),
                        findChildIndexCallback: (key) {
                          if (key is! ValueKey<String>) return null;
                          if (key.value == 'more-covers') {
                            return hasMore ? slides.length : null;
                          }
                          final index = slides.indexWhere(
                            (entry) => entry.id == key.value,
                          );
                          return index < 0 ? null : index;
                        },
                        itemBuilder: (context, index) {
                          if (index == slides.length) {
                            return _MoreCovers(
                              key: const ValueKey<String>('more-covers'),
                              feed: feed!,
                            );
                          }
                          final entry = slides[index];
                          return _CoverSlide(
                            key: ValueKey(entry.id),
                            entry: entry,
                            active:
                                widget.active &&
                                here &&
                                page == index &&
                                !changingPages,
                            muted: muted,
                            account: app,
                            saving: saving.contains(entry.id),
                            onMemberAction: memberAction,
                            onBookmark: toggleSaved,
                            onPractice: openPractice,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverEntry {
  const _CoverEntry.library(this.clip) : post = null;
  const _CoverEntry.member(this.post) : clip = null;
  final LibraryClip? clip;
  final DancePost? post;
  String get id => clip?.source ?? post!.id;
}

class _CoverSlide extends StatelessWidget {
  const _CoverSlide({
    super.key,
    required this.entry,
    required this.active,
    required this.muted,
    required this.account,
    required this.saving,
    required this.onMemberAction,
    required this.onBookmark,
    required this.onPractice,
  });

  final _CoverEntry entry;
  final bool active, muted, saving;
  final AppController account;
  final Future<void> Function(DancePost, String) onMemberAction;
  final Future<void> Function(LibraryClip) onBookmark;
  final ValueChanged<LibraryClip> onPractice;

  Future<String> resolveUrl(bool forceRefresh) async {
    if (entry.clip case final clip?) return clip.url;
    final repo = account.repo!;
    if (forceRefresh) repo.clearMediaCache();
    return repo.mediaUrl(entry.post!.mediaPath);
  }

  @override
  Widget build(BuildContext context) {
    final clip = entry.clip;
    final post = entry.post;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CoverVideoCanvas(
                sourceId: entry.id,
                resolveUrl: resolveUrl,
                active: active,
                muted: muted || clip?.hasAudio == false,
                poster: clip == null
                    ? const ColoredBox(
                        color: VimiColors.surface,
                        child: Center(child: VIcon(Glyph.video)),
                      )
                    : LibraryImage(
                        clip.thumbnail,
                        cacheWidth: 576,
                        compact: true,
                        label: clip.title,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SurfacePanel(
            padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
            child: clip != null
                ? _libraryCredit(context, clip)
                : _memberCredit(context, post!),
          ),
        ],
      ),
    );
  }

  Widget _libraryCredit(BuildContext context, LibraryClip clip) {
    final saved = account.studio
        .savedLibraryClips(account.account)
        .contains(clip.id);
    return Row(
      children: [
        Expanded(
          child: _CoverCredit(
            title: clip.title,
            detail: 'Practice reference · ${clip.durationLabel}',
          ),
        ),
        VIconButton(
          Glyph.save,
          label: saved ? 'Remove saved clip' : 'Save clip',
          color: saved ? VimiColors.cyan : VimiColors.ink,
          busy: saving,
          onPressed: () => onBookmark(clip),
        ),
        VIconButton(
          Glyph.studio,
          label: 'Open practice controls',
          color: VimiColors.violet,
          onPressed: () => onPractice(clip),
        ),
        VIconButton(
          Glyph.report,
          label: 'Report a concern',
          onPressed: () => openPage(
            context,
            HelpCenterPage(libraryItem: '${clip.id} · ${clip.title}'),
          ),
        ),
      ],
    );
  }

  Widget _memberCredit(BuildContext context, DancePost post) {
    final author = InkWell(
      onTap: () => openPage(context, DancerPage(id: post.author.id)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            SignedAvatar(post.author, size: 34),
            const SizedBox(width: 8),
            Expanded(
              child: _CoverCredit(title: post.author.name, detail: post.style),
            ),
          ],
        ),
      ),
    );
    final actions = [
      VIconButton(
        post.liked ? Glyph.heartFull : Glyph.heart,
        label: '${post.liked ? 'Remove like' : 'Like post'} · ${post.likes}',
        color: post.liked ? VimiColors.accent : VimiColors.ink,
        busy: saving,
        onPressed: () => onMemberAction(post, 'like'),
      ),
      VIconButton(
        Glyph.comment,
        label: 'Read comments · ${post.comments}',
        onPressed: () =>
            openPage(context, PostDetailPage(post: post, commentsOnly: true)),
      ),
      VIconButton(
        Glyph.save,
        label: post.saved ? 'Remove saved post' : 'Save post',
        color: post.saved ? VimiColors.cyan : VimiColors.ink,
        busy: saving,
        onPressed: () => onMemberAction(post, 'save'),
      ),
      VIconButton(
        Glyph.more,
        label: 'Post options',
        onPressed: () => postOptions(context, post),
      ),
    ];
    final caption = Text(
      post.caption,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13),
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxWidth < 320;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: author),
                if (!compact) ...actions,
              ],
            ),
            if (compact || post.caption.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 4),
                      child: caption,
                    ),
                  ),
                  if (compact) ...actions,
                ],
              ),
          ],
        );
      },
    );
  }
}

class _CoverCredit extends StatelessWidget {
  const _CoverCredit({required this.title, required this.detail});
  final String title, detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      Text(
        detail,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: VimiColors.muted),
      ),
    ],
  );
}

class _MoreCovers extends StatelessWidget {
  const _MoreCovers({super.key, required this.feed});
  final CursorPager<DancePost> feed;

  @override
  Widget build(BuildContext context) => Center(
    child: feed.loading || !feed.loaded && feed.error == null
        ? const CircularProgressIndicator(strokeWidth: 2)
        : feed.error != null
        ? ErrorNote('More covers could not load.', onRetry: feed.retry)
        : VIconButton(
            Glyph.more,
            label: 'Load more covers',
            onPressed: feed.loadMore,
          ),
  );
}
