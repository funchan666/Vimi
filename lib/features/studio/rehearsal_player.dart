import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/media_library.dart';
import '../../design/vimi_ui.dart';

abstract final class PlaybackCoordinator {
  static final _players = <VideoPlayerController>{};
  static Future<void> play(VideoPlayerController player) async {
    for (final other in _players.toList()) {
      if (other != player) await other.pause();
    }
    _players.add(player);
    await player.play();
  }

  static void pauseAll() {
    for (final player in _players.toList()) {
      unawaited(player.pause().catchError((Object _) {}));
    }
  }

  static void remove(VideoPlayerController player) => _players.remove(player);
}

class PlaybackRouteObserver extends NavigatorObserver {
  PlaybackRouteObserver({this.onReturned});
  final VoidCallback? onReturned;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    PlaybackCoordinator.pauseAll();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    PlaybackCoordinator.pauseAll();
    if (onReturned != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onReturned!());
    }
  }
}

class RehearsalPlayer extends StatefulWidget {
  const RehearsalPlayer({
    super.key,
    required this.source,
    this.network = false,
    this.practice = false,
    this.fullscreen = false,
    this.onReady,
  }) : _sharedController = null,
       _initialMirror = false,
       _onMirrorChanged = null,
       _onRetry = null;
  const RehearsalPlayer._expanded({
    required this.source,
    required this.network,
    required this.practice,
    required VideoPlayerController controller,
    required bool mirrored,
    required ValueChanged<bool> onMirrorChanged,
    required VoidCallback onRetry,
  }) : fullscreen = true,
       onReady = null,
       _sharedController = controller,
       _initialMirror = mirrored,
       _onMirrorChanged = onMirrorChanged,
       _onRetry = onRetry;
  final String source;
  final bool network, practice, fullscreen;
  final VoidCallback? onReady;
  final VideoPlayerController? _sharedController;
  final bool _initialMirror;
  final ValueChanged<bool>? _onMirrorChanged;
  final VoidCallback? _onRetry;
  @override
  State<RehearsalPlayer> createState() => _RehearsalPlayerState();
}

