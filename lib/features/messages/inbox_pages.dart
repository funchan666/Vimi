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
import 'direct_calls.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key, this.active = true});

  final bool active;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final search = TextEditingController();
  final searchFocus = FocusNode();
  CursorPager<Json>? pager;
  CursorPager<Dancer>? mutuals;
  String? owner, openingContact;
  int revision = -1, contactRevision = -1;
  bool unreadOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (!app.signedIn) {
      pager?.dispose();
      mutuals?.dispose();
      pager = null;
      mutuals = null;
      owner = null;
      return;
    }
    if (pager == null || owner != app.account) {
      pager?.dispose();
      mutuals?.dispose();
      final newOwner = app.account;
      final repo = app.repo!;
      owner = newOwner;
      revision = contactRevision = -1;
      pager = CursorPager(
        fetch: (cursor) => repo.inboxPage(cursor: cursor),
        identity: (row) => jsonMap(row['peer'])['id'] as String,
        isCurrent: () => app.signedIn && app.account == newOwner,
      );
      mutuals = CursorPager(
        fetch: (cursor) => _mutualPage(repo, newOwner, cursor),
        identity: (dancer) => dancer.id,
        isCurrent: () => app.signedIn && app.account == newOwner,
      );
    }
    if (revision != app.messageRevision) {
      revision = app.messageRevision;
      unawaited(pager!.refresh());
    }
    refreshContacts(app);
  }

  @override
  void didUpdateWidget(covariant InboxPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) {
      searchFocus.unfocus();
    } else if (!oldWidget.active) {
      refreshContacts(VimiScope.of(context));
    }
  }

  void refreshContacts(AppController app) {
    final contacts = mutuals;
    if (!widget.active || contacts == null || contactRevision == app.revision) {
      return;
    }
    contactRevision = app.revision;
    unawaited(contacts.refresh());
  }

  Future<void> compose() async {
    final app = VimiScope.of(context);
    final contacts = mutuals;
    if (!app.signedIn || contacts == null || openingContact != null) return;
    searchFocus.unfocus();
    final currentOwner = app.account;
    final peer = await openPage<Dancer>(
      context,
      _NewConversationPage(owner: currentOwner, contacts: contacts),
    );
    if (!mounted ||
        peer == null ||
        !app.signedIn ||
        app.account != currentOwner) {
      return;
    }
    await openPage(context, ChatPage(peer: peer));
  }

  Future<void> quickChat(Dancer peer) async {
    if (openingContact != null) return;
    final app = VimiScope.of(context);
    final currentOwner = app.account;
    if (!app.signedIn) return;
    searchFocus.unfocus();
    setState(() => openingContact = peer.id);
    try {
      final allowed = await app.repo!.canMessage(peer.id);
      if (!mounted ||
          !widget.active ||
          !app.signedIn ||
          app.account != currentOwner ||
          ModalRoute.isCurrentOf(context) == false) {
        return;
      }
      if (allowed) {
        await openPage(context, ChatPage(peer: peer));
      } else {
        feedback(context, 'Messaging is no longer available with this dancer.');
        final contacts = mutuals;
        if (contacts != null) unawaited(contacts.refresh());
      }
    } catch (error) {
      if (mounted && widget.active && app.account == currentOwner) {
        feedback(context, readableError(error));
      }
    } finally {
      if (mounted) setState(() => openingContact = null);
    }
  }

  void discoverDancers() {
    searchFocus.unfocus();
    openPage(context, const DancerDirectory());
  }

  @override
  void dispose() {
    pager?.dispose();
    mutuals?.dispose();
    search.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = pager;
    final contacts = mutuals;
    if (conversations == null || contacts == null) {
      return Center(
        child: VIconButton(
          Glyph.inbox,
          label: 'Sign in to open conversations',
          filled: true,
          onPressed: () => openPage(context, const AuthPage(signUp: false)),
        ),
      );
    }
    final query = search.text.trim().toLowerCase();
    final searching = query.isNotEmpty;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(child: _searchField()),
                  const SizedBox(width: 8),
                  VIconButton(
                    Glyph.edit,
                    label: 'New conversation',
                    primary: true,
                    onPressed: openingContact == null ? compose : null,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: VimiColors.cyan,
                backgroundColor: VimiColors.surface,
                onRefresh: () async {
                  await Future.wait([
                    conversations.refresh(),
                    contacts.refresh(),
                  ]);
                },
                child: ListenableBuilder(
                  listenable: Listenable.merge([conversations, contacts]),
                  builder: (context, _) {
                    final rows = conversations.items.where((row) {
                      if (unreadOnly && _unreadMessages(row) == 0) return false;
                      if (!searching) return true;
                      final peer = jsonMap(row['peer']);
                      final name = (peer['display_name'] as String? ?? '')
                          .toLowerCase();
                      return name.contains(query) ||
                          (row['body'] as String).toLowerCase().contains(query);
                    }).toList();
                    final settled =
                        conversations.loaded &&
                        !conversations.loading &&
                        conversations.error == null;
                    final emptyInbox =
                        settled &&
                        conversations.items.isEmpty &&
                        !searching &&
                        !unreadOnly;
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              _InboxFilter(
                                label: 'All',
                                selected: !unreadOnly,
                                onPressed: () =>
                                    setState(() => unreadOnly = false),
                              ),
                              const SizedBox(width: 6),
                              _InboxFilter(
                                label: 'Unread',
                                selected: unreadOnly,
                                onPressed: () =>
                                    setState(() => unreadOnly = true),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: VimiColors.tonal),
                        if (!searching &&
                            !unreadOnly &&
                            contacts.items.isNotEmpty)
                          _ContactShelf(
                            title: 'Quick chats',
                            people: contacts.items.take(5),
                            onOpenAll: compose,
                            openAllLabel: 'Choose a dancer to message',
                            onSelect: openingContact == null ? quickChat : null,
                          ),
                        if (settled && rows.isEmpty)
                          _InboxEmpty(
                            glyph: searching
                                ? Glyph.search
                                : unreadOnly
                                ? Glyph.check
                                : Glyph.inbox,
                            title: searching
                                ? 'No matching chats'
                                : unreadOnly
                                ? 'No unread chats'
                                : 'No conversations yet',
                            detail: searching
                                ? (conversations.hasMore
                                      ? 'Try earlier conversations below.'
                                      : 'Try another name or message.')
                                : unreadOnly
                                ? (conversations.hasMore
                                      ? 'Check earlier conversations below.'
                                      : null)
                                : 'You can message dancers who follow you back.',
                          ),
                        if (emptyInbox && contacts.items.isEmpty)
                          _FindDancersShelf(
                            onOpenAll: discoverDancers,
                            key: ValueKey(owner),
                          ),
                        for (final row in rows)
                          _InboxConversation(
                            key: ValueKey(jsonMap(row['peer'])['id']),
                            row: row,
                          ),
                        PageFooter(
                          pager: conversations,
                          moreLabel: 'Earlier conversations',
                          loadingLabel: 'Opening conversations…',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    const radius = BorderRadius.all(Radius.circular(15));
    return TextField(
      controller: search,
      focusNode: searchFocus,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14, color: VimiColors.ink),
      decoration: InputDecoration(
        hintText: 'Search chats',
        hintStyle: const TextStyle(color: VimiColors.muted, fontSize: 14),
        fillColor: VimiColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 13),
        enabledBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: VimiColors.tonal),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: VimiColors.violet),
        ),
        prefixIcon: const Center(
          widthFactor: 1,
          heightFactor: 1,
          child: VIcon(Glyph.search, size: 19, color: VimiColors.violet),
        ),
        suffixIcon: search.text.isEmpty
            ? null
            : VIconButton(
                Glyph.close,
                label: 'Clear chat search',
                onPressed: () => setState(search.clear),
              ),
      ),
    );
  }
}

