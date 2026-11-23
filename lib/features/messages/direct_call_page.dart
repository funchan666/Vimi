import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../design/vimi_ui.dart';
import '../community/community_pages.dart';
import 'call_media.dart';
import 'direct_calls.dart';

class DirectCallPage extends StatefulWidget {
  const DirectCallPage({required this.calls, required this.call, super.key});

  final DirectCalls calls;
  final DirectCall call;

  @override
  State<DirectCallPage> createState() => _DirectCallPageState();
}

class _DirectCallPageState extends State<DirectCallPage> {
  bool changingMedia = false;
  DirectCall get call => widget.call;
  DirectCalls get calls => widget.calls;

  String get status => switch (call) {
    DirectCall(outcome: final String outcome) => outcome,
    DirectCall(preparing: true) => 'Getting ready…',
    DirectCall(status: 'ringing', incoming: true) => 'Incoming call',
    DirectCall(status: 'ringing') => 'Calling…',
    DirectCall(connection: CallConnectionState.connected) => 'Connected',
    DirectCall(connection: CallConnectionState.disconnected) => 'Reconnecting…',
    _ => 'Connecting…',
  };

  Future<void> changeMedia(Future<void> Function() update) async {
    if (changingMedia) return;
    setState(() => changingMedia = true);
    try {
      await update();
    } on CallMediaException catch (error) {
      if (mounted && !call.finished) feedback(context, error.message);
    } catch (_) {
      if (mounted && !call.finished) {
        feedback(context, 'This control is temporarily unavailable.');
      }
    } finally {
      if (mounted) setState(() => changingMedia = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: calls,
    builder: (context, _) {
      final media = call.media;
      final type = Theme.of(context).textTheme;
      return VPage(
        title: call.kind,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    children: [
                      if (call.video && media?.ready == true)
                        _CallVideo(media: media!, call: call)
                      else
                        Center(child: SignedAvatar(call.peer, size: 112)),
                      const SizedBox(height: 18),
                      Text(
                        call.peer.name,
                        textAlign: TextAlign.center,
                        style: type.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: type.bodyMedium?.copyWith(
                            color: call.finished
                                ? VimiColors.muted
                                : VimiColors.cyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: _actions(media),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _actions(CallMedia? media) {
    if (call.finished) {
      return VButton('Done', onPressed: () => Navigator.pop(context));
    }
    if (call.incoming && call.status == 'ringing') {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          VButton(
            'Decline',
            quiet: true,
            glyph: Glyph.close,
            onPressed: () => unawaited(calls.end(call)),
          ),
          VButton(
            'Answer',
            glyph: call.video ? Glyph.video : Glyph.phone,
            busy: call.preparing,
            onPressed: () => unawaited(calls.accept(call)),
          ),
        ],
      );
    }
    if (call.status == 'ringing') {
      return VButton(
        'Cancel call',
        quiet: true,
        glyph: Glyph.close,
        onPressed: () => unawaited(calls.end(call)),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (media?.ready == true)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              VButton(
                media!.muted ? 'Unmute mic' : 'Mute mic',
                quiet: true,
                onPressed: changingMedia
                    ? null
                    : () => changeMedia(() => media.setMuted(!media.muted)),
              ),
              if (call.video)
                VIconButton(
                  Glyph.video,
                  label: media.cameraEnabled
                      ? 'Turn camera off'
                      : 'Turn camera on',
                  selected: media.cameraEnabled,
                  filled: true,
                  onPressed: changingMedia
                      ? null
                      : () => changeMedia(
                          () => media.setCameraEnabled(!media.cameraEnabled),
                        ),
                ),
              if (call.video && media.cameraEnabled)
                VIconButton(
                  Glyph.mirror,
                  label: 'Switch camera',
                  filled: true,
                  onPressed: changingMedia
                      ? null
                      : () => changeMedia(media.switchCamera),
                ),
              if (!call.video)
                VIconButton(
                  Glyph.sound,
                  label: media.speakerEnabled
                      ? 'Switch to earpiece'
                      : 'Use speaker',
                  selected: media.speakerEnabled,
                  filled: true,
                  onPressed: changingMedia
                      ? null
                      : () => changeMedia(
                          () => media.setSpeakerEnabled(!media.speakerEnabled),
                        ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        VButton(
          'End call',
          tonal: true,
          glyph: Glyph.close,
          onPressed: () => unawaited(calls.end(call)),
        ),
      ],
    );
  }
}

class _CallVideo extends StatelessWidget {
  const _CallVideo({required this.media, required this.call});

  final CallMedia media;
  final DirectCall call;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = (constraints.maxWidth * .9).clamp(180.0, 340.0).toDouble();
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: VimiColors.surface,
                child: _CallTexture(
                  renderer: media.remoteRenderer,
                  fallback: Center(child: SignedAvatar(call.peer, size: 96)),
                ),
              ),
              if (media.cameraEnabled)
                PositionedDirectional(
                  end: 10,
                  bottom: 10,
                  width: (constraints.maxWidth * .27)
                      .clamp(52.0, 104.0)
                      .toDouble(),
                  height: height * .35,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      color: VimiColors.tonal,
                      child: Semantics(
                        label: 'Your camera preview',
                        child: _CallTexture(
                          renderer: media.localRenderer,
                          mirror: media.frontCamera,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _CallTexture extends StatelessWidget {
  const _CallTexture({
    required this.renderer,
    this.mirror = false,
    this.fallback = const SizedBox.expand(),
  });

  final RTCVideoRenderer renderer;
  final bool mirror;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<RTCVideoValue>(
    valueListenable: renderer,
    child: fallback,
    builder: (context, frame, child) =>
        frame.width > 0 && frame.height > 0 && renderer.renderVideo
        ? RTCVideoView(
            renderer,
            mirror: mirror,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        : child!,
  );
}
