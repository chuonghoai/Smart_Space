import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mobile_shared/features/call/models/call_models.dart';

class CallWebRtcEngine {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCVideoRenderer? _remoteRenderer;

  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  bool _remoteDescriptionSet = false;
  bool _disposed = false;
  bool _isMuted = false;

  void Function(RTCIceCandidate candidate)? onIceCandidate;
  void Function(RTCPeerConnectionState state)? onPeerConnectionStateChanged;
  void Function(List<AudioOutputRoute> availableRoutes, AudioOutputRoute activeRoute)?
      onAudioRoutesChanged;

  bool get isMuted => _isMuted;
  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;

  Future<void> initialize({required List<IceServerModel> iceServers}) async {
    if (_disposed) return;

    // 1. Acquire AUDIO-ONLY media stream (never request camera permission)
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });

    // Ensure remote audio plays properly on Web as well as native
    _remoteRenderer = RTCVideoRenderer();
    await _remoteRenderer!.initialize();

    final config = <String, dynamic>{
      'iceServers': iceServers.isEmpty
          ? [
              {'urls': 'stun:stun.l.google.com:19302'},
            ]
          : iceServers.map((s) => s.toRtcMap()).toList(),
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(config);

    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !_isMuted;
      await _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (!_disposed && candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        onIceCandidate?.call(candidate);
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (_disposed) return;
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteRenderer?.srcObject = _remoteStream;
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (!_disposed) {
        onPeerConnectionStateChanged?.call(state);
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      if (_disposed) return;
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        onPeerConnectionStateChanged?.call(RTCPeerConnectionState.RTCPeerConnectionStateConnected);
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        onPeerConnectionStateChanged?.call(RTCPeerConnectionState.RTCPeerConnectionStateFailed);
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        onPeerConnectionStateChanged?.call(RTCPeerConnectionState.RTCPeerConnectionStateDisconnected);
      }
    };

    if (!kIsWeb) {
      try {
        await Helper.setSpeakerphoneOn(false);
      } catch (e) {
        debugPrint('[CallWebRtcEngine] Default earpiece setup skipped: $e');
      }
    }

    await refreshAudioRoutes();
    try {
      navigator.mediaDevices.ondevicechange = (_) {
        refreshAudioRoutes();
      };
    } catch (_) {}
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> handleRemoteOfferAndCreateAnswer(String sdp) async {
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    _remoteDescriptionSet = true;
    await _flushPendingCandidates();

    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> handleRemoteAnswer(String sdp) async {
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
    _remoteDescriptionSet = true;
    await _flushPendingCandidates();
  }

  Future<void> addRemoteIceCandidate({
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    final ice = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
    if (!_remoteDescriptionSet || _peerConnection == null) {
      _pendingRemoteCandidates.add(ice);
      return;
    }
    await _peerConnection!.addCandidate(ice);
  }

  Future<void> _flushPendingCandidates() async {
    if (_peerConnection == null) return;
    while (_pendingRemoteCandidates.isNotEmpty) {
      final candidate = _pendingRemoteCandidates.removeAt(0);
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint('[CallWebRtcEngine] Failed adding buffered ICE candidate: $e');
      }
    }
  }

  /// Syncs mute state directly with actual local audio track(s).
  bool setMuted(bool muted) {
    _isMuted = muted;
    final tracks = _localStream?.getAudioTracks() ?? [];
    for (final track in tracks) {
      track.enabled = !muted;
    }
    return _isMuted;
  }

  Future<AudioOutputRoute> setAudioOutput(AudioOutputRoute route) async {
    if (kIsWeb) {
      return AudioOutputRoute.browserDefault;
    }

    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      final outputs = devices.where((d) => d.kind == 'audiooutput').toList();

      if (route == AudioOutputRoute.speaker) {
        await Helper.setSpeakerphoneOn(true);
        return AudioOutputRoute.speaker;
      }

      await Helper.setSpeakerphoneOn(false);

      if (route == AudioOutputRoute.bluetooth) {
        final bt = outputs.where((d) =>
            d.label.toLowerCase().contains('bluetooth') ||
            d.deviceId.toLowerCase().contains('bluetooth')).firstOrNull;
        if (bt != null) {
          await Helper.selectAudioOutput(bt.deviceId);
          return AudioOutputRoute.bluetooth;
        }
      }

      if (route == AudioOutputRoute.wiredHeadset) {
        final wired = outputs.where((d) =>
            d.label.toLowerCase().contains('wired') ||
            d.label.toLowerCase().contains('headset') ||
            d.deviceId.toLowerCase().contains('wired')).firstOrNull;
        if (wired != null) {
          await Helper.selectAudioOutput(wired.deviceId);
          return AudioOutputRoute.wiredHeadset;
        }
      }

      final earpiece = outputs.where((d) =>
          d.label.toLowerCase().contains('earpiece') ||
          d.deviceId.toLowerCase().contains('earpiece')).firstOrNull;
      if (earpiece != null) {
        await Helper.selectAudioOutput(earpiece.deviceId);
      }
      return AudioOutputRoute.earpiece;
    } catch (e) {
      debugPrint('[CallWebRtcEngine] setAudioOutput($route) error: $e');
      return AudioOutputRoute.earpiece;
    }
  }

  Future<void> refreshAudioRoutes() async {
    if (kIsWeb) {
      onAudioRoutesChanged?.call(
        const [AudioOutputRoute.browserDefault],
        AudioOutputRoute.browserDefault,
      );
      return;
    }

    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      final outputs = devices.where((d) => d.kind == 'audiooutput').toList();
      final routes = <AudioOutputRoute>[
        AudioOutputRoute.earpiece,
        AudioOutputRoute.speaker,
      ];
      AudioOutputRoute active = AudioOutputRoute.earpiece;

      final hasBluetooth = outputs.any((d) =>
          d.label.toLowerCase().contains('bluetooth') ||
          d.deviceId.toLowerCase().contains('bluetooth'));
      final hasWired = outputs.any((d) =>
          d.label.toLowerCase().contains('wired') ||
          d.label.toLowerCase().contains('headset') ||
          d.deviceId.toLowerCase().contains('wired'));

      if (hasWired) {
        routes.add(AudioOutputRoute.wiredHeadset);
        active = AudioOutputRoute.wiredHeadset;
      }
      if (hasBluetooth) {
        routes.add(AudioOutputRoute.bluetooth);
        active = AudioOutputRoute.bluetooth;
      }

      onAudioRoutesChanged?.call(routes, active);
    } catch (_) {
      onAudioRoutesChanged?.call(
        const [AudioOutputRoute.earpiece, AudioOutputRoute.speaker],
        AudioOutputRoute.earpiece,
      );
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    try {
      navigator.mediaDevices.ondevicechange = null;
    } catch (_) {}

    try {
      for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;

    try {
      for (final track in _remoteStream?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }
      await _remoteStream?.dispose();
    } catch (_) {}
    _remoteStream = null;

    try {
      _remoteRenderer?.srcObject = null;
      await _remoteRenderer?.dispose();
    } catch (_) {}
    _remoteRenderer = null;

    try {
      await _peerConnection?.close();
      await _peerConnection?.dispose();
    } catch (_) {}
    _peerConnection = null;

    if (!kIsWeb) {
      try {
        await Helper.setSpeakerphoneOn(false);
      } catch (_) {}
    }
    _pendingRemoteCandidates.clear();
  }
}
