import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../core/pagination.dart';
import '../../design/page_footer.dart';
import '../../core/local_studio.dart';
import '../../design/vimi_ui.dart';
import '../auth/auth_pages.dart';
import '../profile/profile_pages.dart';
import '../studio/rehearsal_player.dart';
import 'publish_page.dart';
import 'content_editor.dart';

class FloorPage extends StatefulWidget {
  const FloorPage({super.key});
  @override
  State<FloorPage> createState() => _FloorPageState();
}

class _FloorPageState extends State<FloorPage> {
  String style = 'All';
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'Find your rhythm.',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Share a cover. Find your dance people.',
          style: TextStyle(fontSize: 15, height: 1.5, color: VimiColors.muted),
        ),
        const SizedBox(height: 22),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              return Stack(
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: Image.asset(
                        'assets/ui/neon-floor.webp',
                        fit: BoxFit.cover,
                        alignment: const Alignment(.35, 0),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: compact ? 140 : 220,
                          child: Text(
                            'Your next\nchorus.',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontSize: compact ? 24 : 30,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        SizedBox(height: compact ? 20 : 36),
                        VButton(
                          'Challenges',
                          onPressed: () =>
                              openPage(context, const ChallengesPage()),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Meet the dancers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            VIconButton(
              Glyph.search,
              label: 'Find dancers',
              color: VimiColors.cyan,
              onPressed: () => openPage(context, const DancerDirectory()),
            ),
          ],
        ),
        if (app.signedIn)
          const CommunityDancers()
        else
          SurfacePanel(
            illuminated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your people are one cover away.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join the community to find dancers and start your own circle.',
                ),
                const SizedBox(height: 16),
                VButton(
                  'Meet your crew',
                  onPressed: () =>
                      openPage(context, const AuthPage(signUp: true)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'On the floor',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            VIconButton(
              Glyph.refresh,
              label: 'Refresh community',
              onPressed: app.changed,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ChoiceStrip(
          options: ['All', ...DanceStyle.values.map((s) => s.label)],
          value: style,
          onChanged: (v) => setState(() => style = v),
        ),
        const SizedBox(height: 18),
        if (!app.signedIn)
          EmptyNote(
            'Your next cover belongs here.',
            'Sign in to post, follow dancers and trade practice tips.',
            action: VButton(
              'Sign in',
              quiet: true,
              onPressed: () => openPage(context, const AuthPage(signUp: false)),
            ),
          )
        else
          PostCollection(
            key: ValueKey('floor-$style-${app.account}'),
            style: style == 'All' ? null : style,
          ),
      ],
    );
  }
}

class CommunityDancers extends StatefulWidget {
  const CommunityDancers({super.key});
  @override
  State<CommunityDancers> createState() => _CommunityDancersState();
}

class _CommunityDancersState extends State<CommunityDancers> {
  Future<List<Dancer>>? dancers;
  String? account;
  int revision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (app.signedIn && (account != app.account || revision != app.revision)) {
      account = app.account;
      revision = app.revision;
      dancers = app.repo!.searchDancers('');
    }
  }

  void reload() {
    final app = VimiScope.of(context);
    if (!app.signedIn) return;
    setState(() => dancers = app.repo!.searchDancers(''));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Dancer>>(
    future: dancers,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ErrorNote(readableError(snapshot.error!), onRetry: reload);
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Finding your dance people…',
            style: TextStyle(color: VimiColors.muted),
          ),
        );
      }
      final app = VimiScope.of(context);
      final people = (snapshot.data ?? [])
          .where((p) => p.id != app.account)
          .take(6)
          .toList();
      if (people.isEmpty) {
        return SurfacePanel(
          illuminated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start your dance circle.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share a cover and give other dancers a way to find you.',
              ),
              const SizedBox(height: 14),
              VButton(
                'Share your dance',
                glyph: Glyph.add,
                onPressed: () => openPage(context, const PublishPage()),
              ),
            ],
          ),
        );
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final dancer in people)
              SizedBox(
                width: 88,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => openPage(context, DancerPage(id: dancer.id)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SignedAvatar(dancer, size: 62),
                      const SizedBox(height: 8),
                      Text(
                        dancer.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: VimiColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class PostCollection extends StatefulWidget {
  const PostCollection({
    super.key,
    this.style,
    this.author,
    this.saved = false,
    this.challenge,
  });
  final String? style, author, challenge;
  final bool saved;
  @override
  State<PostCollection> createState() => _PostCollectionState();
}

class _PostCollectionState extends State<PostCollection> {
  CursorPager<DancePost>? pager;
  String? owner;
  int revision = -1;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (owner != app.account || pager == null) {
      pager?.dispose();
      owner = app.account;
      final currentOwner = owner;
      final repo = app.repo!;
      pager = CursorPager(
        fetch: (cursor) => repo.feedPage(
          style: widget.style,
          author: widget.author,
          saved: widget.saved,
          challenge: widget.challenge,
          cursor: cursor,
        ),
        identity: (post) => post.id,
        isCurrent: () => app.account == currentOwner && app.signedIn,
      );
    }
    if (revision != app.revision) {
      revision = app.revision;
      unawaited(pager!.refresh());
    }
  }

  @override
  void dispose() {
    pager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pager!,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pager!.loaded && pager!.items.isEmpty && pager!.error == null)
          EmptyNote(
            widget.saved
                ? 'Keep a little inspiration.'
                : 'The next cover could be yours.',
            widget.saved
                ? 'Save a dance post to find it here.'
                : 'Share a photo or a dance video. New posts appear after review.',
            action: widget.saved
                ? null
                : VButton(
                    'Share your dance',
                    glyph: Glyph.add,
                    onPressed: () => openPage(
                      context,
                      PublishPage(challenge: widget.challenge),
                    ),
                  ),
          ),
        for (final post in pager!.items)
          Padding(
            key: ValueKey(post.id),
            padding: const EdgeInsets.only(bottom: 24),
            child: PostTile(post: post),
          ),
        PageFooter(
          pager: pager!,
          moreLabel: 'More from the floor',
          loadingLabel: 'Finding the next move…',
        ),
      ],
    ),
  );
}

