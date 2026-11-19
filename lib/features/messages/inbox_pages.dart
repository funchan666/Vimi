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
import '../community/community_pages.dart';
import '../profile/profile_pages.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});
  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
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
        fetch: (cursor) => app.repo!.inboxPage(cursor: cursor),
        identity: (row) => jsonMap(row['peer'])['id'] as String,
        isCurrent: () => app.signedIn && app.account == currentOwner,
      );
    }
    if (pager != null && revision != app.messageRevision) {
      revision = app.messageRevision;
      unawaited(pager!.refresh());
    }
  }

  @override
  void dispose() {
    pager?.dispose();
    super.dispose();
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
                'Messages',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            VIconButton(
              Glyph.refresh,
              label: 'Refresh conversations',
              onPressed: () => pager?.refresh(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Practice notes and conversations with your mutual follows.',
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
          AnimatedBuilder(
            animation: pager!,
            builder: (context, _) {
              final rows = pager!.items;
              final empty = EmptyNote(
                'A good conversation starts on the floor.',
                'Find a dancer whose movement speaks to you. Follow each other to exchange messages.',
                action: VButton(
                  'Discover dancers',
                  glyph: Glyph.search,
                  onPressed: () => openPage(context, const DancerDirectory()),
                ),
              );
              return Column(
                children: [
                  if (pager!.loaded && rows.isEmpty && pager!.error == null)
                    empty,
                  ...rows.map((row) {
                    final peer = Dancer.fromJson(jsonMap(row['peer']));
                    final unread = (row['unread'] as num).toInt();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SurfacePanel(
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
                                          color: VimiColors.accent,
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
                  }),
                  PageFooter(
                    pager: pager!,
                    moreLabel: 'Earlier conversations',
                    loadingLabel: 'Opening conversations…',
                  ),
                ],
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
  late CursorPager<Json> history;
  bool allowed = false, busy = false, loading = true, started = false;
  int revision = -1, generation = 0;
  String? error;
  String? draftError, owner;
  late LocalStudio draftStore;
  late String storedDraftKey;
  String nonce = const Uuid().v4();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (!started) {
      started = true;
      owner = app.account;
      draftStore = app.studio;
      storedDraftKey = 'message.v2.$owner.${widget.peer.id}';
      history = CursorPager(
        fetch: (cursor) => app.repo!.threadPage(widget.peer.id, cursor: cursor),
        identity: (row) => row['id'] as String,
        isCurrent: () => app.signedIn && app.account == owner,
      );
      try {
        final draft = draftStore.readDraft(storedDraftKey);
        input.text =
            draft?['body'] as String? ??
            app.studio.preferences.getString(
              'message.v1.$owner.${widget.peer.id}',
            ) ??
            '';
        nonce = draft?['client_id'] as String? ?? nonce;
      } catch (_) {
        draftError =
            'Your previous message draft could not be opened. It stays stored until you write a new message.';
      }
    }
    if (revision != app.messageRevision) {
      revision = app.messageRevision;
      unawaited(load());
    }
  }

  Future<void> load() async {
    final request = ++generation;
    final app = VimiScope.of(context);
    if (!app.signedIn || owner != app.account) return;
    final repo = app.repo!;
    final offset = scroll.hasClients ? scroll.offset : 0.0;
    final extent = scroll.hasClients ? scroll.position.maxScrollExtent : 0.0;
    try {
      final values = await Future.wait<dynamic>([
        history.refresh(),
        repo.canMessage(widget.peer.id),
      ]);
      if (!mounted || request != generation || owner != app.account) return;
      setState(() {
        allowed = values[1] as bool;
        loading = false;
        error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || request != generation || !scroll.hasClients) return;
        if (offset < 72) {
          scroll.jumpTo(0);
        } else {
          final shift = scroll.position.maxScrollExtent - extent;
          scroll.jumpTo(
            (offset + shift).clamp(0, scroll.position.maxScrollExtent),
          );
        }
      });
      if (history.error == null &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        await repo.markRead(widget.peer.id);
      }
    } catch (e) {
      if (mounted && request == generation && owner == app.account) {
        setState(() {
          error = readableError(e);
          loading = false;
          allowed = false;
        });
      }
    }
  }

  Future<void> send() async {
    if (busy || input.text.trim().isEmpty) return;
    final app = VimiScope.of(context);
    final text = input.text.trim();
    setState(() => busy = true);
    try {
      await app.repo!.send(widget.peer.id, text, nonce);
      await draftStore.removeDraft(storedDraftKey);
      await draftStore.preferences.remove(
        'message.v1.$owner.${widget.peer.id}',
      );
      if (owner != app.account) return;
      app.messagesChanged();
      if (mounted) {
        input.clear();
        nonce = const Uuid().v4();
        await load();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients) scroll.jumpTo(0);
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
    history.dispose();
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: widget.peer.name,

    actions: [
      VIconButton(
        Glyph.refresh,
        label: 'Refresh conversation',
        onPressed: load,
      ),
      VIconButton(
        Glyph.person,
        label: 'Open dancer profile',
        onPressed: () => openPage(context, DancerPage(id: widget.peer.id)),
      ),
    ],
    child: Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: history,
            builder: (context, _) => ListView(
              controller: scroll,
              reverse: true,
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (history.loaded &&
                    history.items.isEmpty &&
                    history.error == null)
                  const EmptyNote(
                    'Say it with a little kindness.',
                    'Trade a practice tip or ask about a routine.',
                  ),
                for (final m in history.items)
                  Align(
                    key: ValueKey(m['id']),
                    alignment: m['sender_id'] == VimiScope.of(context).account
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.sizeOf(context).width.clamp(280, 640) *
                            .82,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SurfacePanel(
                          illuminated:
                              m['sender_id'] == VimiScope.of(context).account,
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['body'] as String,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    displayMessageTime(
                                      DateTime.parse(m['created_at'] as String),
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
                PageFooter(
                  pager: history,
                  moreLabel: 'Earlier messages',
                  loadingLabel: 'Opening your conversation…',
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ErrorNote(error!, onRetry: load),
          ),
        if (draftError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ErrorNote(draftError!),
          ),
        if (!allowed && !loading && error == null)
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
                    draftError = null;
                    unawaited(
                      draftStore
                          .writeDraft(storedDraftKey, {
                            'body': text,
                            'client_id': nonce,
                          })
                          .catchError((Object e) {
                            if (mounted)
                              setState(() => draftError = readableError(e));
                          }),
                    );
                  },
                ),
              ),
              VIconButton(
                Glyph.send,
                color: VimiColors.accent,
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
