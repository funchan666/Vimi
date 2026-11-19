import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    PlaybackCoordinator.pauseAll();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    PlaybackCoordinator.pauseAll();
  }
}

class RehearsalPlayer extends StatefulWidget {
  const RehearsalPlayer({
    super.key,
    required this.source,
    this.network = false,
    this.practice = false,
    this.fullscreen = false,
  });
  final String source;
  final bool network, practice, fullscreen;
  @override
  State<RehearsalPlayer> createState() => _RehearsalPlayerState();
}

class _RehearsalPlayerState extends State<RehearsalPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? player;
  String? error;
  bool mirror = false, loop = false;
  double speed = 1;
  int seek = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(load());
  }

  @override
  void didUpdateWidget(covariant RehearsalPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      release();
      unawaited(load());
    }
  }

  Future<void> load() async {
    final current = widget.network
        ? VideoPlayerController.networkUrl(Uri.parse(widget.source))
        : VideoPlayerController.file(File(widget.source));
    player = current;
    try {
      await current.initialize();
      if (!mounted || player != current) return;
      current.addListener(changed);
      setState(() => error = null);
    } catch (e) {
      if (mounted && player == current)
        setState(
          () => error = 'This video could not be opened. Please try again.',
        );
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
    final current = player;
    player = null;
    if (current != null) {
      PlaybackCoordinator.remove(current);
      current.removeListener(changed);
      unawaited(current.dispose());
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

  @override
  Widget build(BuildContext context) {
    final current = player;
    if (error != null)
      return ErrorNote(
        error!,
        onRetry: () {
          release();
          setState(() => error = null);
          unawaited(load());
        },
      );
    if (current == null || !current.value.isInitialized)
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('Opening video…'),
      );
    final value = current.value;
    final maxSeconds = value.duration.inSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 9 / 16,
              child: Transform.flip(flipX: mirror, child: VideoPlayer(current)),
            ),
            if (!value.isPlaying)
              VButton('Play', glyph: Glyph.play, onPressed: toggle),
          ],
        ),
        SurfacePanel(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  VIconButton(
                    value.isPlaying ? Glyph.pause : Glyph.play,
                    label: value.isPlaying ? 'Pause video' : 'Play video',
                    onPressed: toggle,
                  ),
                  Text('${value.position.inSeconds}s / ${maxSeconds}s'),
                  VIconButton(
                    value.volume > 0 ? Glyph.sound : Glyph.mute,
                    label: value.volume > 0 ? 'Mute audio' : 'Enable audio',
                    onPressed: () =>
                        current.setVolume(value.volume > 0 ? 0 : 1),
                  ),
                  if (widget.practice) ...[
                    VButton(
                      mirror ? 'Mirror on' : 'Mirror off',
                      quiet: true,
                      onPressed: () => setState(() => mirror = !mirror),
                    ),
                    VButton(
                      loop ? 'Loop on' : 'Loop off',
                      quiet: true,
                      onPressed: () async {
                        loop = !loop;
                        await current.setLooping(loop);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                  if (!widget.fullscreen)
                    VButton(
                      'Full screen',
                      quiet: true,
                      onPressed: () async {
                        await current.pause();
                        if (context.mounted)
                          await openPage(
                            context,
                            VPage(
                              title: 'Your movement',
                              child: Center(
                                child: SingleChildScrollView(
                                  child: RehearsalPlayer(
                                    source: widget.source,
                                    network: widget.network,
                                    practice: widget.practice,
                                    fullscreen: true,
                                  ),
                                ),
                              ),
                            ),
                          );
                      },
                    ),
                ],
              ),
              if (widget.practice)
                ChoiceStrip(
                  options: const ['0.5×', '0.75×', '1.0×', '1.25×'],
                  value: '${speed == 1 ? '1.0' : speed}×',
                  onChanged: (v) async {
                    speed = double.parse(v.replaceAll('×', ''));
                    await current.setPlaybackSpeed(speed);
                    if (mounted) setState(() {});
                  },
                ),
              Row(
                children: [
                  VButton(
                    '−5s',
                    quiet: true,
                    onPressed: () => current.seekTo(
                      Duration(
                        seconds: (value.position.inSeconds - 5)
                            .clamp(0, maxSeconds)
                            .toInt(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      label: 'Video position',
                      value:
                          '${value.position.inSeconds} of $maxSeconds seconds',
                      child: TextButton(
                        onPressed: () async {
                          await current.pause();
                          if (!context.mounted) return;
                          final controller = TextEditingController(
                            text: '${value.position.inSeconds}',
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
                                          final number = int.tryParse(
                                            controller.text,
                                          );
                                          if (number != null &&
                                              number >= 0 &&
                                              number <= maxSeconds)
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
                            await current.seekTo(Duration(seconds: result));
                        },
                        child: const Text('Go to time'),
                      ),
                    ),
                  ),
                  VButton(
                    '+5s',
                    quiet: true,
                    onPressed: () => current.seekTo(
                      Duration(
                        seconds: (value.position.inSeconds + 5)
                            .clamp(0, maxSeconds)
                            .toInt(),
                      ),
                    ),
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
