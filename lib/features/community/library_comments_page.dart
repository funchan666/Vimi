import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/media_library.dart';
import '../../core/models.dart';
import '../../core/pagination.dart';
import '../../design/library_image.dart';
import '../../design/page_footer.dart';
import '../../design/vimi_ui.dart';
import '../auth/auth_pages.dart';
import '../profile/profile_pages.dart';
import 'community_pages.dart';
import 'content_editor.dart';

enum _CommentAction { report, edit, delete }

class LibraryCommentsPage extends StatefulWidget {
  const LibraryCommentsPage({super.key, required this.clip});

  final LibraryClip clip;

  @override
  State<LibraryCommentsPage> createState() => _LibraryCommentsPageState();
}

class _LibraryCommentsPageState extends State<LibraryCommentsPage> {
  static const _maxLength = 1000;
  final _message = TextEditingController();
  CursorPager<Json>? _thread;
  String? _owner, _error, _actingOn;
  String _nonce = const Uuid().v4();
  int _revision = -1;
  bool _sending = false;

  String _draftKey(String owner) => 'comment.v1.$owner.${widget.clip.source}';

  bool _isCurrent(AppController app, CursorPager<Json> thread, String owner) =>
      mounted &&
      identical(_thread, thread) &&
      app.signedIn &&
      app.account == owner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    final owner = app.signedIn ? app.account : null;
    if (owner != _owner) {
      _thread?.dispose();
      _thread = null;
      _owner = owner;
      _revision = -1;
      _error = _actingOn = null;
      _sending = false;
      _nonce = const Uuid().v4();
      _message.clear();
      if (owner != null) {
        final repo = app.repo!;
        _thread = CursorPager(
          fetch: (cursor) =>
              repo.libraryCommentPage(widget.clip.id, cursor: cursor),
          identity: (row) => row['id'] as String,
          isCurrent: () => app.signedIn && app.account == owner,
        );
        try {
          final draft = app.studio.readDraft(_draftKey(owner));
          _message.text = draft?['body'] as String? ?? '';
          _nonce = draft?['client_id'] as String? ?? _nonce;
        } catch (_) {
          _error = 'Your saved draft could not be opened.';
        }
      }
    }
    if (_thread case final pager?) {
      if (_revision != app.revision) {
        _revision = app.revision;
        unawaited(pager.refresh());
      }
    }
  }

  void _saveDraft(String text) {
    final app = VimiScope.of(context);
    final owner = _owner;
    final thread = _thread;
    if (owner == null || thread == null || !_isCurrent(app, thread, owner)) {
      return;
    }
    final nonce = const Uuid().v4();
    setState(() {
      _nonce = nonce;
      _error = null;
    });
    unawaited(
      app.studio
          .writeDraft(_draftKey(owner), {'body': text, 'client_id': nonce})
          .catchError((Object error) {
            if (_isCurrent(app, thread, owner) && _nonce == nonce) {
              setState(() => _error = readableError(error));
            }
          }),
    );
  }

  Future<void> _send() async {
    final app = VimiScope.of(context);
    final owner = _owner;
    final thread = _thread;
    final text = _message.text;
    final body = text.trim();
    if (_sending ||
        body.isEmpty ||
        owner == null ||
        thread == null ||
        !_isCurrent(app, thread, owner)) {
      return;
    }
    if (body.runes.length > _maxLength) {
      setState(() => _error = 'Keep comments to 1,000 characters.');
      return;
    }
    final nonce = _nonce;
    final key = _draftKey(owner);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await app.studio.writeDraft(key, {'body': text, 'client_id': nonce});
      if (!_isCurrent(app, thread, owner)) return;
      await app.repo!.submitLibraryComment(widget.clip.id, body, nonce);
      if (!_isCurrent(app, thread, owner)) return;
      _message.clear();
      _nonce = const Uuid().v4();
      if (ModalRoute.isCurrentOf(context) != false) {
        FocusScope.of(context).unfocus();
        feedback(context, 'Comment submitted for review.');
      }
      unawaited(thread.refresh());
      try {
        await app.studio.removeDraft(key);
      } catch (_) {
        if (_isCurrent(app, thread, owner)) {
          setState(
            () => _error = 'Comment sent. The draft could not be cleared.',
          );
        }
      }
    } catch (error) {
      if (_isCurrent(app, thread, owner)) {
        setState(() => _error = readableError(error));
      }
    } finally {
      if (_isCurrent(app, thread, owner)) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _manageComment(Json row, _CommentAction action) async {
    final app = VimiScope.of(context);
    final owner = _owner;
    final thread = _thread;
    if (_actingOn != null ||
        owner == null ||
        thread == null ||
        !_isCurrent(app, thread, owner)) {
      return;
    }
    final id = row['id'] as String;
    setState(() => _actingOn = id);
    try {
      switch (action) {
        case _CommentAction.report:
          await reportContent(context, 'comment', id);
        case _CommentAction.edit:
          await openPage(
            context,
            EditContentPage(
              kind: 'comment',
              id: id,
              text: row['body'] as String,
            ),
          );
        case _CommentAction.delete:
          final confirmed = await confirmAction(
            context,
            title: 'Delete this comment?',
            body: 'Your comment will be removed.',
            action: 'Delete comment',
          );
          if (!confirmed || !_isCurrent(app, thread, owner)) return;
          await app.repo!.deleteComment(id);
          if (_isCurrent(app, thread, owner)) app.changed();
      }
      if (_isCurrent(app, thread, owner)) {
        _revision = app.revision;
        await thread.refresh();
      }
    } catch (error) {
      if (_isCurrent(app, thread, owner)) {
        feedback(context, readableError(error));
      }
    } finally {
      if (_isCurrent(app, thread, owner)) {
        setState(() => _actingOn = null);
      }
    }
  }

  @override
  void dispose() {
    _thread?.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final thread = _thread;
    return VPage(
      title: 'Comments',
      actions: [
        if (thread != null)
          VIconButton(
            Glyph.refresh,
            label: 'Refresh comments',
            onPressed: thread.refresh,
          ),
      ],
      child: thread == null
          ? Center(
              child: VButton(
                'Sign in to join the discussion',
                onPressed: () =>
                    openPage(context, const AuthPage(signUp: false)),
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: LayoutBuilder(
                  builder: (context, bounds) => Column(
                    children: [
                      Expanded(child: _buildThread(thread, app.account)),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: bounds.maxHeight * .6,
                        ),
                        child: SingleChildScrollView(child: _composer()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildThread(CursorPager<Json> thread, String owner) =>
      AnimatedBuilder(
        animation: thread,
        builder: (context, _) {
          final rows = thread.items;
          return RefreshIndicator(
            color: VimiColors.cyan,
            backgroundColor: VimiColors.surface,
            onRefresh: thread.refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: rows.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) return _ClipHeader(clip: widget.clip);
                if (index == 1) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PageFooter(
                        pager: thread,
                        moreLabel: 'Earlier comments',
                        loadingLabel: 'Opening comments…',
                      ),
                      if (thread.loaded &&
                          !thread.loading &&
                          thread.error == null &&
                          rows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('No comments yet.'),
                        ),
                    ],
                  );
                }
                final row = rows[rows.length - index + 1];
                final id = row['id'] as String;
                return _LibraryComment(
                  key: ValueKey(id),
                  row: row,
                  owner: owner,
                  busy: _actingOn == id,
                  onAction: _actingOn == null
                      ? (action) => _manageComment(row, action)
                      : null,
                );
              },
            ),
          );
        },
      );

  Widget _composer() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error case final error?)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: const TextStyle(color: VimiColors.danger, fontSize: 13),
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _message,
                enabled: !_sending,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 3,
                maxLength: _maxLength,
                decoration: const InputDecoration(
                  labelText: 'Add a comment',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  counterText: '',
                ),
                onChanged: _saveDraft,
              ),
            ),
            const SizedBox(width: 8),
            VIconButton(
              Glyph.send,
              label: 'Submit comment',
              primary: true,
              busy: _sending,
              onPressed: _message.text.trim().isEmpty ? null : _send,
            ),
          ],
        ),
      ],
    ),
  );
}