class SignedAvatar extends StatefulWidget {
  const SignedAvatar(this.dancer, {super.key, this.size = 48});
  final Dancer dancer;
  final double size;
  @override
  State<SignedAvatar> createState() => _SignedAvatarState();
}

class _SignedAvatarState extends State<SignedAvatar> {
  Future<String>? url;
  String? path, owner;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    refresh();
  }

  @override
  void didUpdateWidget(covariant SignedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    refresh();
  }

  void refresh() {
    final app = VimiScope.of(context);
    if (owner != app.account || path != widget.dancer.avatar) {
      owner = app.account;
      path = widget.dancer.avatar;
      url = path == null ? null : app.repo!.mediaUrl(path!);
    }
  }

  @override
  Widget build(BuildContext context) => path == null
      ? Avatar(size: widget.size)
      : FutureBuilder<String>(
          future: url,
          builder: (_, snapshot) =>
              Avatar(url: snapshot.data, size: widget.size),
        );
}

class PostTile extends StatefulWidget {
  const PostTile({super.key, required this.post, this.detail = false});
  final DancePost post;
  final bool detail;
  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  bool busy = false;
  int mediaRetry = 0;
  void retryMedia() {
    VimiScope.of(context).repo!.clearMediaCache();
    setState(() => mediaRetry++);
  }