class _RehearsalPlayerState extends State<RehearsalPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? player;
  String? error;
  bool mirror = false, ownsPlayer = true;
  int loadVersion = 0;
  @override
  void initState() {
    super.initState();
    mirror = widget._initialMirror;
    WidgetsBinding.instance.addObserver(this);
    unawaited(load());
  }

  @override
  void didUpdateWidget(covariant RehearsalPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.network != widget.network ||
        oldWidget._sharedController != widget._sharedController) {
      release();
      unawaited(load());
    }
  }

  Future<void> load() async {
    release();
    final version = loadVersion;
    final source = widget.source;
    final shared = widget._sharedController;
    try {
      final clip = shared == null && !widget.network && isLibraryVideo(source)
          ? (await MediaLibrary.load()).clipForSource(source)
          : null;
      if (!mounted || version != loadVersion) return;
      final current =
          shared ??
          (widget.network
              ? VideoPlayerController.networkUrl(Uri.parse(source))
              : clip != null
              ? VideoPlayerController.networkUrl(Uri.parse(clip.url))
              : VideoPlayerController.file(File(source)));
      player = current;
      ownsPlayer = shared == null;
      if (!current.value.isInitialized) {
        await current.initialize().timeout(const Duration(seconds: 30));
      }
      if (!mounted || player != current) return;
      current.addListener(changed);
      setState(() => error = null);
      widget.onReady?.call();
    } catch (_) {
      if (mounted && version == loadVersion) {
        setState(
          () => error =
              'This video could not be opened. Check your connection and retry.',
        );
      }
    }
  }

  void changed() {
    if (mounted)
      setState(() {
        if (player?.value.hasError == true)
          error = 'Playback was interrupted. Open the video again.';
      });
  }

  void release() {
    loadVersion++;
    final current = player;
    player = null;
    if (current != null) {
      current.removeListener(changed);
      if (ownsPlayer) {
        PlaybackCoordinator.remove(current);
        unawaited(current.dispose());
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) player?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    release();
    super.dispose();
  }

  Future<void> toggle() async {
    final current = player;
    if (current == null) return;
    try {
      if (current.value.isPlaying) {
        await current.pause();
      } else {
        if (current.value.position >= current.value.duration)
          await current.seekTo(Duration.zero);
        await PlaybackCoordinator.play(current);
      }
    } catch (_) {
      if (mounted)
        setState(
          () => error = 'Playback was interrupted. Open the video again.',
        );
    }
  }

  Future<void> control(Future<void> Function() change) async {
    try {
      await change();
    } catch (_) {
      if (mounted)
        setState(
          () => error = 'Playback was interrupted. Open the video again.',
        );
    }
  }

  void retry() {
    release();
    setState(() => error = null);
    unawaited(load());
  }

  Future<void> goToTime() async {
    final current = player;
    if (current == null) return;
    await current.pause();
    if (!mounted) return;
    final maxSeconds = current.value.duration.inSeconds;
    final controller = TextEditingController(
      text: '${current.value.position.inSeconds}',
    );
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SurfacePanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VField(
                  'Go to second · 0–$maxSeconds',
                  controller: controller,
                  keyboardType: TextInputType.number,
                ),
                VButton(
                  'Go',
                  onPressed: () {
                    final number = int.tryParse(controller.text);
                    if (number != null && number >= 0 && number <= maxSeconds)
                      Navigator.pop(ctx, number);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
    if (result != null && mounted)
      await control(() => current.seekTo(Duration(seconds: result)));
  }

  Future<void> chooseSpeed() async {
    final current = player;
    if (current == null) return;
    final result = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SurfacePanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Playback speed',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final speed in [0.5, 0.75, 1.0, 1.25])
                      VButton(
                        '${speed == 1 ? '1.0' : speed}×',
                        tonal: current.value.playbackSpeed != speed,
                        onPressed: () => Navigator.pop(ctx, speed),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted)
      await control(() => current.setPlaybackSpeed(result));
  }

  Future<void> expand() async {
    final current = player;
    if (current == null) return;
    await current.pause();
    if (!mounted) return;
    await openPage(
      context,
      VPage(
        title: 'Your movement',
        child: Center(
          child: SingleChildScrollView(
            child: RehearsalPlayer._expanded(
              source: widget.source,
              network: widget.network,
              practice: widget.practice,
              controller: current,
              mirrored: mirror,
              onMirrorChanged: (value) {
                if (mounted) setState(() => mirror = value);
              },
              onRetry: retry,
            ),
          ),
        ),
      ),
    );
  }

  String timestamp(Duration duration) =>
      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final current = player;
    if (error != null)
      return ErrorNote(
        error!,
        onRetry: () {
          if (widget._onRetry != null) {
            Navigator.pop(context);
            widget._onRetry!();
          } else {
            retry();
          }
        },
      );
    if (current == null || !current.value.isInitialized)
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('Opening video…'),
      );
    final value = current.value;
    final loop = value.isLooping, speed = value.playbackSpeed;
    final maxSeconds = value.duration.inSeconds;
    final aspect = value.aspectRatio > 0 ? value.aspectRatio : 9 / 16;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height *
                (widget.fullscreen ? .68 : .52),
          ),
          child: Center(
            child: AspectRatio(
              aspectRatio: aspect,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.flip(flipX: mirror, child: VideoPlayer(current)),
                  if (!value.isPlaying)
                    VIconButton(
                      Glyph.play,
                      label: 'Play',
                      primary: true,
                      onPressed: toggle,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SurfacePanel(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  VIconButton(
                    Glyph.rewind,
                    label: '−5s',
                    onPressed: () => control(
                      () => current.seekTo(
                        Duration(
                          seconds: (value.position.inSeconds - 5)
                              .clamp(0, maxSeconds)
                              .toInt(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  VIconButton(
                    value.isPlaying ? Glyph.pause : Glyph.play,
                    label: value.isPlaying ? 'Pause video' : 'Play video',
                    primary: true,
                    onPressed: toggle,
                  ),
                  const SizedBox(width: 4),
                  VIconButton(
                    Glyph.forward,
                    label: '+5s',
                    onPressed: () => control(
                      () => current.seekTo(
                        Duration(
                          seconds: (value.position.inSeconds + 5)
                              .clamp(0, maxSeconds)
                              .toInt(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      label: 'Video position',
                      value:
                          '${value.position.inSeconds} of $maxSeconds seconds',
                      child: Tooltip(
                        message: 'Go to time',
                        child: TextButton(
                          onPressed: goToTime,
                          style: TextButton.styleFrom(
                            foregroundColor: VimiColors.muted,
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: Text(
                            '${timestamp(value.position)} / ${timestamp(value.duration)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (widget.practice) ...[
                    VIconButton(
                      Glyph.mirror,
                      label: mirror ? 'Mirror on' : 'Mirror off',
                      selected: mirror,
                      filled: true,
                      onPressed: () {
                        setState(() => mirror = !mirror);
                        widget._onMirrorChanged?.call(mirror);
                      },
                    ),
                    VIconButton(
                      Glyph.loop,
                      label: loop ? 'Loop on' : 'Loop off',
                      selected: loop,
                      filled: true,
                      onPressed: () => control(() => current.setLooping(!loop)),
                    ),
                    Tooltip(
                      message: 'Playback speed',
                      child: VButton(
                        '${speed == 1 ? '1.0' : speed}×',
                        quiet: true,
                        onPressed: chooseSpeed,
                      ),
                    ),
                  ],
                  VIconButton(
                    value.volume > 0 ? Glyph.sound : Glyph.mute,
                    label: value.volume > 0 ? 'Mute audio' : 'Enable audio',
                    filled: true,
                    onPressed: () => control(
                      () => current.setVolume(value.volume > 0 ? 0 : 1),
                    ),
                  ),
                  if (!widget.fullscreen)
                    VIconButton(
                      Glyph.expand,
                      label: 'Full screen',
                      filled: true,
                      onPressed: expand,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
