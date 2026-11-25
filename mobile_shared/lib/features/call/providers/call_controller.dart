import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mobile_shared/core/connection/connection_manager.dart';
import 'package:mobile_shared/core/notification/firebase_service.dart';
import 'package:mobile_shared/core/toast/toast_service.dart';
import 'package:mobile_shared/core/websocket/websocket_service.dart';
import 'package:mobile_shared/features/call/data/call_api_service.dart';
import 'package:mobile_shared/features/call/models/call_models.dart';
import 'package:mobile_shared/features/call/services/call_ringtone_service.dart';
import 'package:mobile_shared/features/call/services/call_webrtc_engine.dart';
import 'package:mobile_shared/features/call/services/call_ws_service.dart';
import 'package:mobile_shared/l10n/generated/shared_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class CallState {
  final String? callId;
  final String? conversationId;
  final CallStatus status;
  final bool isOutgoing;
  final CallPeerModel? peer;
  final bool isMuted;
  final AudioOutputRoute activeAudioRoute;
  final List<AudioOutputRoute> availableAudioRoutes;
  final int elapsedSeconds;
  final String? errorKey;
  final String? errorMessage;
  final bool isScreenPresented;

  const CallState({
    this.callId,
    this.conversationId,
    this.status = CallStatus.idle,
    this.isOutgoing = true,
    this.peer,
    this.isMuted = false,
    this.activeAudioRoute = AudioOutputRoute.earpiece,
    this.availableAudioRoutes = const [
      AudioOutputRoute.earpiece,
      AudioOutputRoute.speaker,
    ],
    this.elapsedSeconds = 0,
    this.errorKey,
    this.errorMessage,
    this.isScreenPresented = false,
  });

  bool get hasActiveCall => status.isActive;

  CallState copyWith({
    String? callId,
    String? conversationId,
    CallStatus? status,
    bool? isOutgoing,
    CallPeerModel? peer,
    bool? isMuted,
    AudioOutputRoute? activeAudioRoute,
    List<AudioOutputRoute>? availableAudioRoutes,
    int? elapsedSeconds,
    String? errorKey,
    String? errorMessage,
    bool? isScreenPresented,
    bool clearError = false,
  }) {
    return CallState(
      callId: callId ?? this.callId,
      conversationId: conversationId ?? this.conversationId,
      status: status ?? this.status,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      peer: peer ?? this.peer,
      isMuted: isMuted ?? this.isMuted,
      activeAudioRoute: activeAudioRoute ?? this.activeAudioRoute,
      availableAudioRoutes: availableAudioRoutes ?? this.availableAudioRoutes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isScreenPresented: isScreenPresented ?? this.isScreenPresented,
    );
  }
}

class CallController extends StateNotifier<CallState> {
  CallController() : super(const CallState()) {
    _wsSub = callWsService.events.listen(_handleWsEvent);
    webSocketService.addListener(_onWebSocketStateChanged);
  }

  StreamSubscription<Map<String, dynamic>>? _wsSub;
  CallWebRtcEngine? _engine;
  List<IceServerModel> _iceServers = const [];
  Timer? _durationTimer;
  Timer? _disconnectGraceTimer;
  Timer? _autoDismissTimer;
  bool _ringingAckSent = false;
  bool _connectedSent = false;
  bool _acceptedLocally = false;
  bool _isAppForeground = true;
  bool _isDisposed = false;

  void Function(String callId)? onCallScreenRequested;
  RTCVideoRenderer? get remoteRenderer => _engine?.remoteRenderer;

