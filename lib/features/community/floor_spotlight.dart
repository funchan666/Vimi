import 'package:flutter/material.dart';
import '../../core/media_library.dart';
import '../../design/library_image.dart';
import '../../design/vimi_ui.dart';
import '../studio/media_library_pages.dart';
import '../studio/studio_pages.dart';

class FloorSpotlight extends StatefulWidget {
  const FloorSpotlight({
    super.key,
    required this.onFind,
    required this.onPost,
    required this.onChallenges,
  });

  final VoidCallback onFind, onPost, onChallenges;

  @override
  State<FloorSpotlight> createState() => _FloorSpotlightState();
}

class _FloorSpotlightState extends State<FloorSpotlight> {
  late Future<MediaLibrary> catalog = MediaLibrary.load();

  void showClip(LibraryClip clip) => openPage(
    context,
    ClipLibraryDetail(
      clip: clip,
      practiceBuilder: (clip) => PracticeEditor(initialClip: clip),
    ),
  );

  void showClips() => openPage(
    context,
    MediaLibraryPage(
      practiceBuilder: (clip) => PracticeEditor(initialClip: clip),
    ),
  );

  void showPhotos() =>
      openPage(context, const PortraitPickerPage(browseOnly: true));

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _railHeader('Cover picks', [
        VIconButton(
          Glyph.search,
          label: 'Find dancers',
          onPressed: widget.onFind,
        ),
        VIconButton(
          Glyph.add,
          label: 'Post',
          primary: true,
          onPressed: widget.onPost,
        ),
      ]),
      const SizedBox(height: 4),
      FutureBuilder<MediaLibrary>(
        future: catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorNote(
              'Couldn’t open the cover library.',
              onRetry: () => setState(() => catalog = MediaLibrary.load()),
            );
          }
          final library = snapshot.data;
          if (library == null) {
            return const SizedBox(
              height: 220,
              child: SurfacePanel(
                child: Center(
                  child: VIcon(Glyph.video, color: VimiColors.muted),
                ),
              ),
            );
          }
          final portraits = library.portraits;
          if (library.clips.isEmpty || portraits.isEmpty) {
            return ErrorNote(
              'The cover library is empty.',
              onRetry: () => setState(() => catalog = MediaLibrary.load()),
            );
          }
          final feature = library.clips.firstWhere(
            (clip) => clip.id == 'holiday-duet',
            orElse: () => library.clips.first,
          );
          final challenge = library.clips.firstWhere(
            (clip) => clip.id == 'room-formation',
            orElse: () => feature,
          );
          const featuredPhotoIds = [
            'portrait-015',
            'portrait-021',
            'portrait-010',
          ];
          final photoIndex = {for (final photo in portraits) photo.id: photo};
          final photoWall = [
            for (final id in featuredPhotoIds)
              if (photoIndex[id] case final photo?) photo,
            ...portraits.where((photo) => !featuredPhotoIds.contains(photo.id)),
          ];
          final portraitCover = photoWall.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, box) => SizedBox(
                  height: (box.maxWidth * .79).clamp(216.0, 310.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _CoverFrame(
                          image: feature.thumbnail,
                          title: feature.title,
                          label: 'Play ${feature.title}',
                          glyph: Glyph.play,
                          onTap: () => showClip(feature),
                          feature: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _CoverFrame(
                                image: portraitCover.thumbnail,
                                title: 'Photo wall',
                                label: 'Browse dance portraits',
                                glyph: Glyph.photo,
                                onTap: showPhotos,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _CoverFrame(
                                image: challenge.thumbnail,
                                title: 'Challenges',
                                label: 'Challenges',
                                glyph: Glyph.next,
                                onTap: widget.onChallenges,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _railHeader('Watch a cover', [
                VIconButton(
                  Glyph.library,
                  label: 'Open dance video library',
                  onPressed: showClips,
                ),
              ]),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: library.clips.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final clip = library.clips[index];
                    return SizedBox(
                      width: 114,
                      child: _CoverFrame(
                        image: clip.thumbnail,
                        title: clip.title,
                        label: 'Play ${clip.title}',
                        glyph: Glyph.play,
                        onTap: () => showClip(clip),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _railHeader('Photo picks', [
                VIconButton(
                  Glyph.library,
                  label: 'Open all ${portraits.length} photos',
                  onPressed: showPhotos,
                ),
              ]),
              SizedBox(
                height: 85,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photoWall.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final portrait = photoWall[index];
                    return SizedBox(
                      width: 72,
                      child: _CoverFrame(
                        image: portrait.thumbnail,
                        label: 'View ${portrait.title}',
                        onTap: () => openPage(
                          context,
                          PortraitPreviewPage(
                            portrait: portrait,
                            browseOnly: true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ],
  );

  Widget _railHeader(String label, List<Widget> actions) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      ...actions,
    ],
  );
}

class _CoverFrame extends StatelessWidget {
  const _CoverFrame({
    required this.image,
    required this.label,
    required this.onTap,
    this.title,
    this.glyph,
    this.feature = false,
  });

  final String image, label;
  final String? title;
  final Glyph? glyph;
  final VoidCallback onTap;
  final bool feature;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(feature ? 20 : 14),
      child: Material(
        color: VimiColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              LibraryImage(
                image,
                compact: true,
                cacheWidth: feature ? 420 : 240,
              ),
              if (title case final title?)
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xF20C0716)],
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        feature ? 13 : 9,
                        20,
                        8,
                        feature ? 12 : 8,
                      ),
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: feature ? 18 : 13,
                          height: 1.13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              if (glyph case final glyph?)
                Positioned(
                  right: 8,
                  top: 8,
                  child: IgnorePointer(
                    child: SurfacePanel(
                      illuminated: feature,
                      padding: EdgeInsets.all(feature ? 9 : 6),
                      child: VIcon(glyph, size: feature ? 19 : 15),
                    ),
                  ),
                ),
              if (feature)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 2,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/ui/neon-spectrum.webp',
                      fit: BoxFit.fill,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
