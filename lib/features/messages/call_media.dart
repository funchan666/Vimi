import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallConnectionState { connecting, connected, disconnected, failed, closed }

class CallMediaException implements Exception {
  const CallMediaException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CallMedia {
  CallMedia({
    required this.video,
    required this.onCandidate,
    required this.onConnectionState,
    List<Map<String, dynamic>>? iceServers,
  }) : _iceServers = iceServers ?? _defaultIceServers;

  final bool video;
  final void Function(Map<String, dynamic>) onCandidate;
  final void Function(CallConnectionState) onConnectionState;
  final List<Map<String, dynamic>> _iceServers;
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();
  final _queuedCandidates = <RTCIceCandidate>[];

  RTCPeerConnection? _peer;
  MediaStream? _microphone;
  MediaStream? _camera;
  RTCRtpSender? _videoSender;
  Future<void>? _starting;
  Future<void>? _cameraOperation;
  Future<void>? _audioOperation;
  Future<void>? _closing;
  bool _closed = false;
  bool _ready = false;
  bool _hasRemoteDescription = false;
  bool _frontCamera = true;
  bool _muted = false;
  bool _speakerEnabled = false;

  bool get ready => _ready && !_closed;
  bool get muted => _muted;
  bool get cameraEnabled => _camera != null && ready;
  bool get frontCamera => _frontCamera;
  bool get speakerEnabled => _speakerEnabled;

  // Room-scoped TURN credentials can be injected when the app has a relay service.
  static List<Map<String, dynamic>> get _defaultIceServers {
    const hosts = String.fromEnvironment(
      'VIMI_CALL_STUN_URLS',
      defaultValue: 'stun:stun.l.google.com:19302',
    );
    return [
      for (final host in hosts.split(',').map((value) => value.trim()))
        if (host.startsWith('stun:') || host.startsWith('stuns:'))
          {'urls': host},
    ];
  }

  Future<void> start() {
    if (_closed) return Future.error(StateError('The call has ended.'));
    return _starting ??= _start();
  }

  Future<void> _start() async {
    try {
      await Helper.setAndroidAudioConfiguration(
        AndroidAudioConfiguration.communication,
      );
      _ensureOpen();
      final peer = await createPeerConnection({
        'iceServers': _iceServers,
        'sdpSemantics': 'unified-plan',
      });
      _peer = peer;
      _ensureOpen();
      _microphone = await _capture(camera: false);
      _ensureOpen();
      if (video) {
        _camera = await _capture(camera: true);
        _ensureOpen();
        await localRenderer.initialize();
        await remoteRenderer.initialize();
        _ensureOpen();
        await localRenderer.setSrcObject(stream: _camera);
      }
      _ensureOpen();
      peer.onIceCandidate = (candidate) {
        if (!_closed && (candidate.candidate?.isNotEmpty ?? false)) {
          onCandidate({
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          });
        }
      };
      peer.onConnectionState = (state) {
        if (!_closed) onConnectionState(_connectionState(state));
      };
      if (video) {
        peer.onTrack = (event) {
          if (!_closed &&
              event.track.kind == 'video' &&
              event.streams.isNotEmpty) {
            unawaited(_showRemoteVideo(event));
          }
        };
      }
      final microphone = _microphone!;
      await peer.addTrack(microphone.getAudioTracks().single, microphone);
      _ensureOpen();
      if (_camera case final camera?) {
        _videoSender = await peer.addTrack(
          camera.getVideoTracks().single,
          camera,
        );
        _ensureOpen();
      }
      await Helper.setSpeakerphoneOn(video);
      _speakerEnabled = video;
      _ensureOpen();
      _ready = true;
    } catch (_) {
      _closed = true;
      await _release();
      rethrow;
    }
  }

  static CallConnectionState _connectionState(RTCPeerConnectionState state) =>
      switch (state) {
        RTCPeerConnectionState.RTCPeerConnectionStateNew ||
        RTCPeerConnectionState.RTCPeerConnectionStateConnecting =>
          CallConnectionState.connecting,
        RTCPeerConnectionState.RTCPeerConnectionStateConnected =>
          CallConnectionState.connected,
        RTCPeerConnectionState.RTCPeerConnectionStateDisconnected =>
          CallConnectionState.disconnected,
        RTCPeerConnectionState.RTCPeerConnectionStateFailed =>
          CallConnectionState.failed,
        RTCPeerConnectionState.RTCPeerConnectionStateClosed =>
          CallConnectionState.closed,
      };

  Future<MediaStream> _capture({required bool camera}) async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': !camera,
        'video': !camera
            ? false
            : {
                'facingMode': _frontCamera ? 'user' : 'environment',
                'width': {'ideal': 960},
                'height': {'ideal': 540},
                'frameRate': {'ideal': 24},
              },
      });
      final tracks = camera ? stream.getVideoTracks() : stream.getAudioTracks();
      if (tracks.length == 1) return stream;
      await _stopStream(stream);
    } catch (_) {
      // The native permission API can return a platform-specific error string.
    }
    throw CallMediaException(
      camera
          ? 'Camera unavailable. Check your camera permission and try again.'
          : 'Microphone unavailable. Check your microphone permission and try again.',
    );
  }

  Future<void> _showRemoteVideo(RTCTrackEvent event) async {
    try {
      await remoteRenderer.setSrcObject(
        stream: event.streams.first,
        trackId: event.track.id,
      );
    } catch (_) {
      if (!_closed) onConnectionState(CallConnectionState.failed);
    }
  }

  Future<Map<String, dynamic>> createOffer() async {
    final peer = _activePeer;
    final offer = await peer.createOffer();
    _ensureOpen();
    await peer.setLocalDescription(offer);
    _ensureOpen();
    return {'type': offer.type, 'sdp': offer.sdp};
  }

  Future<Map<String, dynamic>> acceptOffer(Map<String, dynamic> payload) async {
    final peer = _activePeer;
    await _setRemote(peer, payload, 'offer');
    _ensureOpen();
    final answer = await peer.createAnswer();
    _ensureOpen();
    await peer.setLocalDescription(answer);
    _ensureOpen();
    return {'type': answer.type, 'sdp': answer.sdp};
  }

  Future<void> acceptAnswer(Map<String, dynamic> payload) =>
      _setRemote(_activePeer, payload, 'answer');

  Future<void> _setRemote(
    RTCPeerConnection peer,
    Map<String, dynamic> payload,
    String type,
  ) async {
    if (payload case {
      'type': final String actualType,
      'sdp': final String sdp,
    } when actualType == type && sdp.isNotEmpty) {
      await peer.setRemoteDescription(RTCSessionDescription(sdp, type));
    } else {
      throw const FormatException('Invalid call description.');
    }
    _ensureOpen();
    _hasRemoteDescription = true;
    final waiting = List.of(_queuedCandidates);
    _queuedCandidates.clear();
    for (final candidate in waiting) {
      _ensureOpen();
      await peer.addCandidate(candidate);
    }
  }

  Future<void> addCandidate(Map<String, dynamic> payload) async {
    _ensureOpen();
    final value = payload['candidate'];
    final mid = payload['sdpMid'];
    final line = payload['sdpMLineIndex'];
    if (value is! String ||
        value.isEmpty ||
        (mid != null && mid is! String) ||
        (line != null && line is! int) ||
        (mid == null && line == null)) {
      throw const FormatException('Invalid call candidate.');
    }
    final candidate = RTCIceCandidate(value, mid as String?, line as int?);
    if (_hasRemoteDescription) {
      await _activePeer.addCandidate(candidate);
    } else {
      _queuedCandidates.add(candidate);
    }
  }

  Future<void> setMuted(bool value) => _changeAudio(() async {
    await Helper.setMicrophoneMuted(value);
    _muted = value;
  });

  Future<void> setCameraEnabled(bool value) async {
    if (!ready || !video || value == cameraEnabled) return;
    await (_cameraOperation ??= _changeCamera(value).whenComplete(() {
      _cameraOperation = null;
    }));
  }

  Future<void> _changeCamera(bool enabled) async {
    if (!enabled) {
      final previous = _camera;
      _camera = null;
      try {
        await _videoSender!.replaceTrack(null);
        await localRenderer.setSrcObject();
      } finally {
        await _stopStream(previous);
      }
      return;
    }
    final camera = await _capture(camera: true);
    try {
      _ensureOpen();
      await _videoSender!.replaceTrack(camera.getVideoTracks().single);
      await localRenderer.setSrcObject(stream: camera);
      _ensureOpen();
      _camera = camera;
    } catch (_) {
      await _stopStream(camera);
      rethrow;
    }
  }

  Future<void> setSpeakerEnabled(bool value) => _changeAudio(() async {
    await Helper.setSpeakerphoneOn(value);
    _speakerEnabled = value;
  });

  Future<void> _changeAudio(Future<void> Function() update) async {
    if (!ready) return;
    await (_audioOperation ??= update().whenComplete(() {
      _audioOperation = null;
    }));
  }

  Future<void> switchCamera() async {
    if (!cameraEnabled) return;
    await (_cameraOperation ??= _switchCamera().whenComplete(() {
      _cameraOperation = null;
    }));
  }

  Future<void> _switchCamera() async {
    _frontCamera = await Helper.switchCamera(_camera!.getVideoTracks().single);
  }

  RTCPeerConnection get _activePeer {
    if (!ready) throw StateError('Call media is not ready.');
    return _peer!;
  }

  void _ensureOpen() {
    if (_closed) throw StateError('The call has ended.');
  }

  Future<void> dispose() {
    _closed = true;
    return _closing ??= _close();
  }

  Future<void> _close() async {
    if (_starting case final starting?) {
      await _cleanup(starting);
    }
    if (_cameraOperation case final changing?) {
      await _cleanup(changing);
    }
    if (_audioOperation case final changing?) {
      await _cleanup(changing);
    }
    await _release();
  }

  bool _released = false;

  Future<void> _release() async {
    if (_released) return;
    _released = true;
    _queuedCandidates.clear();
    final peer = _peer;
    if (peer != null) {
      peer.onIceCandidate = null;
      peer.onConnectionState = null;
      peer.onTrack = null;
    }
    await Future.wait([_stopStream(_microphone), _stopStream(_camera)]);
    if (peer != null) {
      await _cleanup(peer.close());
      await _cleanup(peer.dispose());
    }
    if (_muted) await _cleanup(Helper.setMicrophoneMuted(false));
    await Future.wait([
      _cleanup(localRenderer.dispose()),
      _cleanup(remoteRenderer.dispose()),
    ]);
  }

  static Future<void> _stopStream(MediaStream? stream) async {
    if (stream == null) return;
    await Future.wait(
      stream.getTracks().map((track) => _cleanup(track.stop())),
    );
    await _cleanup(stream.dispose());
  }

  static Future<void> _cleanup(Future<void> work) async {
    try {
      await work;
    } catch (_) {
      // Keep releasing the remaining native resources if one already stopped.
    }
  }
}