  void onAppLifecycleChanged(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      onAppResumed();
    } else if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.hidden ||
        lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.detached) {
      _isAppForeground = false;
    }
  }

  Future<void> onAppResumed() async {
    _isAppForeground = true;
    final callId = state.callId;
    if (!state.hasActiveCall ||
        callId == null ||
        callId.startsWith('pending_')) {
      return;
    }

    final res = await callApiService.getCallStatus(callId);
    if (_isDisposed) return;

    if (!res.success || res.data == null) {
      await FirebaseService.dismissActiveWsCallNotice(callId);
      _transitionToTerminal(CallStatus.failed, immediate: true);
      return;
    }

    final remote = res.data!;
    if (remote.status.isTerminal) {
      await FirebaseService.dismissActiveWsCallNotice(callId);
      _transitionToTerminal(
        remote.status,
        immediate: !state.isOutgoing && state.status == CallStatus.incoming,
      );
      return;
    }

    if (!state.isOutgoing &&
        state.status == CallStatus.incoming &&
        (remote.status == CallStatus.connecting ||
            remote.status == CallStatus.ringing)) {
      await FirebaseService.dismissActiveWsCallNotice(callId);
      onCallScreenRequested?.call(callId);
      await callRingtoneService.startRinging(callId);
    }
  }

  void openActiveCallFromNotice(String callId) {
    if (callId.isEmpty || state.callId != callId || !state.hasActiveCall) {
      return;
    }
    FirebaseService.dismissActiveWsCallNotice(callId);
    onCallScreenRequested?.call(callId);
    if (!state.isOutgoing && state.status == CallStatus.incoming) {
      callRingtoneService.startRinging(callId);
    }
  }

  void _onWebSocketStateChanged() {
    if (_isDisposed || webSocketService.isConnected) return;
    if (state.status == CallStatus.connecting ||
        state.status == CallStatus.ringing ||
        state.status == CallStatus.incoming ||
        state.status == CallStatus.accepted) {
      final callId = state.callId;
      if (callId != null && !callId.startsWith('pending_')) {
        callApiService.markFailed(callId, reason: 'WS_DISCONNECTED');
      }
      _transitionToTerminal(CallStatus.failed);
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    if (kIsWeb) {
      return true;
    }
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final requested = await Permission.microphone.request();
    return requested.isGranted;
  }

  Future<bool> startCall({
    required String targetUserId,
    String? conversationId,
    bool? isAnonymous,
    required String peerName,
    String? peerAvatar,
    String? peerRole,
  }) async {
    if (state.hasActiveCall) return false;

    final requestedPeer = CallPeerModel(
      id: targetUserId,
      fullName: peerName,
      avatarUrl: peerAvatar,
      role: peerRole,
      isAnonymous: isAnonymous ?? false,
    );

    if (!webSocketService.isConnected) {
      _showImmediateConnectFailure(requestedPeer, conversationId);
      return false;
    }

    final hasMic = await _ensureMicrophonePermission();
    if (!hasMic) {
      state = state.copyWith(errorKey: 'callMicPermissionDenied');
      return false;
    }

    _cleanupTimersAndEngine();
    _ringingAckSent = false;
    _connectedSent = false;
    _acceptedLocally = false;

    final pendingId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    connectionManager.setKeepAliveForActiveCall(true);

    state = CallState(
      callId: pendingId,
      conversationId: conversationId,
      status: CallStatus.connecting,
      isOutgoing: true,
      peer: requestedPeer,
      activeAudioRoute:
          kIsWeb ? AudioOutputRoute.browserDefault : AudioOutputRoute.earpiece,
      isScreenPresented: true,
    );
    onCallScreenRequested?.call(pendingId);

    final res = await callApiService.initiateCall(
      receiverId: targetUserId,
      conversationId: conversationId,
      isAnonymous: isAnonymous,
    );

    if (_isDisposed) return false;

    if (!res.success || res.data == null) {
      _transitionToTerminal(
        CallStatus.failed,
        errorMessage: res.message,
      );
      return false;
    }

    final session = res.data!;
    _iceServers = session.iceServers;

    state = state.copyWith(
      callId: session.callId,
      conversationId: session.conversationId ?? conversationId,
      peer: session.peer ?? requestedPeer,
      isScreenPresented: true,
      clearError: true,
    );
    return true;
  }

  void _showImmediateConnectFailure(
    CallPeerModel peer,
    String? conversationId,
  ) {
    _cleanupTimersAndEngine();
    final failedId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    state = CallState(
      callId: failedId,
      conversationId: conversationId,
      status: CallStatus.failed,
      isOutgoing: true,
      peer: peer,
      activeAudioRoute:
          kIsWeb ? AudioOutputRoute.browserDefault : AudioOutputRoute.earpiece,
      isScreenPresented: true,
    );
    onCallScreenRequested?.call(failedId);

    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 2), () {
      if (!_isDisposed && state.callId == failedId && state.status.isTerminal) {
        state = const CallState();
      }
    });
  }

  /// Must be called when the receiver's Incoming Call UI is mounted & visible.
  Future<void> confirmIncomingUiReady(String callId) async {
    if (state.callId != callId ||
        state.isOutgoing ||
        state.status != CallStatus.incoming ||
        _ringingAckSent) {
      return;
    }
    _ringingAckSent = true;

    await callRingtoneService.startRinging(callId);

    final sentWs = callWsService.sendRinging(callId);
    if (!sentWs) {
      await callApiService.acknowledgeRinging(callId);
    }
  }

  Future<void> acceptIncomingCall() async {
    final callId = state.callId;
    if (callId == null || state.isOutgoing) return;

    _acceptedLocally = true;
    await callRingtoneService.stopRinging(callId);
    await FirebaseService.dismissActiveWsCallNotice(callId);

    final hasMic = await _ensureMicrophonePermission();
    if (!hasMic) {
      await rejectIncomingCall(reason: 'MIC_PERMISSION_DENIED');
      state = state.copyWith(errorKey: 'callMicPermissionDenied');
      return;
    }

    final res = await callApiService.acceptCall(callId);
    if (!res.success || res.data == null) {
      _transitionToTerminal(CallStatus.failed, errorMessage: res.message);
      return;
    }

    final session = res.data!;
    _iceServers = session.iceServers;
    state = state.copyWith(status: CallStatus.accepted, clearError: true);

    await _initEngine(callId);
  }

  Future<void> rejectIncomingCall({String? reason}) async {
    final callId = state.callId;
    if (callId == null) return;
    _acceptedLocally = false;
    await callRingtoneService.stopRinging(callId);
    await FirebaseService.dismissActiveWsCallNotice(callId);

    final sentWs = callWsService.sendReject(callId, reason: reason);
    if (!sentWs) {
      await callApiService.rejectCall(callId, reason: reason);
    }
    _transitionToTerminal(CallStatus.rejected, immediate: true);
  }

  Future<void> cancelOutgoingCall() async {
    final callId = state.callId;
    if (callId == null) return;
    if (!callId.startsWith('pending_')) {
      final sentWs = callWsService.sendCancel(callId);
      if (!sentWs) {
        await callApiService.cancelCall(callId);
      }
    }
    _transitionToTerminal(CallStatus.cancelled, immediate: true);
  }

  Future<void> endActiveCall({String? reason}) async {
    final callId = state.callId;
    if (callId == null) return;
    await callRingtoneService.stopRinging(callId);
    await FirebaseService.dismissActiveWsCallNotice(callId);

    if (!state.isOutgoing && state.status == CallStatus.incoming) {
      await rejectIncomingCall(reason: reason);
      return;
    }
    if (state.isOutgoing &&
        (state.status == CallStatus.connecting ||
            state.status == CallStatus.ringing)) {
      await cancelOutgoingCall();
      return;
    }

    if (!callId.startsWith('pending_')) {
      final sentWs = callWsService.sendEnd(callId, reason: reason);
      if (!sentWs) {
        await callApiService.endCall(callId, reason: reason);
      }
    }
    _transitionToTerminal(CallStatus.ended, immediate: true);
  }

  void toggleMute() {
    if (_engine == null) return;
    final nextMuted = !_engine!.isMuted;
    final actualMuted = _engine!.setMuted(nextMuted);
    state = state.copyWith(isMuted: actualMuted);
  }

  Future<void> selectAudioOutput(AudioOutputRoute route) async {
    if (_engine == null) return;
    final applied = await _engine!.setAudioOutput(route);
    state = state.copyWith(activeAudioRoute: applied);
  }

  Future<void> _initEngine(String callId) async {
    await _engine?.dispose();
    final engine = CallWebRtcEngine();
    _engine = engine;

    engine.onIceCandidate = (candidate) {
      final sent = callWsService.sendSignal(
        callId: callId,
        signalType: 'ICE_CANDIDATE',
        candidate: candidate.candidate,
        sdpMid: candidate.sdpMid,
        sdpMLineIndex: candidate.sdpMLineIndex,
      );
      if (!sent) {
        callApiService.relaySignal(
          callId: callId,
          signalType: 'ICE_CANDIDATE',
          candidate: candidate.candidate,
          sdpMid: candidate.sdpMid,
          sdpMLineIndex: candidate.sdpMLineIndex,
        );
      }
    };

    engine.onAudioRoutesChanged = (routes, active) {
      if (!_isDisposed && state.callId == callId) {
        state = state.copyWith(
          availableAudioRoutes: routes,
          activeAudioRoute: active,
        );
      }
    };

    engine.onPeerConnectionStateChanged = (rtcState) {
      if (_isDisposed || state.callId != callId) return;
      if (rtcState == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _disconnectGraceTimer?.cancel();
        if (!_connectedSent) {
          _connectedSent = true;
          final sent = callWsService.sendConnected(callId);
          if (!sent) {
            callApiService.markConnected(callId);
          }
          _enterOngoingState();
        }
      } else if (rtcState ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _disconnectGraceTimer?.cancel();
        _disconnectGraceTimer = Timer(const Duration(seconds: 8), () {
          if (!_isDisposed && state.callId == callId && state.hasActiveCall) {
            callApiService.markFailed(callId, reason: 'NETWORK_LOST');
            _transitionToTerminal(CallStatus.failed);
          }
        });
      } else if (rtcState ==
          RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        callApiService.markFailed(callId, reason: 'ICE_FAILED');
        _transitionToTerminal(CallStatus.failed);
      }
    };

    try {
      await engine.initialize(iceServers: _iceServers);
      state = state.copyWith(isMuted: engine.isMuted);
    } catch (e) {
      debugPrint('[CallController] Engine init failed: $e');
      await callApiService.markFailed(callId, reason: 'MEDIA_INIT_FAILED');
      _transitionToTerminal(CallStatus.failed, errorMessage: e.toString());
    }
  }

  void _enterOngoingState() {
    if (state.status == CallStatus.ongoing) return;
    state = state.copyWith(status: CallStatus.ongoing, elapsedSeconds: 0);
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isDisposed && state.status == CallStatus.ongoing) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  Future<void> _handleWsEvent(Map<String, dynamic> event) async {
    if (_isDisposed) return;
    final eventType = event['eventType']?.toString() ?? '';
    final callId = event['callId']?.toString() ?? '';

    if (eventType == 'CALL_INCOMING') {
      if (callId.isEmpty || (state.hasActiveCall && state.callId != callId)) {
        return;
      }

      final peerMap = event['peer'] as Map<String, dynamic>?;
      final peer = peerMap != null
          ? CallPeerModel.fromJson(peerMap)
          : CallPeerModel(
              id: event['callerId']?.toString() ?? '',
              fullName: '',
              isAnonymous: event['isAnonymous'] == true,
            );

      _cleanupTimersAndEngine();
      _ringingAckSent = false;
      _connectedSent = false;
      _acceptedLocally = false;
      connectionManager.setKeepAliveForActiveCall(true);

      state = CallState(
        callId: callId,
        conversationId: event['conversationId']?.toString(),
        status: CallStatus.incoming,
        isOutgoing: false,
        peer: peer,
        activeAudioRoute:
            kIsWeb ? AudioOutputRoute.browserDefault : AudioOutputRoute.earpiece,
        isScreenPresented: _isAppForeground,
      );

      if (_isAppForeground) {
        onCallScreenRequested?.call(callId);
      } else {
        final ctx = sharedNavigatorKey.currentContext;
        final l10n = ctx != null ? SharedLocalizations.of(ctx) : null;
        final callerName = peer.isAnonymous
            ? (l10n?.callAnonymousUser ?? '')
            : peer.fullName;
        final title = l10n?.callStatusIncoming ?? 'SmartSpace';
        final body = callerName.isNotEmpty ? callerName : title;
        final shown = await FirebaseService.showActiveWsCallNotice(
          callId: callId,
          title: title,
          body: body,
        );
        if (shown && !_ringingAckSent && state.callId == callId) {
          _ringingAckSent = true;
          callWsService.sendRinging(callId);
        }
      }
      return;
    }

    if (callId.isEmpty || state.callId != callId) return;

    switch (eventType) {
      case 'CALL_RINGING':
        if (state.isOutgoing && state.status == CallStatus.connecting) {
          state = state.copyWith(status: CallStatus.ringing);
        }
        break;

      case 'CALL_ACCEPTED':
        if (state.isOutgoing &&
            (state.status == CallStatus.connecting ||
                state.status == CallStatus.ringing)) {
          state = state.copyWith(status: CallStatus.accepted);
          await _initEngine(callId);
          if (_engine != null) {
            final offer = await _engine!.createOffer();
            final sent = callWsService.sendSignal(
              callId: callId,
              signalType: 'OFFER',
              sdp: offer.sdp,
            );
            if (!sent) {
              await callApiService.relaySignal(
                callId: callId,
                signalType: 'OFFER',
                sdp: offer.sdp,
              );
            }
          }
        }
        break;

      case 'CALL_SIGNAL':
        await _handleSignalEvent(callId, event);
        break;

      case 'CALL_ONGOING':
        _enterOngoingState();
        break;

      case 'CALL_REJECTED':
        _transitionToTerminal(CallStatus.rejected);
        break;

      case 'CALL_CANCELLED':
        _transitionToTerminal(CallStatus.cancelled, immediate: !state.isOutgoing);
        break;

      case 'CALL_HANDLED_ELSEWHERE':
        if (!_acceptedLocally) {
          _transitionToTerminal(CallStatus.ended, immediate: true);
        }
        break;

      case 'CALL_MISSED':
        _transitionToTerminal(CallStatus.missed);
        break;

      case 'CALL_ENDED':
        _transitionToTerminal(CallStatus.ended);
        break;

      case 'CALL_FAILED':
      case 'CALL_ERROR':
        _transitionToTerminal(
          CallStatus.failed,
          errorMessage: (event['endReason'] ?? event['error'])?.toString(),
        );
        break;
    }
  }

  Future<void> _handleSignalEvent(String callId, Map<String, dynamic> event) async {
    if (_engine == null) return;
    final signalType = event['signalType']?.toString() ?? '';
    try {
      if (signalType == 'OFFER') {
        final sdp = event['sdp']?.toString() ?? '';
        final answer = await _engine!.handleRemoteOfferAndCreateAnswer(sdp);
        final sent = callWsService.sendSignal(
          callId: callId,
          signalType: 'ANSWER',
          sdp: answer.sdp,
        );
        if (!sent) {
          await callApiService.relaySignal(
            callId: callId,
            signalType: 'ANSWER',
            sdp: answer.sdp,
          );
        }
      } else if (signalType == 'ANSWER') {
        final sdp = event['sdp']?.toString() ?? '';
        await _engine!.handleRemoteAnswer(sdp);
      } else if (signalType == 'ICE_CANDIDATE') {
        final candidate = event['candidate']?.toString() ?? '';
        final sdpMid = event['sdpMid']?.toString();
        final sdpMLineIndex = (event['sdpMLineIndex'] as num?)?.toInt();
        await _engine!.addRemoteIceCandidate(
          candidate: candidate,
          sdpMid: sdpMid,
          sdpMLineIndex: sdpMLineIndex,
        );
      }
    } catch (e) {
      debugPrint('[CallController] Signal handling error ($signalType): $e');
    }
  }

  void _transitionToTerminal(
    CallStatus terminalStatus, {
    bool immediate = false,
    String? errorMessage,
  }) {
    final callId = state.callId;
    if (callId != null) {
      callRingtoneService.stopRinging(callId);
      FirebaseService.dismissActiveWsCallNotice(callId);
    }
    _acceptedLocally = false;
    _cleanupTimersAndEngine();
    connectionManager.setKeepAliveForActiveCall(false);

    if (immediate) {
      state = const CallState();
      return;
    }

    state = state.copyWith(
      status: terminalStatus,
      errorMessage: errorMessage,
    );

    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 2), () {
      if (!_isDisposed && state.status.isTerminal) {
        state = const CallState();
      }
    });
  }

  void dismissCallUi() {
    _autoDismissTimer?.cancel();
    if (!state.hasActiveCall) {
      state = const CallState();
    }
  }

  Future<void> cleanupOnLogout() async {
    if (state.hasActiveCall && state.callId != null) {
      await endActiveCall(reason: 'LOGOUT');
    }
    _cleanupTimersAndEngine();
    await callRingtoneService.stopRinging();
    connectionManager.setKeepAliveForActiveCall(false);
    state = const CallState();
  }

  void _cleanupTimersAndEngine() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _disconnectGraceTimer?.cancel();
    _disconnectGraceTimer = null;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _engine?.dispose();
    _engine = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    webSocketService.removeListener(_onWebSocketStateChanged);
    _wsSub?.cancel();
    _cleanupTimersAndEngine();
    callRingtoneService.stopRinging();
    connectionManager.setKeepAliveForActiveCall(false);
    super.dispose();
  }
}

final callControllerProvider =
    StateNotifierProvider<CallController, CallState>((ref) => CallController());
