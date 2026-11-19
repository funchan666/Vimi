import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/media_library.dart';
import '../../core/dance_repository.dart';
import '../../design/vimi_ui.dart';
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
          padding: const EdgeInsets.all(24),
          child: ErrorNote(
            'The library could not be opened. Please try again.',
            onRetry: () => setState(() => future = MediaLibrary.load()),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: Text('Opening your library…'));
      }
      return widget.builder(context, snapshot.data!);
    },
  );
}

class MediaLibraryPage extends StatefulWidget {
  const MediaLibraryPage({super.key, required this.practiceBuilder});
  final Widget Function(LibraryClip) practiceBuilder;
  @override
  State<MediaLibraryPage> createState() => _MediaLibraryPageState();
}

class _MediaLibraryPageState extends State<MediaLibraryPage> {
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final saved =
        (app.studio.preferences.getStringList(
                  'library-saved.v1.${app.account}',
                ) ??
                [])
            .toSet();
    return VPage(
      title: 'Dance video library',
      child: _Catalog(
        builder: (context, library) {
          final clips = library.clips
              .where(
                (clip) =>
                    filter == 'All' ||
                    (filter == 'Saved'
                        ? saved.contains(clip.id)
                        : clip.category == filter),
              )
              .toList();
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick a take to practice.',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Slow down a take, try it mirrored and keep a note for your next rehearsal. Every clip is available offline.',
                      ),
                      const SizedBox(height: 20),
                      ChoiceStrip(
                        options: const [
                          'All',
                          'Solo',
                          'Duets',
                          'Groups',
                          'Saved',
                        ],
                        value: filter,
                        onChanged: (value) => setState(() => filter = value),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${clips.length} ${clips.length == 1 ? 'clip' : 'clips'}',
                        style: const TextStyle(color: VimiColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              if (clips.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: EmptyNote(
                      'Keep a take for later.',
                      'Open a clip and tap Save clip. Your saved clips stay with this account on this device.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverGrid.builder(
                    itemCount: clips.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                          childAspectRatio: .56,
                        ),
                    itemBuilder: (context, index) {
                      final clip = clips[index];
                      return _LibraryTile(
                        image: clip.thumbnail,
                        title: clip.title,
                        detail:
                            '${clip.category} · ${clip.durationLabel}${saved.contains(clip.id) ? ' · Saved' : ''}',
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
    final app = VimiScope.of(context), owner = VimiScope.of(context).account;
    final prefs = app.studio.preferences, key = 'library-saved.v1.$owner';
    final next = (prefs.getStringList(key) ?? []).toSet();
    if (!next.add(widget.clip.id)) next.remove(widget.clip.id);
    setState(() => busy = true);
    try {
      if (!await prefs.setStringList(key, next.toList())) {
        throw StateError('Your saved clips could not be updated. Try again.');
      }
    } catch (e) {
      if (mounted && app.account == owner) feedback(context, readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context), clip = widget.clip;
    final saved =
        (app.studio.preferences.getStringList(
                  'library-saved.v1.${app.account}',
                ) ??
                [])
            .contains(clip.id);
    return VPage(
      title: clip.title,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          RehearsalPlayer(source: clip.source, practice: true),
          const SizedBox(height: 20),
          Text(
            '${clip.category} · ${clip.durationLabel} · ${clip.hasAudio ? 'Includes audio' : 'Silent clip'}',
            style: const TextStyle(color: VimiColors.muted),
          ),
          const SizedBox(height: 20),
          VButton(
            'Add to a practice note',
            glyph: Glyph.add,
            onPressed: () => openPage(context, widget.practiceBuilder(clip)),
          ),
          VButton(
            saved ? 'Saved · tap to remove' : 'Save clip',
            glyph: Glyph.save,
            quiet: true,
            busy: busy,
            onPressed: toggleSaved,
          ),
          VButton(
            'Report a concern',
            glyph: Glyph.report,
            quiet: true,
            onPressed: () => openPage(
              context,
              HelpCenterPage(libraryItem: '${clip.id} · ${clip.title}'),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Start with one eight-count phrase. Mark the weight changes, try the transition slowly, then write down what you want to improve.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Library performances are reference media. The people shown are not presented as registered Vimi members.',
            style: TextStyle(color: VimiColors.muted),
          ),
        ],
      ),
    );
  }
}

class PortraitPickerPage extends StatelessWidget {
  const PortraitPickerPage({super.key});
  @override
  Widget build(BuildContext context) => VPage(
    title: 'Profile image library',
    child: _Catalog(
      builder: (context, library) => CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find your profile look.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Explore ${library.portraits.length} images. Open one to see the full photo and preview its avatar crop.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Library imagery does not verify anyone’s identity.',
                    style: TextStyle(color: VimiColors.muted),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverGrid.builder(
              itemCount: library.portraits.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: .65,
              ),
              itemBuilder: (context, index) {
                final portrait = library.portraits[index];
                return _LibraryTile(
                  image: portrait.thumbnail,
                  title: portrait.title,
                  detail: 'Preview image',
                  onTap: () async {
                    final choice = await openPage<LibraryPortrait>(
                      context,
                      _PortraitPreview(portrait: portrait),
                    );
                    if (choice != null && context.mounted)
                      Navigator.pop(context, choice);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _PortraitPreview extends StatelessWidget {
  const _PortraitPreview({required this.portrait});
  final LibraryPortrait portrait;
  @override
  Widget build(BuildContext context) => VPage(
    title: portrait.title,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * .52,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.asset(
              portrait.asset,
              fit: BoxFit.contain,
              semanticLabel: portrait.title,
              errorBuilder: (_, _, _) =>
                  const Center(child: Text('This image could not be opened.')),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Pinch to zoom. Your avatar uses the centered crop below.'),
        const SizedBox(height: 16),
        Center(
          child: ClipOval(
            child: Image.asset(
              portrait.asset,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        VButton(
          'Use this image',
          glyph: Glyph.check,
          onPressed: () => Navigator.pop(context, portrait),
        ),
        VButton(
          'Report a concern',
          glyph: Glyph.report,
          quiet: true,
          onPressed: () => openPage(
            context,
            HelpCenterPage(libraryItem: '${portrait.id} · ${portrait.title}'),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'The image uploads when you save your profile. You can change it again before saving.',
        ),
      ],
    ),
  );
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.image,
    required this.title,
    required this.detail,
    required this.onTap,
  });
  final String image, title, detail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Open $title',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: VimiColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  cacheWidth: 320,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) =>
                      const Center(child: Text('Image unavailable')),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VimiColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
