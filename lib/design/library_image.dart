import 'package:flutter/material.dart';
import 'vimi_ui.dart';

/// Publisher image with a stable layout and an explicit retry path.
class LibraryImage extends StatefulWidget {
  const LibraryImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.label,
    this.compact = false,
  });
  final String url;
  final BoxFit fit;
  final double? width, height;
  final int? cacheWidth;
  final String? label;
  final bool compact;
  @override
  State<LibraryImage> createState() => _LibraryImageState();
}

class _LibraryImageState extends State<LibraryImage> {
  int attempt = 0;
  Future<void> retry() async {
    await NetworkImage(widget.url).evict();
    if (mounted) setState(() => attempt++);
  }

  @override
  Widget build(BuildContext context) => Image.network(
    widget.url,
    key: ValueKey('${widget.url}-$attempt'),
    width: widget.width,
    height: widget.height,
    fit: widget.fit,
    cacheWidth: widget.cacheWidth,
    semanticLabel: widget.label,
    excludeFromSemantics: widget.label == null,
    frameBuilder: (context, child, frame, synchronous) =>
        frame != null || synchronous
        ? child
        : SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: VIcon(Glyph.photo, color: VimiColors.muted),
            ),
          ),
    errorBuilder: (context, error, stack) => SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.compact)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Image unavailable. Check your connection and retry.',
                  textAlign: TextAlign.center,
                ),
              ),
            VIconButton(
              Glyph.refresh,
              label: 'Retry image',
              filled: true,
              onPressed: retry,
            ),
          ],
        ),
      ),
    ),
  );
}
