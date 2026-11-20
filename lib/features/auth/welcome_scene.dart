import 'package:flutter/material.dart';
import '../../core/media_library.dart';
import '../../design/library_image.dart';
import '../../design/vimi_ui.dart';

/// Real publisher performances introduce the community without invented activity.
class DanceWelcomeScene extends StatefulWidget {
  const DanceWelcomeScene({
    super.key,
    required this.onJoin,
    required this.onSignIn,
    required this.onExplore,
    required this.onPrivacy,
    required this.onSafety,
    required this.onPreview,
  });
  final VoidCallback onJoin, onSignIn, onExplore, onPrivacy, onSafety;
  final ValueChanged<LibraryClip> onPreview;
  @override
  State<DanceWelcomeScene> createState() => _DanceWelcomeSceneState();
}

class _DanceWelcomeSceneState extends State<DanceWelcomeScene> {
  late Future<MediaLibrary> library = MediaLibrary.load();

  Widget header() => Row(
    children: [
      Expanded(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/ui/neon-mark.webp',
                width: 32,
                height: 32,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'vimi',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
            ),
          ],
        ),
      ),
      _WelcomeLink('Sign in', onPressed: widget.onSignIn, glyph: Glyph.next),
    ],
  );

  Widget introduction(double width) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Meet your\n'),
            const TextSpan(
              text: 'dance crew.',
              style: TextStyle(color: VimiColors.accent),
            ),
          ],
        ),
        style: TextStyle(
          fontSize: width < 340 ? 38 : 44,
          height: 1.04,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.3,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'K-pop covers. New dance friends.',
        style: TextStyle(color: VimiColors.muted, fontSize: 16, height: 1.4),
      ),
    ],
  );

  Widget actions() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _JoinCrewButton(onPressed: widget.onJoin),
      const SizedBox(height: 4),
      Center(
        child: _WelcomeLink(
          'Explore the studio',
          glyph: Glyph.studio,
          onPressed: widget.onExplore,
          muted: true,
        ),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          _WelcomeLink(
            'Privacy Policy',
            onPressed: widget.onPrivacy,
            muted: true,
          ),
          _WelcomeLink('Child safety', onPressed: widget.onSafety, muted: true),
        ],
      ),
    ],
  );

  Widget mosaic(double height) => SizedBox(
    height: height,
    child: FutureBuilder<MediaLibrary>(
      future: library,
      builder: (context, snapshot) {
        final clips = snapshot.data?.clips;
        final group = clips
            ?.where((clip) => clip.id == 'street-style-group')
            .firstOrNull;
        final duet = clips
            ?.where((clip) => clip.id == 'holiday-duet')
            .firstOrNull;
        return LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            return ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -w * .025,
                    top: h * .12,
                    width: w * .55,
                    height: h * .78,
                    child: Transform.rotate(
                      angle: -.10,
                      child: _PerformancePhoto(
                        url: group?.thumbnail,
                        alignment: Alignment.topCenter,
                        label: 'Group covers',
                      ),
                    ),
                  ),
                  Positioned(
                    right: w * .015,
                    top: h * .045,
                    width: w * .59,
                    height: h * .88,
                    child: Transform.rotate(
                      angle: .075,
                      child: _PerformancePhoto(
                        url: duet?.thumbnail,
                        alignment: Alignment.topCenter,
                        label: 'Duet covers',
                        onPreview: duet == null
                            ? null
                            : () => widget.onPreview(duet),
                      ),
                    ),
                  ),
                  if (snapshot.hasError)
                    Align(
                      alignment: Alignment.center,
                      child: VIconButton(
                        Glyph.refresh,
                        label: 'Retry welcome media',
                        filled: true,
                        onPressed: () =>
                            setState(() => library = MediaLibrary.load()),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: NeonBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
            if (box.maxWidth >= 760) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                    child: header(),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28, 8, 12, 20),
                            child: mosaic(
                              (box.maxHeight - 84).clamp(240.0, 740.0),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 32, 32, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                introduction(box.maxWidth * .42),
                                const SizedBox(height: 28),
                                actions(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            final photoHeight = (box.maxHeight * .415 - (scale - 1) * 80).clamp(
              220.0,
              410.0,
            );
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header(),
                      const SizedBox(height: 8),
                      mosaic(photoHeight),
                      const SizedBox(height: 16),
                      introduction(box.maxWidth - 40),
                      const SizedBox(height: 24),
                      actions(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _PerformancePhoto extends StatelessWidget {
  const _PerformancePhoto({
    required this.url,
    required this.alignment,
    required this.label,
    this.onPreview,
  });
  final String? url;
  final Alignment alignment;
  final String label;
  final VoidCallback? onPreview;
  @override
  Widget build(BuildContext context) {
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/ui/neon-spectrum.webp',
            fit: BoxFit.fill,
            excludeFromSemantics: true,
          ),
          Padding(
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/ui/surface-clean.webp',
                    fit: BoxFit.cover,
                    color: VimiColors.tonal,
                    colorBlendMode: BlendMode.srcIn,
                    excludeFromSemantics: true,
                  ),
                  if (url != null)
                    LibraryImage(
                      url!,
                      fit: BoxFit.cover,
                      alignment: alignment,
                      compact: true,
                    ),
                ],
              ),
            ),
          ),
          if (onPreview != null)
            Positioned(
              right: 12,
              bottom: 12,
              width: 48,
              height: 48,
              child: SurfacePanel(
                padding: EdgeInsets.zero,
                child: const Center(child: VIcon(Glyph.play, size: 24)),
              ),
            ),
          Positioned(
            left: 12,
            right: onPreview == null ? 12 : 72,
            bottom: 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SurfacePanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (onPreview == null) return photo;
    return Semantics(
      button: true,
      label: 'Preview a duet',
      onTap: onPreview,
      child: Tooltip(
        message: 'Preview a duet',
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPreview,
            borderRadius: BorderRadius.circular(26),
            child: photo,
          ),
        ),
      ),
    );
  }
}

class _JoinCrewButton extends StatelessWidget {
  const _JoinCrewButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/ui/neon-spectrum.webp',
            fit: BoxFit.fill,
            excludeFromSemantics: true,
          ),
        ),
      ),
      TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: VimiColors.onAccent,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Text(
                'Join the crew',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            VIcon(Glyph.next, color: VimiColors.onAccent, size: 22),
          ],
        ),
      ),
    ],
  );
}

class _WelcomeLink extends StatelessWidget {
  const _WelcomeLink(
    this.label, {
    required this.onPressed,
    this.glyph,
    this.muted = false,
  });
  final String label;
  final VoidCallback onPressed;
  final Glyph? glyph;
  final bool muted;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: muted ? VimiColors.muted : VimiColors.ink,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (glyph == Glyph.studio) ...[
          VIcon(glyph!, size: 18, color: VimiColors.violet),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
        ),
        if (glyph != null && glyph != Glyph.studio) ...[
          const SizedBox(width: 8),
          VIcon(glyph!, size: 16),
        ],
      ],
    ),
  );
}