class _InboxFilter extends StatelessWidget {
  const _InboxFilter({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        foregroundColor: selected ? VimiColors.cyan : VimiColors.muted,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(height: 5),
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

class _InboxEmpty extends StatelessWidget {
  const _InboxEmpty({required this.glyph, required this.title, this.detail});

  final Glyph glyph;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 34, 16, 28),
    child: Column(
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: VimiColors.surface,
            borderRadius: BorderRadius.all(Radius.circular(17)),
            border: Border.fromBorderSide(BorderSide(color: VimiColors.tonal)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: VIcon(glyph, size: 27, color: VimiColors.cyan),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(
            detail!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: VimiColors.muted),
          ),
        ],
      ],
    ),
  );
}

class _FindDancersShelf extends StatefulWidget {
  const _FindDancersShelf({super.key, required this.onOpenAll});

  final VoidCallback onOpenAll;

  @override
  State<_FindDancersShelf> createState() => _FindDancersShelfState();
}

class _FindDancersShelfState extends State<_FindDancersShelf> {
  late Future<CursorPage<Dancer>> people;
  int revision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (revision != app.revision) {
      revision = app.revision;
      people = app.repo!.dancerPage('');
    }
  }

  void retry() {
    final repository = VimiScope.of(context).repo!;
    setState(() => people = repository.dancerPage(''));
  }

  Widget status(String message, {bool canRetry = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: VimiColors.muted),
            ),
          ),
        ),
        if (canRetry)
          VIconButton(
            Glyph.refresh,
            label: 'Retry finding dancers',
            color: VimiColors.violet,
            onPressed: retry,
          ),
        VIconButton(
          Glyph.search,
          label: 'Browse dancers',
          color: VimiColors.cyan,
          onPressed: widget.onOpenAll,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<CursorPage<Dancer>>(
    future: people,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return status('Finding dancers…');
      }
      if (snapshot.hasError) {
        return status('Couldn’t load dancer suggestions.', canRetry: true);
      }
      final dancers = snapshot.data?.items ?? [];
      if (dancers.isEmpty) {
        return status('No dancer suggestions yet.');
      }
      return _ContactShelf(
        title: 'Find dancers',
        openAllLabel: 'Browse dancers',
        people: dancers.take(8),
        onOpenAll: widget.onOpenAll,
        onSelect: (dancer) => openPage(context, DancerPage(id: dancer.id)),
      );
    },
  );
}

