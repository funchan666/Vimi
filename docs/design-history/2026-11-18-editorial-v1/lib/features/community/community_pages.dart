import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'Your kind\nof movement.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1.35,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/ui/floor.webp',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, .55),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: VButton(
                      'Pick a chorus challenge',
                      onPressed: () =>
                          openPage(context, const ChallengesPage()),
                      lime: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'On the floor',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            VIconButton(
              Glyph.search,
              label: 'Find dancers',
              onPressed: () => openPage(context, const DancerDirectory()),
            ),
            VIconButton(
              Glyph.refresh,
              label: 'Refresh posts',
              onPressed: app.changed,
            ),
          ],
        ),
        ChoiceStrip(
          options: ['All', ...DanceStyle.values.map((s) => s.label)],
          value: style,
          onChanged: (v) => setState(() => style = v),
        ),
        const SizedBox(height: 16),
        if (!app.signedIn)
          EmptyNote(
            'Come dance with us.',
            'Join the community to see dancers, share your cover and start a conversation.',
            action: VButton(
              'Join the floor',
              onPressed: () => openPage(context, const AuthPage(signUp: true)),
            ),
          )
        else
          PostCollection(
            key: ValueKey('floor-$style-${app.revision}'),
            style: style == 'All' ? null : style,
          ),
      ],
    );
  }
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
  List<DancePost> posts = [];
  bool loading = false, more = true;
  String? error;
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      unawaited(load());
    }
  }

  Future<void> load() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final repo = VimiScope.of(context).repo!;
      final next = await repo.feed(
        style: widget.style,
        author: widget.author,
        saved: widget.saved,
        challenge: widget.challenge,
        offset: posts.length,
      );
      if (mounted)
        setState(() {
          posts.addAll(next.where((p) => !posts.any((old) => old.id == p.id)));
          more = next.length == 20;
        });
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (error != null) ErrorNote(error!, onRetry: load),
      if (!loading && posts.isEmpty && error == null)
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
      for (final post in posts)
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: PostTile(post: post),
        ),
      if (loading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Finding the next move…'),
        ),
      if (!loading && more && posts.isNotEmpty)
        VButton('More from the floor', quiet: true, onPressed: load),
    ],
  );
}

class SignedAvatar extends StatelessWidget {
  const SignedAvatar(this.dancer, {super.key, this.size = 48});
  final Dancer dancer;
  final double size;
  @override
  Widget build(BuildContext context) {
    if (dancer.avatar == null) return Avatar(size: size);
    return FutureBuilder<String>(
      future: VimiScope.of(context).repo!.mediaUrl(dancer.avatar!),
      builder: (_, snapshot) => Avatar(url: snapshot.data, size: size),
    );
  }
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
  Future<void> act(String action) async {
    if (busy) return;
    final app = VimiScope.of(context);
    setState(() => busy = true);
    try {
      await app.repo!.postAction(widget.post.id, action);
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
        FutureBuilder<String>(
          future: app.repo!.mediaUrl(p.mediaPath),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return ErrorNote(
                'This media is unavailable. Refresh the floor to try again.',
              );
            if (!snapshot.hasData)
              return const Paper(child: Text('Opening media…'));
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: p.kind == 'video'
                  ? RehearsalPlayer(source: snapshot.data!, network: true)
                  : Semantics(
                      label: 'Dance photo by ${p.author.name}',
                      button: true,
                      child: GestureDetector(
                        onTap: () => openPage(
                          context,
                          VPage(
                            title: p.author.name,
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Center(
                                child: Image.network(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        child: Image.network(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ErrorNote(
                            'This photo could not be opened.',
                          ),
                        ),
                      ),
                    ),
            );
          },
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            VIconButton(
              p.liked ? Glyph.heartFull : Glyph.heart,
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

Future<void> postOptions(BuildContext context, DancePost post) async {
  PlaybackCoordinator.pauseAll();
  final app = VimiScope.of(context);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Paper(
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
        child: Paper(
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
    app.changed();
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
  late Future<List<Json>> comments;
  late Future<DancePost?> post;
  bool started = false, busy = false;
  int revision = -1;
  String? error;
  String nonce = const Uuid().v4();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (revision != app.revision) {
      revision = app.revision;
      comments = app.repo!.comments(widget.post.id);
      post = app.repo!.post(widget.post.id);
      started = true;
    }
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy || message.text.trim().isEmpty) return;
    final app = VimiScope.of(context);
    setState(() => busy = true);
    try {
      await app.repo!.comment(widget.post.id, message.text.trim(), nonce);
      message.clear();
      nonce = const Uuid().v4();
      app.changed();
      if (mounted) feedback(context, 'Comment submitted for review.');
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
          if (currentPost.hasError)
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorNote(
                readableError(currentPost.error!),
                onRetry: app.changed,
              ),
            );
          if (currentPost.connectionState != ConnectionState.done)
            return const Center(child: Text('Opening dance…'));
          if (currentPost.data == null)
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
              PostTile(post: currentPost.data!, detail: true),
              const SizedBox(height: 24),
              Text(
                'Talk about the movement',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Json>>(
                future: comments,
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return ErrorNote(
                      readableError(snapshot.error!),
                      onRetry: app.changed,
                    );
                  if (snapshot.connectionState != ConnectionState.done)
                    return const Text('Opening comments…');
                  final rows = snapshot.data ?? [];
                  if (rows.isEmpty)
                    return const Text('Start with a kind, specific note.');
                  return Column(
                    children: rows.map((c) {
                      final author = Dancer.fromJson(jsonMap(c['author']));
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
                                          feedback(context, readableError(e));
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
                    }).toList(),
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
              ),
              if (error != null) ErrorNote(error!),
              VButton('Submit comment', onPressed: send, busy: busy),
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
      art: 'floor',
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
              child: Paper(
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
                      lime: true,
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
      art: 'floor',
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
            lime: true,
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
              key: ValueKey('${challenge.id}-${app.revision}'),
              challenge: challenge.id,
            )
          else
            const Text('Sign in to see the community’s takes.'),
        ],
      ),
    );
  }
}
