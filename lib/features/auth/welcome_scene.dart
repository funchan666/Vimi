import 'dart:math' as math;

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
    required this.onTerms,
    required this.onPrivacy,
    required this.onSafety,
    required this.onPreview,
  });
  final VoidCallback onJoin, onSignIn, onTerms, onPrivacy, onSafety;
  final ValueChanged<LibraryClip> onPreview;
  @override
  State<DanceWelcomeScene> createState() => _DanceWelcomeSceneState();
}

class _DanceWelcomeSceneState extends State<DanceWelcomeScene> {
  late Future<MediaLibrary> library = MediaLibrary.load();

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
      AccountEntryButton('Join the crew', onPressed: widget.onJoin),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Already a member?',
            style: TextStyle(color: VimiColors.muted, fontSize: 14),
          ),
          _WelcomeLink('Sign in', onPressed: widget.onSignIn, prominent: true),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          _WelcomeLink('Terms of Use', onPressed: widget.onTerms),
          _WelcomeLink('Privacy Policy', onPressed: widget.onPrivacy),
          _WelcomeLink('Child safety', onPressed: widget.onSafety),
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
            final size = box.biggest;
            return Stack(
              children: [
                _placeCover(
                  size,
                  widthFraction: .50,
                  heightFraction: .78,
                  centerYFraction: .53,
                  angle: -.10,
                  child: _PerformancePhoto(
                    url: group?.thumbnail,
                    alignment: Alignment.topCenter,
                    label: 'Group covers',
                  ),
                ),
                _placeCover(
                  size,
                  widthFraction: .55,
                  heightFraction: .88,
                  centerYFraction: .48,
                  angle: .075,
                  trailing: true,
                  child: _PerformancePhoto(
                    url: duet?.thumbnail,
                    alignment: Alignment.topCenter,
                    label: 'Duet covers',
                    onPreview: duet == null
                        ? null
                        : () => widget.onPreview(duet),
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
            );
          },
        );
      },
    ),
  );

  Widget _placeCover(
    Size stage, {
    required double widthFraction,
    required double heightFraction,
    required double centerYFraction,
    required double angle,
    required Widget child,
    bool trailing = false,
  }) {
    final width = stage.width * widthFraction;
    final height = stage.height * heightFraction;
    final sine = math.sin(angle).abs(), cosine = math.cos(angle).abs();
    final paintedWidth = width * cosine + height * sine;
    final paintedHeight = height * cosine + width * sine;
    final edge = math.min(4.0, stage.shortestSide / 8);
    // Position the entire rotated frame inside the stage, including the
    // corners that extend past its unrotated layout box.
    final fit = math.min(
      1.0,
      math.min(
        (stage.width - 2 * edge) / paintedWidth,
        (stage.height - 2 * edge) / paintedHeight,
      ),
    );
    final halfOuterHeight = paintedHeight * fit / 2;
    final centerY = (stage.height * centerYFraction).clamp(
      edge + halfOuterHeight,
      math.max(edge + halfOuterHeight, stage.height - edge - halfOuterHeight),
    );
    final side = edge + (paintedWidth - width) * fit / 2;
    return Positioned(
      left: trailing ? null : side,
      right: trailing ? side : null,
      top: centerY - height * fit / 2,
      width: width * fit,
      height: height * fit,
      child: Transform.rotate(angle: angle, child: child),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: NeonBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final expanded = box.maxWidth >= 760;
            final photoHeight = expanded
                ? (box.maxHeight - 48).clamp(200.0, 640.0)
                : (box.maxHeight * .415 - (scale - 1) * 80).clamp(200.0, 410.0);
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: expanded ? 1240 : 540,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: expanded ? 28 : 20,
                        vertical: 24,
                      ),
                      child: LayoutBuilder(
                        builder: (context, content) {
                          if (expanded) {
                            return Row(
                              children: [
                                Expanded(flex: 6, child: mosaic(photoHeight)),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      introduction(
                                        (content.maxWidth - 32) * 5 / 11,
                                      ),
                                      const SizedBox(height: 24),
                                      actions(),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              mosaic(photoHeight),
                              const SizedBox(height: 16),
                              introduction(content.maxWidth),
                              const SizedBox(height: 24),
                              actions(),
                            ],
                          );
                        },
                      ),
                    ),
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => _buildPhoto(
      playAboveLabel:
          box.maxWidth < MediaQuery.textScalerOf(context).scale(156),
    ),
  );

  Widget _buildPhoto({required bool playAboveLabel}) {
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
              top: playAboveLabel ? 12 : null,
              bottom: playAboveLabel ? null : 12,
              width: 48,
              height: 48,
              child: SurfacePanel(
                padding: EdgeInsets.zero,
                child: const Center(child: VIcon(Glyph.play, size: 24)),
              ),
            ),
          Positioned(
            left: 12,
            right: onPreview == null ? 30 : (playAboveLabel ? 12 : 68),
            top: onPreview == null ? 12 : null,
            bottom: onPreview == null ? null : 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SurfacePanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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
      label: 'Sign in to preview the duet',
      onTap: onPreview,
      child: Tooltip(
        message: 'Sign in to preview the duet',
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPreview,
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(26),
            child: photo,
          ),
        ),
      ),
    );
  }
}

class AccountEntryButton extends StatelessWidget {
  const AccountEntryButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool busy;
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
        onPressed: busy ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: VimiColors.onAccent,
          disabledForegroundColor: VimiColors.onAccent,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                busy ? 'Please wait…' : label,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!busy)
              const VIcon(Glyph.next, color: VimiColors.onAccent, size: 22),
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
    this.prominent = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool prominent;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: prominent ? VimiColors.accent : VimiColors.muted,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        height: 1.35,
        fontWeight: prominent ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
  );
}
