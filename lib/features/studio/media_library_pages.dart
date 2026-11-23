import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/local_studio.dart';
import '../../core/media_library.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../design/vimi_ui.dart';
import '../../design/library_image.dart';
import '../messages/inbox_pages.dart' show ChatPage, startMemberCall;
import '../profile/help_pages.dart';
import 'rehearsal_player.dart';
import 'studio_clip_credit.dart';

class _Catalog extends StatefulWidget {
  const _Catalog({required this.builder});
  final Widget Function(BuildContext, MediaLibrary) builder;
  @override
  State<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<_Catalog> {
  late Future<MediaLibrary> future = MediaLibrary.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<MediaLibrary>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorNote(
            'The library could not be opened.',
            onRetry: () => setState(() => future = MediaLibrary.load()),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Opening your library…', style: _libraryMetadata),
          ),
        );
      }
      return widget.builder(context, snapshot.data!);
    },
  );
}

const _libraryMetadata = TextStyle(fontSize: 12, color: VimiColors.muted);

class RehearsalShelf extends StatelessWidget {
  const RehearsalShelf({super.key, required this.practiceBuilder});
  final Widget Function(LibraryClip) practiceBuilder;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Rehearsal cuts',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          VIconButton(
            Glyph.save,
            label: 'Saved clips',
            color: VimiColors.violet,
            onPressed: () => openPage(
              context,
              MediaLibraryPage(
                practiceBuilder: practiceBuilder,
                showSaved: true,
              ),
            ),
          ),
          VIconButton(
            Glyph.library,
            label: 'Dance video library',
            color: VimiColors.cyan,
            onPressed: () => openPage(
              context,
              MediaLibraryPage(practiceBuilder: practiceBuilder),
            ),
          ),
        ],
      ),
      SizedBox(
        height: 218,
        child: _Catalog(
          builder: (context, library) => ListView.separated(
            primary: false,
            scrollDirection: Axis.horizontal,
            itemCount: library.clips.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final clip = library.clips[index];
              return SizedBox(
                width: 146,
                child: LibraryClipTile(
                  clip: clip,
                  onTap: () => openPage(
                    context,
                    ClipLibraryDetail(
                      clip: clip,
                      practiceBuilder: practiceBuilder,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}

class MediaLibraryPage extends StatefulWidget {
  const MediaLibraryPage({
    super.key,
    required this.practiceBuilder,
    this.showSaved = false,
  });

  final Widget Function(LibraryClip) practiceBuilder;
  final bool showSaved;
  @override
  State<MediaLibraryPage> createState() => _MediaLibraryPageState();
}

class _MediaLibraryPageState extends State<MediaLibraryPage> {
  late String filter = widget.showSaved ? 'Saved' : 'All';
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final saved = app.studio.savedLibraryClips(app.account);
    return VPage(
      title: 'Dance video library',
      child: _Catalog(
        builder: (context, library) {
          final clips = library.clips
              .where(
                (clip) => switch (filter) {
                  'All' => true,
                  'Saved' => saved.contains(clip.id),
                  _ => clip.category == filter,
                },
              )
              .toList();
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final category in const [
                              'All',
                              'Solo',
                              'Duets',
                              'Groups',
                              'Saved',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _LibraryFilter(
                                  label: category,
                                  selected: category == filter,
                                  onTap: () =>
                                      setState(() => filter = category),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${clips.length} ${clips.length == 1 ? 'clip' : 'clips'}',
                        style: _libraryMetadata,
                      ),
                    ],
                  ),
                ),
              ),
              if (clips.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: SurfacePanel(
                      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                      child: Row(
                        children: [
                          const VIcon(
                            Glyph.save,
                            size: 20,
                            color: VimiColors.violet,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              filter == 'Saved'
                                  ? 'No saved clips yet'
                                  : 'No clips in this category',
                            ),
                          ),
                          VIconButton(
                            Glyph.library,
                            label: 'Show all clips',
                            color: VimiColors.cyan,
                            onPressed: () => setState(() => filter = 'All'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid.builder(
                    itemCount: clips.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 236,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: .73,
                        ),
                    itemBuilder: (context, index) {
                      final clip = clips[index];
                      return LibraryClipTile(
                        clip: clip,
                        saved: saved.contains(clip.id),
                        onTap: () async {
                          await openPage(
                            context,
                            ClipLibraryDetail(
                              clip: clip,
                              practiceBuilder: widget.practiceBuilder,
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class StudioCreatorProfilePage extends StatefulWidget {
  const StudioCreatorProfilePage({
    super.key,
    required this.clip,
    required this.practiceBuilder,
  });

  final LibraryClip clip;
  final Widget Function(LibraryClip) practiceBuilder;

  @override
  State<StudioCreatorProfilePage> createState() =>
      _StudioCreatorProfilePageState();
}

class _StudioCreatorProfilePageState extends State<StudioCreatorProfilePage> {
  bool _updating = false;
  bool _checkingCall = false;

  Future<void> _openClip() async {
    await openPage(
      context,
      ClipLibraryDetail(
        clip: widget.clip,
        practiceBuilder: widget.practiceBuilder,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openChat() async {
    if (ModalRoute.isCurrentOf(context) != true) return;
    await openPage(context, _StudioCreatorChatPage(clip: widget.clip));
  }

  Future<void> _callCreator({required bool video}) async {
    final app = VimiScope.of(context);
    if (!app.signedIn || _checkingCall || _updating) return;
    final owner = app.account;
    bool canContinue() =>
        mounted &&
        app.signedIn &&
        app.account == owner &&
        ModalRoute.isCurrentOf(context) == true;
    setState(() => _checkingCall = true);
    try {
      final member = await _studioMember(app, widget.clip);
      if (!canContinue()) return;
      if (member == null) {
        feedback(
          context,
          'Calls require mutual follows between members. This Studio profile has no available member account.',
        );
        return;
      }
      await startMemberCall(context, member, video: video);
    } catch (error) {
      if (canContinue()) feedback(context, readableError(error));
    } finally {
      if (mounted) setState(() => _checkingCall = false);
    }
  }

  Future<void> _setPreference(StudioCreatorPreference preference) async {
    final app = VimiScope.of(context);
    if (_updating || _checkingCall || !app.signedIn) return;
    final owner = app.account;
    final clip = widget.clip;
    final hiding = preference == StudioCreatorPreference.hidden;
    setState(() => _updating = true);
    try {
      if (hiding &&
          !await confirmAction(
            context,
            title: 'Hide ${StudioClipCredit.forClip(clip).name}?',
            body:
                'Their covers and profile will be hidden from Floor and Dancers on this device. This also removes the follow. You can show them again in Settings.',
            action: 'Hide creator',
          )) {
        return;
      }
      if (!mounted || !app.signedIn || app.account != owner) return;
      await app.studio.setStudioCreatorPreference(owner, clip.id, preference);
      if (!mounted || !app.signedIn || app.account != owner) return;
      app.changed();
      if (hiding) {
        feedback(context, 'Creator hidden on this device.');
        if (ModalRoute.isCurrentOf(context) == true) {
          await Navigator.maybePop(context);
        }
      } else if (preference == StudioCreatorPreference.following) {
        feedback(context, 'Added to Following on this device.');
      }
    } catch (error) {
      if (mounted && app.account == owner) {
        feedback(context, readableError(error));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final clip = widget.clip;
    final credit = StudioClipCredit.forClip(clip);
    final preference = app.studio.studioCreatorPreference(app.account, clip.id);
    final following = preference == StudioCreatorPreference.following;
    final hidden = preference == StudioCreatorPreference.hidden;
    return VPage(
      title: 'Creator profile',
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SurfacePanel(
                illuminated: true,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StudioClipAvatar(clip: clip, size: 72),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  credit.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                credit.handle,
                                style: const TextStyle(color: VimiColors.cyan),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Studio editorial profile',
                                style: _libraryMetadata,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(credit.bio),
                    if (app.signedIn) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (!hidden)
                            VButton(
                              following ? 'Following' : 'Follow',
                              glyph: following ? Glyph.check : Glyph.add,
                              tonal: following,
                              onPressed: _updating || _checkingCall
                                  ? null
                                  : () => _setPreference(
                                      following
                                          ? StudioCreatorPreference.none
                                          : StudioCreatorPreference.following,
                                    ),
                            ),
                          VButton(
                            hidden ? 'Show creator' : 'Hide creator',
                            glyph: hidden ? Glyph.check : Glyph.block,
                            quiet: true,
                            onPressed: _updating || _checkingCall
                                ? null
                                : () => _setPreference(
                                    hidden
                                        ? StudioCreatorPreference.none
                                        : StudioCreatorPreference.hidden,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 12, color: VimiColors.tonal),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _contactButton('Chat', Glyph.inbox, _openChat),
                          _contactButton(
                            'Voice call',
                            Glyph.phone,
                            () => _callCreator(video: false),
                          ),
                          _contactButton(
                            'Video call',
                            Glyph.video,
                            () => _callCreator(video: true),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
                child: Semantics(
                  header: true,
                  child: Text(
                    'Cover',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 224,
                  maxHeight: 360,
                ),
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: LibraryClipTile(
                    clip: clip,
                    saved: app.studio
                        .savedLibraryClips(app.account)
                        .contains(clip.id),
                    onTap: _openClip,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactButton(String label, Glyph glyph, VoidCallback onPressed) =>
      Expanded(
        child: TextButton(
          onPressed: _updating || _checkingCall ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: VimiColors.ink,
            minimumSize: const Size(48, 56),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VIcon(glyph, size: 22, color: VimiColors.cyan),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

Future<Dancer?> _studioMember(AppController app, LibraryClip clip) async {
  final repo = app.repo;
  if (!app.signedIn || repo == null) return null;
  final stats = await repo.libraryClipStats().timeout(
    const Duration(seconds: 10),
  );
  return stats[clip.id]?.author;
}

class _StudioCreatorChatPage extends StatefulWidget {
  const _StudioCreatorChatPage({required this.clip});

  final LibraryClip clip;

  @override
  State<_StudioCreatorChatPage> createState() => _StudioCreatorChatPageState();
}

class _StudioCreatorChatPageState extends State<_StudioCreatorChatPage> {
  Future<Dancer?>? _member;
  String? _owner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    final owner = app.signedIn ? app.account : null;
    if (_owner != owner) {
      _owner = owner;
      _member = owner == null ? null : _studioMember(app, widget.clip);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Dancer?>(
    key: ValueKey(_owner),
    future: _member,
    builder: (context, snapshot) {
      if (snapshot.data case final member?) return ChatPage(peer: member);
      final credit = StudioClipCredit.forClip(widget.clip);
      return VPage(
        title: credit.name,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: StudioClipAvatar(clip: widget.clip, size: 56),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Text('Opening chat…', style: _libraryMetadata)
            else if (snapshot.hasError)
              ErrorNote(
                readableError(snapshot.error!),
                onRetry: () {
                  final app = VimiScope.of(context);
                  setState(() => _member = _studioMember(app, widget.clip));
                },
              )
            else
              const EmptyNote(
                'Messaging unavailable',
                'This Studio profile has no member account available for messages.',
              ),
          ],
        ),
      );
    },
  );
}

class _LibraryFilter extends StatelessWidget {
  const _LibraryFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected ? VimiColors.cyan : VimiColors.muted,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
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

class LibraryClipTile extends StatelessWidget {
  const LibraryClipTile({
    super.key,
    required this.clip,
    required this.onTap,
    this.saved = false,
  });
  final LibraryClip clip;
  final VoidCallback onTap;
  final bool saved;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Play ${clip.title}',
    child: Material(
      color: VimiColors.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LibraryImage(
                    clip.thumbnail,
                    compact: true,
                    cacheWidth: 320,
                    alignment: const Alignment(0, -.25),
                  ),
                  Positioned(
                    right: 7,
                    bottom: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: VimiColors.background.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const VIcon(
                              Glyph.play,
                              color: VimiColors.cyan,
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              clip.durationLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clip.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clip.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _libraryMetadata,
                        ),
                      ),
                      if (saved)
                        const VIcon(
                          Glyph.save,
                          color: VimiColors.violet,
                          size: 13,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ClipLibraryDetail extends StatefulWidget {
  const ClipLibraryDetail({
    super.key,
    required this.clip,
    required this.practiceBuilder,
  });
  final LibraryClip clip;
  final Widget Function(LibraryClip) practiceBuilder;
  @override
  State<ClipLibraryDetail> createState() => _ClipLibraryDetailState();
}

class _ClipLibraryDetailState extends State<ClipLibraryDetail> {
  bool busy = false;
  Future<void> toggleSaved() async {
    if (busy) return;
    final app = VimiScope.of(context), owner = app.account;
    setState(() => busy = true);
    try {
      await app.studio.toggleLibraryClip(owner, widget.clip.id);
    } catch (e) {
      if (mounted && app.account == owner) feedback(context, readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context), clip = widget.clip;
    final saved = app.studio.savedLibraryClips(app.account).contains(clip.id);
    return VPage(
      title: clip.title,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
        children: [
          RehearsalPlayer(source: clip.source, practice: true),
          const SizedBox(height: 8),
          SurfacePanel(
            padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${clip.category} · ${clip.durationLabel}\n${clip.hasAudio ? 'Audio available' : 'Silent clip'}',
                    style: _libraryMetadata,
                  ),
                ),
                VIconButton(
                  Glyph.add,
                  label: 'Add to a practice note',
                  color: VimiColors.cyan,
                  onPressed: () =>
                      openPage(context, widget.practiceBuilder(clip)),
                ),
                VIconButton(
                  Glyph.save,
                  label: saved ? 'Saved · tap to remove' : 'Save clip',
                  selected: saved,
                  color: VimiColors.violet,
                  busy: busy,
                  onPressed: toggleSaved,
                ),
                VIconButton(
                  Glyph.report,
                  label: 'Report a concern',
                  color: VimiColors.muted,
                  onPressed: () => openPage(
                    context,
                    HelpCenterPage(libraryItem: '${clip.id} · ${clip.title}'),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Text(
              'Practice reference · Supplied by the publisher',
              style: _libraryMetadata,
            ),
          ),
        ],
      ),
    );
  }
}

class PortraitPickerPage extends StatelessWidget {
  const PortraitPickerPage({super.key, this.browseOnly = false});
  final bool browseOnly;

  @override
  Widget build(BuildContext context) => VPage(
    title: browseOnly ? 'Photo library' : 'Profile image library',
    child: _Catalog(
      builder: (context, library) => CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Explore ${library.portraits.length} images.',
                style: _libraryMetadata,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid.builder(
              itemCount: library.portraits.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 138,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: .8,
              ),
              itemBuilder: (context, index) {
                final portrait = library.portraits[index];
                return Tooltip(
                  message: portrait.title,
                  child: Material(
                    color: VimiColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        final choice = await openPage<LibraryPortrait>(
                          context,
                          PortraitPreviewPage(
                            portrait: portrait,
                            browseOnly: browseOnly,
                          ),
                        );
                        if (!browseOnly && choice != null && context.mounted) {
                          Navigator.pop(context, choice);
                        }
                      },
                      child: LibraryImage(
                        portrait.thumbnail,
                        compact: true,
                        cacheWidth: 280,
                        label: portrait.title,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class PortraitPreviewPage extends StatelessWidget {
  const PortraitPreviewPage({
    super.key,
    required this.portrait,
    this.browseOnly = false,
  });
  final LibraryPortrait portrait;
  final bool browseOnly;

  @override
  Widget build(BuildContext context) => VPage(
    title: portrait.title,
    actions: [
      VIconButton(
        Glyph.report,
        label: 'Report a concern',
        color: VimiColors.muted,
        onPressed: () => openPage(
          context,
          HelpCenterPage(libraryItem: '${portrait.id} · ${portrait.title}'),
        ),
      ),
    ],
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * (browseOnly ? .69 : .52),
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: LibraryImage(
              portrait.url,
              fit: BoxFit.contain,
              label: portrait.title,
            ),
          ),
        ),
        if (browseOnly)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Pinch to zoom',
              textAlign: TextAlign.center,
              style: _libraryMetadata,
            ),
          )
        else ...[
          const SizedBox(height: 12),
          SurfacePanel(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            child: Row(
              children: [
                ClipOval(
                  child: LibraryImage(
                    portrait.url,
                    compact: true,
                    width: 52,
                    height: 52,
                    cacheWidth: 156,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avatar crop',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Uploads when you save your profile.',
                        style: _libraryMetadata,
                      ),
                    ],
                  ),
                ),
                VIconButton(
                  Glyph.check,
                  label: 'Use this image',
                  color: VimiColors.cyan,
                  onPressed: () => Navigator.pop(context, portrait),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
