import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../design/vimi_ui.dart';
import '../studio/rehearsal_player.dart';

class CoverVideoCanvas extends StatefulWidget {
  const CoverVideoCanvas({
    super.key,
    required this.sourceId,
    required this.resolveUrl,
    required this.active,
    required this.muted,
    required this.poster,
  });

  final String sourceId;
  final Future<String> Function(bool forceRefresh) resolveUrl;
  final bool active, muted;
  final Widget poster;

  @override
  State<CoverVideoCanvas> createState() => _CoverVideoCanvasState();
}

class _CoverVideoCanvasState extends State<CoverVideoCanvas>
    with WidgetsBindingObserver {
  VideoPlayerController? _player;
  late bool _foreground;
  bool _loading = false, _ready = false, _failed = false, _userPaused = false;
  bool _changingPlayback = false;
  int _loadVersion = 0;
  Duration _position = Duration.zero;

  bool get _visible => widget.active && _foreground;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _updateVisibility();
  }

  @override
  void didUpdateWidget(covariant CoverVideoCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceId != widget.sourceId) {
      _release();
      _position = Duration.zero;
      _userPaused = false;
      _failed = false;
    }
    _updateVisibility();
    final player = _player;
    if (oldWidget.muted != widget.muted &&
        player?.value.isInitialized == true) {
      unawaited(_applyVolume(player!));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground != foreground) {
      setState(() => _foreground = foreground);
      _updateVisibility();
    }
  }

  void _updateVisibility() {
    if (!_visible) {
      _release();
    } else if (!_loading && !_ready && !_failed) {
      unawaited(_load());
    }
  }

  Future<void> _load({bool retry = false}) async {
    final version = ++_loadVersion;
    _loading = true;
    try {
      final url = await widget
          .resolveUrl(retry)
          .timeout(const Duration(seconds: 15));
      if (!mounted || version != _loadVersion) return;
      final uri = Uri.parse(url);
      if (uri.scheme != 'https' || uri.host.isEmpty) {
        throw const FormatException('Expected an HTTPS video URL.');
      }
      final player = VideoPlayerController.networkUrl(uri);
      _player = player;
      await player.initialize().timeout(const Duration(seconds: 30));
      if (!mounted || version != _loadVersion) return;
      await player.setLooping(true);
      await player.setVolume(widget.muted ? 0 : 1);
      if (_position > Duration.zero) await player.seekTo(_position);
      if (!mounted || version != _loadVersion) return;
      if (!_userPaused) await _play(player);
      if (!mounted || version != _loadVersion) return;
      setState(() {
        _loading = false;
        _ready = true;
      });
    } catch (_) {
      if (mounted && version == _loadVersion) _showFailure();
    }
  }

  Future<void> _play(VideoPlayerController player) async {
    try {
      await PlaybackCoordinator.play(player);
    } finally {
      if (_player != player) PlaybackCoordinator.remove(player);
    }
  }

  Future<void> _applyVolume(VideoPlayerController player) async {
    try {
      await player.setVolume(widget.muted ? 0 : 1);
    } catch (_) {
      if (mounted && _player == player) _showFailure();
    }
  }

  Future<void> _toggle(VideoPlayerController player) async {
    if (!_visible || _player != player || _changingPlayback) return;
    _changingPlayback = true;
    _userPaused = player.value.isPlaying;
    try {
      if (_userPaused) {
        await player.pause();
      } else {
        await _play(player);
      }
    } catch (_) {
      if (mounted && _player == player) _showFailure();
    } finally {
      if (_player == player) _changingPlayback = false;
    }
  }

  void _showFailure() {
    _release();
    setState(() => _failed = true);
  }

  void _retry() {
    _release();
    if (!_visible) return;
    setState(() => _failed = false);
    unawaited(_load(retry: true));
  }

  void _release() {
    _loadVersion++;
    _loading = false;
    _changingPlayback = false;
    final player = _player;
    _player = null;
    if (player != null) {
      if (_ready && player.value.isInitialized)
        _position = player.value.position;
      PlaybackCoordinator.remove(player);
      unawaited(player.dispose().catchError((Object _) {}));
    }
    _ready = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _release();
    super.dispose();
  }

  Widget _progress(BuildContext context) => Semantics(
    label: 'Loading video',
    child: Center(
      child: SizedBox(
        width: 64,
        child: MediaQuery.disableAnimationsOf(context)
            ? const VIcon(Glyph.video, color: VimiColors.cyan)
            : const LinearProgressIndicator(
                minHeight: 2,
                color: VimiColors.cyan,
                backgroundColor: VimiColors.tonal,
              ),
      ),
    ),
  );

  Widget _unavailable() => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SurfacePanel(
        padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(child: Text('Video unavailable')),
            const SizedBox(width: 8),
            VIconButton(Glyph.refresh, label: 'Retry video', onPressed: _retry),
          ],
        ),
      ),
    ),
  );

  Widget _frame(VideoPlayerController player) => LayoutBuilder(
    builder: (context, constraints) {
      final size = player.value.size;
      if (size.isEmpty) return const SizedBox.shrink();
      final fill =
          size.width < size.height &&
          constraints.maxWidth < constraints.maxHeight;
      return ColoredBox(
        color: VimiColors.background,
        child: ClipRect(
          child: FittedBox(
            fit: fill ? BoxFit.cover : BoxFit.contain,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(player),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final player = _player;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: VimiColors.background, child: widget.poster),
        if (_visible)
          if (_ready && player != null)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: player,
              child: _frame(player),
              builder: (context, value, frame) {
                if (value.hasError) return _unavailable();
                final duration = value.duration.inMilliseconds;
                final progress = duration == 0
                    ? 0.0
                    : (value.position.inMilliseconds / duration).clamp(
                        0.0,
                        1.0,
                      );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    frame!,
                    Semantics(
                      label: value.isPlaying ? 'Pause video' : 'Play video',
                      child: TextButton(
                        onPressed: () => _toggle(player),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: value.isPlaying
                            ? const SizedBox.expand()
                            : const Center(
                                child: SurfacePanel(
                                  padding: EdgeInsets.all(12),
                                  child: VIcon(
                                    Glyph.play,
                                    color: VimiColors.cyan,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (value.isPlaying && value.isBuffering)
                      IgnorePointer(child: _progress(context)),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2,
                        color: VimiColors.cyan,
                        backgroundColor: VimiColors.background.withValues(
                          alpha: .6,
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          else if (_failed)
            _unavailable()
          else
            _progress(context),
      ],
    );
  }
}
