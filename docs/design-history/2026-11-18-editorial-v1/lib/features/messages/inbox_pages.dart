import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../design/vimi_ui.dart';
import '../auth/auth_pages.dart';
import '../community/community_pages.dart';
import '../profile/profile_pages.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});
  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  Future<List<Json>>? future;
  int revision = -1;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (app.signedIn && revision != app.revision) {
      revision = app.revision;
      future = app.repo!.inbox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'After the\nlast count.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            VIconButton(
              Glyph.refresh,
              label: 'Refresh conversations',
              onPressed: app.changed,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Talk routines, trade practice notes. Conversations open when you follow each other.',
        ),
        const SizedBox(height: 24),
        if (!app.signedIn)
          EmptyNote(
            'Find your dance people.',
            'Sign in to start conversations with mutual follows.',
            action: VButton(
              'Sign in',
              onPressed: () => openPage(context, const AuthPage(signUp: false)),
            ),
          )
        else
          FutureBuilder<List<Json>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return ErrorNote(
                  readableError(snapshot.error!),
                  onRetry: app.changed,
                );
              if (snapshot.connectionState != ConnectionState.done)
                return const Text('Opening conversations…');
              final rows = snapshot.data ?? [];
              if (rows.isEmpty)
                return EmptyNote(
                  'A good conversation starts on the floor.',
                  'Find a dancer whose movement speaks to you. Follow each other to exchange messages.',
                  action: VButton(
                    'Discover dancers',
                    glyph: Glyph.search,
                    onPressed: () => openPage(context, const DancerDirectory()),
                  ),
                );
              return Column(
                children: rows.map((row) {
                  final peer = Dancer.fromJson(jsonMap(row['peer']));
                  final unread = (row['unread'] as num).toInt();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Paper(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: TextButton(
                        onPressed: () =>
                            openPage(context, ChatPage(peer: peer)),
                        child: Row(
                          children: [
                            SignedAvatar(peer),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    peer.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    row['body'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: VimiColors.muted,
                                    ),
                                  ),
                                  if (unread > 0)
                                    Text(
                                      '$unread unread',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              displayDate(
                                DateTime.parse(row['created_at'] as String),
                              ),
                              style: const TextStyle(color: VimiColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.peer});
  final Dancer peer;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  List<Json> messages = [];
  bool allowed = false, busy = false, loading = true, started = false;
  int revision = -1, generation = 0;
  String? error;
  String nonce = const Uuid().v4();
  String get draftKey =>
      'message.v1.${VimiScope.of(context).account}.${widget.peer.id}';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (!started) {
      started = true;
      input.text = app.studio.preferences.getString(draftKey) ?? '';
    }
    if (revision != app.revision) {
      revision = app.revision;
      unawaited(load());
    }
  }

  Future<void> load() async {
    final request = ++generation;
    final app = VimiScope.of(context);
    final repo = app.repo!;
    try {
      final values = await Future.wait<dynamic>([
        repo.thread(widget.peer.id),
        repo.canMessage(widget.peer.id),
      ]);
      if (!mounted || request != generation) return;
      setState(() {
        messages = values[0] as List<Json>;
        allowed = values[1] as bool;
        loading = false;
        error = null;
      });
      await repo.markRead(widget.peer.id);
    } catch (e) {
      if (mounted && request == generation)
        setState(() {
          error = readableError(e);
          loading = false;
        });
    }
  }

  Future<void> send() async {
    if (busy || input.text.trim().isEmpty) return;
    final app = VimiScope.of(context);
    final text = input.text.trim();
    setState(() => busy = true);
    try {
      await app.repo!.send(widget.peer.id, text, nonce);
      input.clear();
      nonce = const Uuid().v4();
      await app.studio.preferences.remove(draftKey);
      app.changed();
      if (mounted) {
        await load();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: widget.peer.name,
    art: 'inbox',
    actions: [
      VIconButton(
        Glyph.person,
        label: 'Open dancer profile',
        onPressed: () => openPage(context, DancerPage(id: widget.peer.id)),
      ),
    ],
    child: Column(
      children: [
        Expanded(
          child: loading
              ? const Center(child: Text('Opening your conversation…'))
              : ListView(
                  controller: scroll,
                  padding: const EdgeInsets.all(20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (messages.isEmpty)
                      const EmptyNote(
                        'Say it with a little kindness.',
                        'Trade a practice tip or ask about a routine.',
                      ),
                    for (final m in messages)
                      Align(
                        alignment:
                            m['sender_id'] == VimiScope.of(context).account
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.sizeOf(
                                  context,
                                ).width.clamp(280, 640) *
                                .82,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Paper(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['body'] as String,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        displayDate(
                                          DateTime.parse(
                                            m['created_at'] as String,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: VimiColors.muted,
                                        ),
                                      ),
                                      if (m['sender_id'] ==
                                          VimiScope.of(context).account)
                                        Text(
                                          m['read_at'] != null
                                              ? ' · Read'
                                              : ' · Sent',
                                          style: const TextStyle(
                                            color: VimiColors.muted,
                                          ),
                                        ),
                                      if (m['sender_id'] !=
                                          VimiScope.of(context).account)
                                        VIconButton(
                                          Glyph.report,
                                          label: 'Report message',
                                          onPressed: () => reportContent(
                                            context,
                                            'message',
                                            m['id'] as String,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ErrorNote(error!, onRetry: load),
          ),
        if (!allowed && !loading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Follow each other to send messages. If either person has blocked the other, messaging stays unavailable.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: VField(
                  'Your message',
                  controller: input,
                  enabled: !busy,
                  lines: 2,
                  maxLength: 2000,
                  onChanged: (text) {
                    nonce = const Uuid().v4();
                    unawaited(
                      VimiScope.of(
                        context,
                      ).studio.preferences.setString(draftKey, text),
                    );
                  },
                ),
              ),
              VIconButton(
                Glyph.send,
                label: busy ? 'Sending message' : 'Send message',
                onPressed: allowed && !busy ? send : null,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
