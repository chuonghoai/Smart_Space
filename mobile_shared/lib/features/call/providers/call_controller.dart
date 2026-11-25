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
  CallController({
    CallWsService? wsService,
    CallApiService? apiService,
    CallWebRtcEngine Function()? engineFactory,
    bool Function()? isWsConnected,
    Duration setupSyncInterval = const Duration(seconds: 3),
  })  : _wsService = wsService ?? callWsService,
        _apiService = apiService ?? callApiService,
        _engineFactory = engineFactory ?? (() => CallWebRtcEngine()),
        _isWsConnected = isWsConnected ?? (() => webSocketService.isConnected),
        _setupSyncInterval = setupSyncInterval,
        super(const CallState()) {
    _wsSub = _wsService.events.listen(_handleWsEvent);
    webSocketService.addListener(_onWebSocketStateChanged);
    if (_isWsConnected()) {
      _wsService.ensureSubscribed();
    }
  }

  final CallWsService _wsService;
  final CallApiService _apiService;
  final CallWebRtcEngine Function() _engineFactory;
  final bool Function() _isWsConnected;
  final Duration _setupSyncInterval;

  StreamSubscription<Map<String, dynamic>>? _wsSub;
  CallWebRtcEngine? _engine;
  List<IceServerModel> _iceServers = const [];
  Timer? _durationTimer;
  Timer? _disconnectGraceTimer;
  Timer? _autoDismissTimer;
  Timer? _setupSyncTimer;
  bool _ringingAckSent = false;
  bool _connectedSent = false;
  bool _acceptedLocally = false;
  bool _isAppForeground = true;
  bool _isDisposed = false;
  bool _isEngineReady = false;
  String? _engineCallId;
  bool _offerStarted = false;
  bool _isFlushingSignals = false;
  bool _isSyncingSetupState = false;
  final List<Map<String, dynamic>> _pendingSignals = [];
  final Map<String, List<Map<String, dynamic>>> _earlyWsEventsByCallId = {};

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

    final res = await _apiService.getCallStatus(callId);
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
    if (_isDisposed) return;
    if (_isWsConnected()) {
      _wsService.ensureSubscribed();
      return;
    }
    if (state.status == CallStatus.connecting ||
        state.status == CallStatus.ringing ||
        state.status == CallStatus.incoming ||
        state.status == CallStatus.accepted) {
      final callId = state.callId;
      if (callId != null && !callId.startsWith('pending_')) {
        _apiService.markFailed(callId, reason: 'WS_DISCONNECTED');
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

    if (!_isWsConnected() || !_wsService.ensureSubscribed()) {
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

    final res = await _apiService.initiateCall(
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
    _startSetupSyncTimer(session.callId);

    final earlyEvents = _earlyWsEventsByCallId.remove(session.callId);
    if (earlyEvents != null && earlyEvents.isNotEmpty) {
      for (final ev in earlyEvents) {
        await _handleWsEvent(ev);
        if (_isDisposed ||
            state.callId != session.callId ||
            state.status.isTerminal) {
          break;
        }
      }
    }
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

    final sentWs = _wsService.sendRinging(callId);
    if (!sentWs) {
      await _apiService.acknowledgeRinging(callId);
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

    final res = await _apiService.acceptCall(callId);
    if (!res.success || res.data == null) {
      _transitionToTerminal(CallStatus.failed, errorMessage: res.message);
      return;
    }

    final session = res.data!;
    _iceServers = session.iceServers;
    state = state.copyWith(status: CallStatus.accepted, clearError: true);
    _startSetupSyncTimer(callId);

    await _initEngine(callId);
  }

  Future<void> rejectIncomingCall({String? reason}) async {
    final callId = state.callId;
    if (callId == null) return;
    _acceptedLocally = false;
    await callRingtoneService.stopRinging(callId);
    await FirebaseService.dismissActiveWsCallNotice(callId);

    final sentWs = _wsService.sendReject(callId, reason: reason);
    if (!sentWs) {
      await _apiService.rejectCall(callId, reason: reason);
    }
    _transitionToTerminal(CallStatus.rejected, immediate: true);
  }

  Future<void> cancelOutgoingCall() async {
    final callId = state.callId;
    if (callId == null) return;
    if (!callId.startsWith('pending_')) {
      final sentWs = _wsService.sendCancel(callId);
      if (!sentWs) {
        await _apiService.cancelCall(callId);
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
      final sentWs = _wsService.sendEnd(callId, reason: reason);
      if (!sentWs) {
        await _apiService.endCall(callId, reason: reason);
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
    _isEngineReady = false;
    _engineCallId = callId;
    await _engine?.dispose();
    final engine = _engineFactory();
    _engine = engine;

    engine.onIceCandidate = (candidate) {
      final sent = _wsService.sendSignal(
        callId: callId,
        signalType: 'ICE_CANDIDATE',
        candidate: candidate.candidate,
        sdpMid: candidate.sdpMid,
        sdpMLineIndex: candidate.sdpMLineIndex,
      );
      if (!sent) {
        _apiService.relaySignal(
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
          final sent = _wsService.sendConnected(callId);
          if (!sent) {
            _apiService.markConnected(callId);
          }
          _enterOngoingState();
        }
      } else if (rtcState ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _disconnectGraceTimer?.cancel();
        _disconnectGraceTimer = Timer(const Duration(seconds: 8), () {
          if (!_isDisposed && state.callId == callId && state.hasActiveCall) {
            _apiService.markFailed(callId, reason: 'NETWORK_LOST');
            _transitionToTerminal(CallStatus.failed);
          }
        });
      } else if (rtcState ==
          RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _apiService.markFailed(callId, reason: 'ICE_FAILED');
        _transitionToTerminal(CallStatus.failed);
      }
    };

    try {
      await engine.initialize(iceServers: _iceServers);
      if (_isDisposed || state.callId != callId || _engine != engine) {
        await engine.dispose();
        return;
      }
      _isEngineReady = true;
      state = state.copyWith(isMuted: engine.isMuted);
      await _flushPendingSignals(callId);
    } catch (e) {
      debugPrint('[CallController] Engine init failed: $e');
      if (!_isDisposed && state.callId == callId) {
        await _apiService.markFailed(callId, reason: 'MEDIA_INIT_FAILED');
        _transitionToTerminal(CallStatus.failed, errorMessage: e.toString());
      }
    }
  }

  void _enterOngoingState() {
    _setupSyncTimer?.cancel();
    _setupSyncTimer = null;
    if (state.status == CallStatus.ongoing) return;
    state = state.copyWith(status: CallStatus.ongoing, elapsedSeconds: 0);
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isDisposed && state.status == CallStatus.ongoing) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void _startSetupSyncTimer(String callId) {
    _setupSyncTimer?.cancel();
    if (callId.startsWith('pending_')) return;
    _setupSyncTimer = Timer.periodic(_setupSyncInterval, (_) {
      _syncCallSetupState(callId);
    });
  }

  Future<void> _syncCallSetupState(String callId) async {
    if (_isDisposed ||
        state.callId != callId ||
        !state.hasActiveCall ||
        state.status == CallStatus.ongoing) {
      _setupSyncTimer?.cancel();
      _setupSyncTimer = null;
      return;
    }
    if (_isSyncingSetupState) return;
    _isSyncingSetupState = true;
    try {
      final res = await _apiService.getCallStatus(callId);
      if (_isDisposed || state.callId != callId || !state.hasActiveCall) {
        return;
      }
      if (!res.success || res.data == null) return;

      final remote = res.data!;
      if (remote.status.isTerminal) {
        debugPrint(
          '[CallController] Watchdog synced terminal state ${remote.status} for call $callId',
        );
        _transitionToTerminal(
          remote.status,
          immediate: !state.isOutgoing && state.status == CallStatus.incoming,
          errorMessage: remote.endReason,
        );
        return;
      }

      if (state.isOutgoing &&
          remote.status == CallStatus.ringing &&
          state.status == CallStatus.connecting) {
        state = state.copyWith(status: CallStatus.ringing);
      } else if (state.isOutgoing &&
          remote.status == CallStatus.accepted &&
          !_offerStarted) {
        if (remote.iceServers.isNotEmpty) {
          _iceServers = remote.iceServers;
        }
        debugPrint('[CallController] Watchdog recovered missed CALL_ACCEPTED for $callId');
        await _startOutgoingWebRtcOffer(callId);
      } else if (remote.status == CallStatus.ongoing) {
        _enterOngoingState();
      }
    } catch (e) {
      debugPrint('[CallController] Setup sync check error: $e');
    } finally {
      _isSyncingSetupState = false;
    }
  }

  Future<void> _startOutgoingWebRtcOffer(String callId) async {
    if (_isDisposed ||
        state.callId != callId ||
        !state.isOutgoing ||
        _offerStarted) {
      return;
    }
    _offerStarted = true;
    state = state.copyWith(status: CallStatus.accepted);
    await _initEngine(callId);
    if (_isDisposed ||
        state.callId != callId ||
        !_isEngineReady ||
        _engine == null ||
        !_engine!.isInitialized) {
      return;
    }
    try {
      final offer = await _engine!.createOffer();
      final sent = _wsService.sendSignal(
        callId: callId,
        signalType: 'OFFER',
        sdp: offer.sdp,
      );
      if (!sent) {
        await _apiService.relaySignal(
          callId: callId,
          signalType: 'OFFER',
          sdp: offer.sdp,
        );
      }
    } catch (e) {
      debugPrint('[CallController] Failed creating/sending OFFER: $e');
      if (!_isDisposed && state.callId == callId) {
        await _apiService.markFailed(callId, reason: 'SIGNALING_ERROR');
        _transitionToTerminal(CallStatus.failed, errorMessage: e.toString());
      }
    }
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
      _startSetupSyncTimer(callId);

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
          _wsService.sendRinging(callId);
        }
      }
      return;
    }

    if (callId.isNotEmpty &&
        state.callId != callId &&
        state.isOutgoing &&
        state.status == CallStatus.connecting &&
        (state.callId?.startsWith('pending_') ?? false)) {
      _earlyWsEventsByCallId
          .putIfAbsent(callId, () => [])
          .add(Map<String, dynamic>.from(event));
      debugPrint('[CallController] Buffered early WS event $eventType for $callId');
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
          await _startOutgoingWebRtcOffer(callId);
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
    if (_engine == null ||
        !_engine!.isInitialized ||
        !_isEngineReady ||
        _engineCallId != callId) {
      _pendingSignals.add(Map<String, dynamic>.from(event));
      debugPrint(
        '[CallController] Buffered ${event['signalType']} for call $callId (pending=${_pendingSignals.length})',
      );
      return;
    }
    await _processSignalEvent(callId, event);
  }

  Future<void> _processSignalEvent(String callId, Map<String, dynamic> event) async {
    if (_isDisposed ||
        state.callId != callId ||
        _engine == null ||
        !_engine!.isInitialized) {
      return;
    }
    final signalType = event['signalType']?.toString() ?? '';
    try {
      if (signalType == 'OFFER') {
        final sdp = event['sdp']?.toString() ?? '';
        final answer = await _engine!.handleRemoteOfferAndCreateAnswer(sdp);
        final sent = _wsService.sendSignal(
          callId: callId,
          signalType: 'ANSWER',
          sdp: answer.sdp,
        );
        if (!sent) {
          await _apiService.relaySignal(
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

  Future<void> _flushPendingSignals(String callId) async {
    if (_isFlushingSignals) return;
    _isFlushingSignals = true;
    try {
      while (!_isDisposed &&
          _isEngineReady &&
          state.callId == callId &&
          _pendingSignals.isNotEmpty) {
        int nextIndex = _pendingSignals.indexWhere((e) {
          final t = e['signalType']?.toString() ?? '';
          return t == 'OFFER' || t == 'ANSWER';
        });
        if (nextIndex < 0) {
          nextIndex = 0;
        }
        final nextEvent = _pendingSignals.removeAt(nextIndex);
        await _processSignalEvent(callId, nextEvent);
      }
    } finally {
      _isFlushingSignals = false;
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
    _setupSyncTimer?.cancel();
    _setupSyncTimer = null;
    _isSyncingSetupState = false;
    _isEngineReady = false;
    _engineCallId = null;
    _offerStarted = false;
    _pendingSignals.clear();
    _earlyWsEventsByCallId.clear();
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