  Future<void> act(String action) async {
    if (busy) return;
    final app = VimiScope.of(context);
    setState(() => busy = true);
    try {
      await app.repo!.postAction(
        widget.post.id,
        action,
        selected: action == 'like' ? !widget.post.liked : !widget.post.saved,
      );
      app.changed();
    } catch (e) {
      if (mounted) feedback(context, readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final app = VimiScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => openPage(context, DancerPage(id: p.author.id)),
                child: Row(
                  children: [
                    SignedAvatar(p.author, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.author.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${p.style} · ${displayDate(p.createdAt)}',
                            style: const TextStyle(color: VimiColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VIconButton(
              Glyph.more,
              label: 'Post options',
              onPressed: () => postOptions(context, p),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, box) => SizedBox(
            height: p.kind == 'image' ? box.maxWidth * 4 / 3 : null,
            child: FutureBuilder<String>(
              key: ValueKey('${p.mediaPath}-$mediaRetry'),
              future: app.repo!.mediaUrl(p.mediaPath),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return ErrorNote(
                    'This media could not be opened.',
                    onRetry: retryMedia,
                  );
                if (!snapshot.hasData)
                  return const SurfacePanel(child: Text('Opening media…'));
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: p.kind == 'video'
                      ? RehearsalPlayer(source: snapshot.data!, network: true)
                      : Semantics(
                          label: 'Dance photo by ${p.author.name}',
                          button: true,
                          child: GestureDetector(
                            onTap: () =>
                                openPage(context, DancePhotoPage(post: p)),
                            child: Image.network(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => ErrorNote(
                                'This photo could not be opened.',
                                onRetry: retryMedia,
                              ),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            VIconButton(
              p.liked ? Glyph.heartFull : Glyph.heart,
              color: p.liked ? VimiColors.accent : VimiColors.ink,
              label: '${p.liked ? 'Remove like' : 'Like post'} · ${p.likes}',
              onPressed: busy ? null : () => act('like'),
            ),
            Text('${p.likes}'),
            VIconButton(
              Glyph.comment,
              label: 'Read comments · ${p.comments}',
              onPressed: () => openPage(context, PostDetailPage(post: p)),
            ),
            Text('${p.comments}'),
            VIconButton(
              Glyph.save,
              color: p.saved ? VimiColors.cyan : VimiColors.ink,
              label: p.saved ? 'Remove saved post' : 'Save post',
              onPressed: busy ? null : () => act('save'),
            ),
            if (p.status != 'approved')
              Text(
                p.status == 'pending' ? 'In review' : 'Not approved',
                style: const TextStyle(color: VimiColors.muted),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(p.caption, style: Theme.of(context).textTheme.bodyLarge),
        ),
        if (!widget.detail)
          VButton(
            'View dance and comments',
            quiet: true,
            onPressed: () => openPage(context, PostDetailPage(post: p)),
          ),
      ],
    );
  }
}

class DancePhotoPage extends StatefulWidget {
  const DancePhotoPage({super.key, required this.post});
  final DancePost post;
  @override
  State<DancePhotoPage> createState() => _DancePhotoPageState();
}

class _DancePhotoPageState extends State<DancePhotoPage> {
  Future<String>? url;
  int attempt = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    url ??= VimiScope.of(context).repo!.mediaUrl(widget.post.mediaPath);
  }

  void retry() {
    final repo = VimiScope.of(context).repo!;
    repo.clearMediaCache();
    setState(() {
      attempt++;
      url = repo.mediaUrl(widget.post.mediaPath);
    });
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: widget.post.author.name,
    child: FutureBuilder<String>(
      future: url,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: ErrorNote('This photo could not be opened.', onRetry: retry),
          );
        if (!snapshot.hasData)
          return const Center(child: Text('Opening photo…'));
        return InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(
              snapshot.data!,
              key: ValueKey(attempt),
              fit: BoxFit.contain,
              semanticLabel: 'Dance photo by ${widget.post.author.name}',
              errorBuilder: (_, __, ___) =>
                  ErrorNote('This photo could not be opened.', onRetry: retry),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> postOptions(BuildContext context, DancePost post) async {
  PlaybackCoordinator.pauseAll();
  final app = VimiScope.of(context);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SurfacePanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (post.author.id == app.account)
                VButton(
                  'Edit caption and style',
                  quiet: true,
                  onPressed: () {
                    Navigator.pop(ctx);
                    openPage(
                      context,
                      EditContentPage(
                        kind: 'post',
                        id: post.id,
                        text: post.caption,
                        style: post.style,
                      ),
                    );
                  },
                ),
              if (post.author.id == app.account)
                VButton(
                  'Delete this post',
                  glyph: Glyph.delete,
                  quiet: true,
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (!await confirmAction(
                          context,
                          title: 'Delete this dance?',
                          body:
                              'Your post, media and comments will be removed.',
                          action: 'Delete post',
                        ) ||
                        !context.mounted)
                      return;
                    try {
                      await app.repo!.deletePost(post);
                      app.changed();
                      if (context.mounted) feedback(context, 'Post deleted.');
                    } catch (e) {
                      if (context.mounted) feedback(context, readableError(e));
                    }
                  },
                )
              else ...[
                VButton(
                  'Report this post',
                  glyph: Glyph.report,
                  quiet: true,
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(reportContent(context, 'post', post.id));
                  },
                ),
                VButton(
                  'Block ${post.author.name}',
                  glyph: Glyph.block,
                  quiet: true,
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(blockDancer(context, post.author));
                  },
                ),
              ],
              VButton(
                'Close',
                quiet: true,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> reportContent(BuildContext context, String type, String id) async {
  final app = VimiScope.of(context);
  if (!app.signedIn) return;
  final reason = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SurfacePanel(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'What should we review?',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                for (final reason in const [
                  'Child safety',
                  'Harassment',
                  'Sexual content',
                  'Hate or violence',
                  'Copyright',
                  'Spam or scam',
                  'Privacy',
                  'Underage user',
                  'Other',
                ])
                  VButton(
                    reason,
                    quiet: true,
                    onPressed: () => Navigator.pop(ctx, reason),
                  ),
                VButton(
                  'Cancel',
                  quiet: true,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  if (!await confirmAction(
        context,
        title: 'Send this report?',
        body:
            'The item will be hidden for you and added to the moderation queue.',
        action: 'Send report',
      ) ||
      !context.mounted)
    return;
  try {
    await app.repo!.report(type, id, reason);
    app.changed();
    if (context.mounted)
      feedback(context, 'Report sent. This item is now hidden for you.');
  } catch (e) {
    if (context.mounted) feedback(context, readableError(e));
  }
}

Future<void> blockDancer(BuildContext context, Dancer dancer) async {
  final app = VimiScope.of(context);
  if (!await confirmAction(
        context,
        title: 'Block ${dancer.name}?',
        body:
            'Your follows will be removed and you will no longer see each other’s content or messages.',
        action: 'Block dancer',
      ) ||
      !context.mounted)
    return;
  try {
    await app.repo!.block(dancer.id, true);
    await app.refreshAccount();
    if (context.mounted) {
      Navigator.maybePop(context);
      feedback(context, 'Dancer blocked.');
    }
  } catch (e) {
    if (context.mounted) feedback(context, readableError(e));
  }
}

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.post});
  final DancePost post;
  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final message = TextEditingController();
  CursorPager<Json>? comments;
  late Future<DancePost?> post;
  DancePost? visiblePost;
  bool started = false, busy = false;
  int revision = -1;
  String? error;
  String nonce = const Uuid().v4();
  LocalStudio? draftStore;
  String? draftKey;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (draftKey == null) {
      draftStore = app.studio;
      draftKey = 'comment.v1.${app.account}.${widget.post.id}';
      try {
        final draft = draftStore!.readDraft(draftKey!);
        message.text = draft?['body'] as String? ?? '';
        nonce = draft?['client_id'] as String? ?? nonce;
      } catch (_) {
        error =
            'Your previous comment could not be opened. It stays stored until you write a new comment.';
      }
    }
    if (revision != app.revision) {
      revision = app.revision;
      comments ??= CursorPager(
        fetch: (cursor) =>
            app.repo!.commentPage(widget.post.id, cursor: cursor),
        identity: (row) => row['id'] as String,
        isCurrent: () =>
            draftKey == 'comment.v1.${app.account}.${widget.post.id}' &&
            app.signedIn,
      );
      unawaited(comments!.refresh());
      post = app.repo!.post(widget.post.id);
      started = true;
    }
  }

  @override
  void dispose() {
    comments?.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy || message.text.trim().isEmpty) return;
    final app = VimiScope.of(context);
    setState(() => busy = true);
    try {
      await app.repo!.comment(widget.post.id, message.text.trim(), nonce);
      await draftStore!.removeDraft(draftKey!);
      app.changed();
      if (mounted) {
        message.clear();
        nonce = const Uuid().v4();
        error = null;
        feedback(context, 'Comment submitted for review.');
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return VPage(
      title: 'A closer look',
      child: FutureBuilder<DancePost?>(
        future: post,
        builder: (context, currentPost) {
          if (currentPost.connectionState == ConnectionState.done &&
              !currentPost.hasError) {
            visiblePost = currentPost.data;
          }
          final shown = currentPost.data ?? visiblePost;
          if (currentPost.hasError && shown == null)
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorNote(
                readableError(currentPost.error!),
                onRetry: app.changed,
              ),
            );
          if (shown == null &&
              currentPost.connectionState != ConnectionState.done)
            return const Center(child: Text('Opening dance…'));
          if (shown == null)
            return const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyNote(
                'This dance is unavailable.',
                'Return to the floor to see other movement.',
              ),
            );
          return ListView(
            padding: const EdgeInsets.all(20),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (currentPost.hasError)
                    ErrorNote(
                      readableError(currentPost.error!),
                      onRetry: app.changed,
                    ),
                  PostTile(post: shown, detail: true),
                  const SizedBox(height: 24),
                  Text(
                    'Talk about the movement',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: comments!,
                    builder: (context, _) {
                      final rows = comments!.items.reversed;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PageFooter(
                            pager: comments!,
                            moreLabel: 'Earlier comments',
                            loadingLabel: 'Opening comments…',
                          ),
                          if (comments!.loaded &&
                              rows.isEmpty &&
                              comments!.error == null)
                            const Text('Start with a kind, specific note.'),
                          ...rows.map((c) {
                            final author = Dancer.fromJson(
                              jsonMap(c['author']),
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () => openPage(
                                            context,
                                            DancerPage(id: author.id),
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(author.name),
                                          ),
                                        ),
                                      ),
                                      if (c['author_id'] == app.account)
                                        VButton(
                                          'Edit',
                                          quiet: true,
                                          onPressed: () => openPage(
                                            context,
                                            EditContentPage(
                                              kind: 'comment',
                                              id: c['id'] as String,
                                              text: c['body'] as String,
                                            ),
                                          ),
                                        ),
                                      if (c['status'] == 'pending')
                                        const Text('In review'),
                                      VIconButton(
                                        c['author_id'] == app.account
                                            ? Glyph.delete
                                            : Glyph.report,
                                        label: c['author_id'] == app.account
                                            ? 'Delete comment'
                                            : 'Report comment',
                                        onPressed: () async {
                                          if (c['author_id'] == app.account) {
                                            if (!await confirmAction(
                                                  context,
                                                  title: 'Delete this comment?',
                                                  body:
                                                      'Your comment will be removed.',
                                                  action: 'Delete comment',
                                                ) ||
                                                !context.mounted)
                                              return;
                                            try {
                                              await app.repo!.deleteComment(
                                                c['id'] as String,
                                              );
                                              app.changed();
                                            } catch (e) {
                                              if (context.mounted)
                                                feedback(
                                                  context,
                                                  readableError(e),
                                                );
                                            }
                                          } else {
                                            await reportContent(
                                              context,
                                              'comment',
                                              c['id'] as String,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(c['body'] as String),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  VField(
                    'Add a comment',
                    controller: message,
                    enabled: !busy,
                    lines: 3,
                    maxLength: 1000,
                    onChanged: (text) {
                      nonce = const Uuid().v4();
                      unawaited(
                        draftStore!
                            .writeDraft(draftKey!, {
                              'body': text,
                              'client_id': nonce,
                            })
                            .catchError((Object e) {
                              if (mounted)
                                setState(() => error = readableError(e));
                            }),
                      );
                    },
                  ),
                  if (error != null) ErrorNote(error!),
                  VButton('Submit comment', onPressed: send, busy: busy),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChallengesPage extends StatelessWidget {
  const ChallengesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return VPage(
      title: 'Pick your next eight',

      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Original practice prompts. Bring your own movement and music you have permission to use.',
          ),
          const SizedBox(height: 24),
          for (final challenge in app.challenges)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SurfacePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('${challenge.style} · ${challenge.counts} counts'),
                    const SizedBox(height: 12),
                    Text(challenge.description),
                    const SizedBox(height: 16),
                    VButton(
                      'Open challenge',

                      onPressed: () => openPage(
                        context,
                        ChallengePage(challenge: challenge),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChallengePage extends StatelessWidget {
  const ChallengePage({super.key, required this.challenge});
  final ChoreographyPrompt challenge;
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return VPage(
      title: challenge.title,

      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            challenge.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < challenge.prompts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${i + 1}. ${challenge.prompts[i]}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          VButton(
            'Share your take',
            glyph: Glyph.video,

            onPressed: () async {
              if (await requireSignIn(context) && context.mounted)
                await openPage(context, PublishPage(challenge: challenge.id));
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Community takes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (app.signedIn)
            PostCollection(
              key: ValueKey('${challenge.id}-${app.account}'),
              challenge: challenge.id,
            )
          else
            const Text('Sign in to see the community’s takes.'),
        ],
      ),
    );
  }
}