class _ContactShelf extends StatelessWidget {
  const _ContactShelf({
    required this.title,
    required this.openAllLabel,
    required this.people,
    required this.onOpenAll,
    required this.onSelect,
  });

  final String title, openAllLabel;
  final Iterable<Dancer> people;
  final VoidCallback onOpenAll;
  final ValueChanged<Dancer>? onSelect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            VIconButton(
              Glyph.next,
              label: openAllLabel,
              color: VimiColors.violet,
              onPressed: onOpenAll,
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final dancer in people)
                SizedBox(
                  width: 74,
                  child: TextButton(
                    onPressed: onSelect == null
                        ? null
                        : () => onSelect!(dancer),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      foregroundColor: VimiColors.ink,
                    ),
                    child: Column(
                      children: [
                        SignedAvatar(dancer, size: 49),
                        const SizedBox(height: 6),
                        Text(
                          dancer.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

int _unreadMessages(Json row) => (row['unread'] as num?)?.toInt() ?? 0;

class _InboxConversation extends StatelessWidget {
  const _InboxConversation({super.key, required this.row});
  final Json row;

  @override
  Widget build(BuildContext context) {
    final peer = Dancer.fromJson(jsonMap(row['peer']));
    final unread = _unreadMessages(row);
    final time = DateTime.parse(row['created_at'] as String).toLocal();
    final today = DateUtils.isSameDay(DateTime.now(), time);
    return _ConversationRow(
      key: ValueKey(peer.id),
      peer: peer,
      detail: row['body'] as String,
      highlighted: unread > 0,
      onTap: () => openPage(context, ChatPage(peer: peer)),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 84),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              today
                  ? MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay.fromDateTime(time),
                      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                        context,
                      ),
                    )
                  : displayDate(time),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unread > 0 ? VimiColors.cyan : VimiColors.muted,
                fontSize: 11,
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(height: 5),
              Semantics(
                label: '$unread unread messages',
                excludeSemantics: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: VimiColors.cyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: VimiColors.onAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    super.key,
    required this.peer,
    this.detail,
    this.trailing,
    this.onTap,
    this.highlighted = false,
  });
  final Dancer peer;
  final String? detail;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: VimiColors.tonal)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
            child: Row(
              children: [
                SignedAvatar(peer, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peer.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (detail != null && detail!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          detail!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: highlighted
                                ? VimiColors.ink
                                : VimiColors.muted,
                            fontSize: 13,
                            fontWeight: highlighted
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NewConversationPage extends StatefulWidget {
  const _NewConversationPage({required this.owner, required this.contacts});
  final String owner;
  final CursorPager<Dancer> contacts;

  @override
  State<_NewConversationPage> createState() => _NewConversationPageState();
}

class _NewConversationPageState extends State<_NewConversationPage> {
  String? checking;

  Future<void> choose(Dancer dancer) async {
    if (checking != null) return;
    final app = VimiScope.of(context);
    if (!app.signedIn || app.account != widget.owner) return;
    setState(() => checking = dancer.id);
    try {
      final allowed = await app.repo!.canMessage(dancer.id);
      if (!mounted ||
          !app.signedIn ||
          app.account != widget.owner ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      if (allowed) {
        Navigator.of(context).pop(dancer);
      } else {
        feedback(context, 'Messaging is no longer available with this dancer.');
        unawaited(widget.contacts.refresh());
      }
    } catch (error) {
      if (mounted &&
          app.signedIn &&
          app.account == widget.owner &&
          ModalRoute.of(context)?.isCurrent == true) {
        feedback(context, readableError(error));
      }
    } finally {
      if (mounted) setState(() => checking = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final current = widget.contacts;
    return VPage(
      title: 'New conversation',
      actions: [
        VIconButton(
          Glyph.search,
          label: 'Discover dancers',
          onPressed: checking == null
              ? () => openPage(context, const DancerDirectory())
              : null,
        ),
      ],
      child: !app.signedIn || app.account != widget.owner
          ? const SizedBox.shrink()
          : AnimatedBuilder(
              animation: current,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  if (current.loaded &&
                      current.items.isEmpty &&
                      current.error == null &&
                      !current.loading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                      child: Text(
                        current.hasMore
                            ? 'No matches yet. Check more of your follows.'
                            : 'You can message dancers who follow you back.',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: VimiColors.muted,
                        ),
                      ),
                    ),
                  for (final dancer in current.items)
                    _ConversationRow(
                      key: ValueKey(dancer.id),
                      peer: dancer,
                      detail: dancer.styles.join(' · '),
                      trailing: checking == dancer.id
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const VIcon(
                              Glyph.next,
                              size: 18,
                              color: VimiColors.muted,
                            ),
                      onTap: checking == null ? () => choose(dancer) : null,
                    ),
                  if (current.loading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Looking for mutual follows…',
                        style: TextStyle(color: VimiColors.muted, fontSize: 13),
                      ),
                    ),
                  if (current.error != null)
                    ErrorNote(
                      readableError(current.error!),
                      onRetry: current.retry,
                    ),
                  if (current.loaded &&
                      current.hasMore &&
                      current.error == null &&
                      !current.loading)
                    Align(
                      alignment: Alignment.center,
                      child: VIconButton(
                        Glyph.more,
                        label: 'Check more follows',
                        onPressed: current.loadMore,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

Future<CursorPage<Dancer>> _mutualPage(
  DanceRepository repo,
  String owner,
  TimelineCursor? cursor,
) async {
  final following = await repo.relationPage(
    owner,
    followers: false,
    cursor: cursor,
  );
  if (following.items.isEmpty) return following;
  // The reverse look-up covers only this page and uses the same RLS as follows.
  final reverse = jsonRows(
    await repo.client
        .from('follows')
        .select('follower_id')
        .eq('following_id', owner)
        .inFilter(
          'follower_id',
          following.items.map((dancer) => dancer.id).toList(),
        ),
  );
  final mutualIds = reverse.map((row) => row['follower_id'] as String).toSet();
  final items = <Dancer>[];
  final cursors = <TimelineCursor>[];
  for (final (index, dancer) in following.items.indexed) {
    if (mutualIds.contains(dancer.id)) {
      items.add(dancer);
      cursors.add(following.cursors[index]);
    }
  }
  return CursorPage(
    items,
    next: following.next,
    hasMore: following.hasMore,
    cursors: cursors,
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.peer});
  final Dancer peer;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const _messageLimit = 2000;

  final input = TextEditingController();
  final scroll = ScrollController();
  late CursorPager<Json> history;
  bool allowed = false, busy = false, loading = true, started = false;
  bool planning = false;
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
    if (!allowed || busy || planning || input.text.trim().isEmpty) return;
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
          if (mounted && scroll.hasClients) scroll.jumpTo(0);
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> planRehearsal() async {
    final app = VimiScope.of(context);
    final repo = app.repo;
    final route = ModalRoute.of(context);
    final peer = widget.peer.id;
    bool isSameThread() =>
        mounted &&
        app.signedIn &&
        owner == app.account &&
        app.repo == repo &&
        widget.peer.id == peer;

    if (planning ||
        busy ||
        !allowed ||
        repo == null ||
        !isSameThread() ||
        route?.isCurrent != true) {
      return;
    }
    final draft = input.text;
    final separator = draft.isEmpty ? '' : '\n\n';
    FocusScope.of(context).unfocus();
    setState(() => planning = true);
    try {
      final invitation = await showModalBottomSheet<String>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RehearsalInviteSheet(
          charactersLeft: _messageLimit - draft.runes.length - separator.length,
          checkPermission: () async {
            final canMessage = await repo.canMessage(peer);
            if (!isSameThread()) return false;
            if (allowed != canMessage) setState(() => allowed = canMessage);
            return canMessage;
          },
        ),
      );
      if (invitation == null || !isSameThread() || route?.isCurrent != true) {
        return;
      }
      if (!allowed) {
        feedback(context, 'Messaging is currently unavailable in this chat.');
        return;
      }
      if (input.text != draft) {
        feedback(context, 'Your draft changed. Open the invitation again.');
        return;
      }
      final next = '$draft$separator$invitation';
      input.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      saveDraft(next);
    } catch (e) {
      if (isSameThread() && route?.isCurrent == true) {
        feedback(context, readableError(e));
      }
    } finally {
      if (mounted) setState(() => planning = false);
    }
  }

  void startCall(DirectCalls calls, {required bool video}) {
    if (!allowed) return;
    FocusScope.of(context).unfocus();
    if (!calls.start(widget.peer, video: video)) {
      feedback(context, 'Calling is currently unavailable.');
    }
  }

  Future<void> conversationActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: SurfacePanel(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (allowed)
                VActionRow(
                  'Invite to practice',
                  glyph: Glyph.clock,
                  onPressed: () => Navigator.pop(sheetContext, 'practice'),
                ),
              VActionRow(
                'Refresh conversation',
                glyph: Glyph.refresh,
                onPressed: () => Navigator.pop(sheetContext, 'refresh'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (action == 'practice') await planRehearsal();
    if (action == 'refresh') await load();
  }

  void saveDraft(String text) {
    final clientId = const Uuid().v4();
    nonce = clientId;
    if (draftError != null) setState(() => draftError = null);
    unawaited(
      draftStore
          .writeDraft(storedDraftKey, {'body': text, 'client_id': clientId})
          .catchError((Object e) {
            if (mounted && nonce == clientId) {
              setState(() => draftError = readableError(e));
            }
          }),
    );
  }

  @override
  void dispose() {
    history.dispose();
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final calls = DirectCallScope.maybeOf(context);
    final peer = widget.peer;
    final canUseThread = app.signedIn && app.account == owner;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: NeonBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Row(
                      children: [
                        VIconButton(
                          Glyph.back,
                          label: 'Go back',
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        if (canUseThread)
                          Expanded(
                            child: Tooltip(
                              message: 'Open dancer profile',
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: VimiColors.ink,
                                  padding: const EdgeInsets.fromLTRB(
                                    6,
                                    6,
                                    10,
                                    6,
                                  ),
                                  minimumSize: const Size(48, 48),
                                  alignment: Alignment.centerLeft,
                                ),
                                onPressed: () =>
                                    openPage(context, DancerPage(id: peer.id)),
                                child: Row(
                                  children: [
                                    SignedAvatar(peer, size: 36),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        peer.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (canUseThread && calls != null) ...[
                          VIconButton(
                            Glyph.phone,
                            label: 'Voice call',
                            color: VimiColors.cyan,
                            onPressed: allowed && !planning
                                ? () => startCall(calls, video: false)
                                : null,
                          ),
                          VIconButton(
                            Glyph.video,
                            label: 'Video call',
                            color: VimiColors.cyan,
                            onPressed: allowed && !planning
                                ? () => startCall(calls, video: true)
                                : null,
                          ),
                        ],
                        if (canUseThread)
                          VIconButton(
                            Glyph.more,
                            label: 'Conversation actions',
                            color: VimiColors.muted,
                            onPressed: conversationActions,
                          ),
                      ],
                    ),
                  ),
                  if (canUseThread) ...[
                    const Divider(height: 1, color: VimiColors.tonal),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: history,
                        builder: (context, _) => ListView(
                          controller: scroll,
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            if (error != null) ErrorNote(error!, onRetry: load),
                            if (draftError != null) ErrorNote(draftError!),
                            if (!allowed && !loading && error == null)
                              const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Messages and calls are available between mutual follows without a block.',
                                  style: _chatMeta,
                                ),
                              ),
                            if (history.loaded &&
                                history.items.isEmpty &&
                                history.error == null &&
                                allowed)
                              const Padding(
                                padding: EdgeInsets.all(14),
                                child: Text(
                                  'Invite them to practice or ask about a routine.',
                                  textAlign: TextAlign.center,
                                  style: _chatMeta,
                                ),
                              ),
                            for (var i = 0; i < history.items.length; i++)
                              _message(context, history.items, i),
                            PageFooter(
                              pager: history,
                              moreLabel: 'Earlier messages',
                              loadingLabel: 'Opening your conversation…',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: VimiColors.tonal),
                    _composer(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _chatMeta = TextStyle(
    color: VimiColors.muted,
    fontSize: 12,
    height: 1.35,
  );

  Widget _message(BuildContext context, List<Json> rows, int index) {
    final row = rows[index];
    final sentByMe = row['sender_id'] == owner;
    final time = DateTime.parse(row['created_at'] as String).toLocal();
    final startsDay =
        index == rows.length - 1 ||
        !DateUtils.isSameDay(
          time,
          DateTime.parse(rows[index + 1]['created_at'] as String).toLocal(),
        );
    final showPeer =
        !sentByMe &&
        (index == 0 ||
            rows[index - 1]['sender_id'] != row['sender_id'] ||
            !DateUtils.isSameDay(
              time,
              DateTime.parse(rows[index - 1]['created_at'] as String).toLocal(),
            ));
    return Column(
      key: ValueKey(row['id']),
      children: [
        if (startsDay)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Expanded(child: Divider(color: VimiColors.tonal)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(displayDate(time), style: _chatMeta),
                ),
                const Expanded(child: Divider(color: VimiColors.tonal)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            mainAxisAlignment: sentByMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!sentByMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 18),
                  child: SizedBox(
                    width: 24,
                    child: showPeer
                        ? ExcludeSemantics(
                            child: SignedAvatar(widget.peer, size: 24),
                          )
                        : null,
                  ),
                )
              else
                const SizedBox(width: 54),
              Flexible(
                child: Column(
                  crossAxisAlignment: sentByMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: sentByMe ? VimiColors.tonal : VimiColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(sentByMe ? 16 : 5),
                          bottomRight: Radius.circular(sentByMe ? 5 : 16),
                        ),
                        image: sentByMe
                            ? const DecorationImage(
                                image: AssetImage(
                                  'assets/ui/neon-spectrum.webp',
                                ),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Color(0xDB322143),
                                  BlendMode.srcATop,
                                ),
                              )
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Text(
                          row['body'] as String,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 3, 2, 0),
                      child: Wrap(
                        alignment: sentByMe
                            ? WrapAlignment.end
                            : WrapAlignment.start,
                        children: [
                          Text(
                            MaterialLocalizations.of(context).formatTimeOfDay(
                              TimeOfDay.fromDateTime(time),
                              alwaysUse24HourFormat:
                                  MediaQuery.alwaysUse24HourFormatOf(context),
                            ),
                            style: _chatMeta,
                          ),
                          if (sentByMe)
                            Text(
                              row['read_at'] != null ? ' · Read' : ' · Sent',
                              style: _chatMeta.copyWith(
                                color: row['read_at'] != null
                                    ? VimiColors.cyan
                                    : VimiColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!sentByMe)
                VIconButton(
                  Glyph.more,
                  label: 'Report message',
                  color: VimiColors.muted,
                  onPressed: () =>
                      reportContent(context, 'message', row['id'] as String),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _composer() {
    const inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: VimiColors.tonal),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: input,
              enabled: !busy && !planning,
              minLines: 1,
              maxLines: 3,
              maxLength: _messageLimit,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(
                labelText: 'Your message',
                floatingLabelBehavior: FloatingLabelBehavior.never,
                counterText: '',
                isDense: true,
                enabledBorder: inputBorder,
                disabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: const BorderSide(color: VimiColors.violet),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              onChanged: saveDraft,
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: input,
            builder: (_, value, child) {
              final canSend =
                  allowed && !busy && !planning && value.text.trim().isNotEmpty;
              return VIconButton(
                Glyph.send,
                label: busy ? 'Sending message' : 'Send message',
                busy: busy,
                primary: canSend,
                filled: true,
                color: VimiColors.cyan,
                onPressed: canSend ? send : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RehearsalInviteSheet extends StatefulWidget {
  const _RehearsalInviteSheet({
    required this.charactersLeft,
    required this.checkPermission,
  });

  final int charactersLeft;
  final Future<bool> Function() checkPermission;

  @override
  State<_RehearsalInviteSheet> createState() => _RehearsalInviteSheetState();
}

class _RehearsalInviteSheetState extends State<_RehearsalInviteSheet> {
  final routine = TextEditingController();
  final plan = TextEditingController();
  bool checking = false;
  String? error;

  @override
  void dispose() {
    plan.dispose();
    routine.dispose();
    super.dispose();
  }

  Future<void> addToDraft() async {
    if (checking) return;
    final title = routine.text.trim();
    final detail = plan.text.trim();
    if (title.isEmpty || detail.isEmpty) {
      setState(() => error = 'Add a routine and a proposed time or note.');
      return;
    }
    final invitation = 'Want to rehearse $title together?\n$detail';
    if (invitation.runes.length > widget.charactersLeft) {
      setState(
        () =>
            error = 'Shorten your chat draft to make room for this invitation.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      checking = true;
      error = null;
    });
    try {
      final allowed = await widget.checkPermission();
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      if (allowed) {
        Navigator.pop(context, invitation);
      } else {
        setState(
          () => error = 'Messaging is currently unavailable in this chat.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: SurfacePanel(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const VIcon(Glyph.clock, size: 20, color: VimiColors.cyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Invite to practice',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  VIconButton(
                    Glyph.close,
                    label: 'Close invitation',
                    color: VimiColors.muted,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              VField(
                'Routine or song',
                controller: routine,
                maxLength: 80,
                enabled: !checking,
              ),
              VField(
                'Proposed time or practice note',
                controller: plan,
                lines: 2,
                maxLength: 240,
                enabled: !checking,
              ),
              if (error != null) ...[
                ErrorNote(error!),
                const SizedBox(height: 8),
              ],
              VButton('Add to draft', busy: checking, onPressed: addToDraft),
            ],
          ),
        ),
      ),
    ),
  );
}
