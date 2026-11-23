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
  int modeVersion = 0;
  int? scanningMode;
  bool following = false;
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

  void rebuildEntries({bool restart = false}) {
    if (!mounted) return;
    final current = restart ? null : entries.elementAtOrNull(page)?.id;
    final atEnd = !restart && entries.isNotEmpty && page == entries.length;
    final previousIds = atEnd ? entries.map((entry) => entry.id).toSet() : null;
    final feed = members;
    final posts = feed?.items ?? [];
    final waitingForMembers =
        feed != null && !feed.loaded && feed.error == null;
    final next = [
      for (final post in posts)
        if (!following || post.author.isFollowing) _CoverEntry.member(post),
      if (!following && !waitingForMembers)
        for (final clip in clips) _CoverEntry.library(clip),
    ];
    final index = next.indexWhere((entry) => entry.id == current);
    final newMember = previousIds == null
        ? -1
        : next.indexWhere(
            (entry) => entry.post != null && !previousIds.contains(entry.id),
          );
    final selected = restart
        ? 0
        : index >= 0
        ? index
        : newMember >= 0
        ? newMember
        : atEnd && canLoadMore
        ? next.length
        : page.clamp(0, next.isEmpty ? 0 : next.length - 1).toInt();
    final move = !restart && selected != page && pages.hasClients;
    setState(() {
      entries = next;
      page = selected;
      if (restart) changingPages = false;
      if (move) changingPages = true;
    });
    if (move) {
      final mode = modeVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || mode != modeVersion) return;
        if (pages.hasClients) pages.jumpToPage(page);
        setState(() => changingPages = false);
      });
    }
  }

  void selectFeed(bool value) {
    if (following == value) return;
    following = value;
    modeVersion++;
    rebuildEntries(restart: true);
    if (following) unawaited(findFollowingVideos());
  }

  Future<void> findFollowingVideos() async {
    final feed = members;
    final mode = modeVersion;
    if (!following ||
        feed == null ||
        scanningMode == mode ||
        VimiScope.of(context).profile?.following == 0 ||
        entries.isNotEmpty) {
      return;
    }
    scanningMode = mode;
    try {
      // Look beyond photo-heavy batches without draining a long feed at once.
      for (
        var attempt = 0;
        attempt < 3 &&
            mounted &&
            widget.active &&
            mode == modeVersion &&
            identical(feed, members) &&
            entries.isEmpty &&
            feed.hasMore &&
            feed.error == null;
        attempt++
      ) {
        await feed.loadMore();
      }
    } finally {
      if (scanningMode == mode) scanningMode = null;
    }
  }

  void discoverDancers() => openPage(context, const DancerDirectory());

  Widget followingEmpty(CursorPager<DancePost>? feed, bool hasNoFollows) {
    final looking = !hasNoFollows && feed?.loading == true;
    final error = hasNoFollows ? null : feed?.error;
    final canContinue = feed != null && feed.hasMore && !hasNoFollows;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SurfacePanel(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VIcon(Glyph.person, size: 30, color: VimiColors.cyan),
              const SizedBox(height: 10),
              Text(
                hasNoFollows
                    ? 'No followed covers yet'
                    : looking
                    ? 'Looking for followed dancers’ videos…'
                    : error != null
                    ? 'Couldn’t load followed covers'
                    : canContinue
                    ? 'No followed covers in these results'
                    : 'No videos from followed dancers yet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (hasNoFollows)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Follow dancers to see their videos here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: VimiColors.muted, fontSize: 13),
                  ),
                ),
              if (looking)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (error != null)
                VActionRow(
                  'Retry covers',
                  glyph: Glyph.refresh,
                  onPressed: feed!.retry,
                )
              else if (canContinue)
                VActionRow(
                  'Check earlier videos',
                  glyph: Glyph.video,
                  onPressed: findFollowingVideos,
                )
              else if (!hasNoFollows && feed != null)
                VActionRow(
                  'Refresh covers',
                  glyph: Glyph.refresh,
                  onPressed: () async {
                    final mode = modeVersion;
                    await feed.refresh();
                    if (mounted && mode == modeVersion) {
                      await findFollowingVideos();
                    }
                  },
                )
              else
                VActionRow(
                  'Discover dancers',
                  glyph: Glyph.search,
                  onPressed: discoverDancers,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget feedMode(String label, bool value) {
    final selected = following == value;
    return Semantics(
      selected: selected,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: selected ? VimiColors.cyan : VimiColors.muted,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        onPressed: () => selectFeed(value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(height: 4),
            SizedBox(
              width: 14,
              height: 2,
              child: ColoredBox(
                color: selected ? VimiColors.cyan : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
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
    final mode = modeVersion;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 490),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    children: [
                      feedMode('All covers', false),
                      feedMode('Following', true),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                        onPressed: discoverDancers,
                      ),
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
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: slides.isEmpty && following
                    ? followingEmpty(feed, app.profile?.following == 0)
                    : slides.isEmpty && !hasMore
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
                        key: ValueKey(following),
                        controller: pages,
                        scrollDirection: Axis.vertical,
                        allowImplicitScrolling: true,
                        onPageChanged: (index) {
                          if (changingPages || mode != modeVersion) return;
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
          child: Tooltip(
            message: 'Open Studio library',
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: VimiColors.ink,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              ),
              onPressed: () => openPage(
                context,
                MediaLibraryPage(
                  practiceBuilder: (value) =>
                      PracticeEditor(initialClip: value),
                ),
              ),
              child: Row(
                children: [
                  const VIcon(
                    Glyph.library,
                    size: 22,
                    color: VimiColors.violet,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _CoverCredit(
                      title: clip.title,
                      detail: 'Studio library · ${clip.durationLabel}',
                    ),
                  ),
                ],
              ),
            ),
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
    final hasCaption = post.caption.trim().isNotEmpty;
    return LayoutBuilder(
      builder: (context, bounds) {
        final combineCaptionAndActions =
            bounds.maxWidth >= 340 &&
            MediaQuery.textScalerOf(context).scale(13) <= 18;
        final caption = hasCaption
            ? Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: Text(
                  post.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              )
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CoverAuthor(author: post.author, style: post.style),
            if (combineCaptionAndActions)
              Row(
                children: [
                  Expanded(child: caption ?? const SizedBox.shrink()),
                  ...actions,
                ],
              )
            else ...[
              if (caption != null) caption,
              Wrap(alignment: WrapAlignment.end, children: actions),
            ],
          ],
        );
      },
    );
  }
}

class _CoverAuthor extends StatelessWidget {
  const _CoverAuthor({required this.author, required this.style});

  final Dancer author;
  final String style;

  @override
  Widget build(BuildContext context) {
    final label = 'Open ${author.name}’s profile';
    void openProfile() => openPage(context, DancerPage(id: author.id));

    return Semantics(
      button: true,
      label: label,
      focusable: true,
      onTap: openProfile,
      excludeSemantics: true,
      child: Tooltip(
        excludeFromSemantics: true,
        message: label,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: VimiColors.ink,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.fromLTRB(2, 5, 12, 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: openProfile,
          child: Row(
            children: [
              SignedAvatar(author, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: _CoverCredit(title: author.name, detail: style),
              ),
              const SizedBox(width: 8),
              const VIcon(Glyph.next, size: 16, color: VimiColors.cyan),
            ],
          ),
        ),
      ),
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