class _ClipHeader extends StatelessWidget {
  const _ClipHeader({required this.clip});

  final LibraryClip clip;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SurfacePanel(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.square(
              dimension: 52,
              child: LibraryImage(
                clip.thumbnail,
                cacheWidth: 160,
                compact: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clip.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'Studio · Practice reference',
                  style: TextStyle(color: VimiColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _LibraryComment extends StatelessWidget {
  const _LibraryComment({
    super.key,
    required this.row,
    required this.owner,
    required this.busy,
    required this.onAction,
  });

  final Json row;
  final String owner;
  final bool busy;
  final ValueChanged<_CommentAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final author = Dancer.fromJson(jsonMap(row['author']));
    final self = author.id == owner;
    final date = displayDate(DateTime.parse(row['created_at'] as String));
    final metadata = switch (row['status']) {
      'pending' => '$date · In review',
      'rejected' => '$date · Review declined',
      _ => date,
    };
    final action = onAction;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: VimiColors.ink,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  onPressed: () => openPage(context, DancerPage(id: author.id)),
                  child: Row(
                    children: [
                      SignedAvatar(author, size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              author.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              metadata,
                              style: const TextStyle(
                                color: VimiColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (self) ...[
                VIconButton(
                  Glyph.edit,
                  label: 'Edit comment',
                  onPressed: action == null
                      ? null
                      : () => action(_CommentAction.edit),
                ),
                VIconButton(
                  Glyph.delete,
                  label: 'Delete comment',
                  onPressed: action == null
                      ? null
                      : () => action(_CommentAction.delete),
                ),
              ] else
                VIconButton(
                  Glyph.report,
                  label: 'Report comment',
                  onPressed: action == null
                      ? null
                      : () => action(_CommentAction.report),
                  busy: busy,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 44, right: 12, bottom: 8),
            child: Text(row['body'] as String),
          ),
          const Divider(height: 1, color: VimiColors.tonal),
        ],
      ),
    );
  }
}
