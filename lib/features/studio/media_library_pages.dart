import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/media_library.dart';
import '../../core/dance_repository.dart';
import '../../design/vimi_ui.dart';
import '../../design/library_image.dart';
import '../profile/help_pages.dart';
import 'rehearsal_player.dart';

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

abstract final class StudioPublisher {
  static const name = 'Studio';
}

class StudioPublisherAvatar extends StatelessWidget {
  const StudioPublisherAvatar({
    super.key,
    required this.clip,
    required this.size,
  });

  final LibraryClip clip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: VimiColors.tonal,
      child: Center(
        child: VIcon(Glyph.studio, size: size * .52, color: VimiColors.cyan),
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: Image.network(
          clip.thumbnail,
          fit: BoxFit.cover,
          cacheWidth: 576,
          alignment: const Alignment(0, -.42),
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, synchronous) =>
              frame != null || synchronous ? child : placeholder,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      ),
    );
  }
}

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
  }) : _publisherClip = null;

  const MediaLibraryPage.publisher({
    super.key,
    required LibraryClip clip,
    required this.practiceBuilder,
  }) : showSaved = false,
       _publisherClip = clip;

  final Widget Function(LibraryClip) practiceBuilder;
  final bool showSaved;
  final LibraryClip? _publisherClip;
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
      title: widget._publisherClip == null
          ? 'Dance video library'
          : 'Publisher profile',
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
              if (widget._publisherClip case final clip?)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: _PublisherIdentity(clip: clip),
                  ),
                ),
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

class _PublisherIdentity extends StatelessWidget {
  const _PublisherIdentity({required this.clip});

  final LibraryClip clip;

  @override
  Widget build(BuildContext context) => SurfacePanel(
    illuminated: true,
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        StudioPublisherAvatar(clip: clip, size: 64),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  StudioPublisher.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Official dance library', style: _libraryMetadata),
            ],
          ),
        ),
      ],
    ),
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
