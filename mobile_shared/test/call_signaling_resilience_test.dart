import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/websocket/ws_feature_service.dart';
import 'package:mobile_shared/features/call/data/call_api_service.dart';
import 'package:mobile_shared/features/call/models/call_models.dart';
import 'package:mobile_shared/features/call/providers/call_controller.dart';
import 'package:mobile_shared/features/call/services/call_webrtc_engine.dart';
import 'package:mobile_shared/features/call/services/call_ws_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    const permissionChannel = MethodChannel('flutter.baseflow.com/permissions/methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
      if (call.method == 'checkPermissionStatus') {
        return 1; // PermissionStatus.granted
      }
      if (call.method == 'requestPermissions') {
        return <int, int>{7: 1}; // microphone granted
      }
      return 1;
    });
  });

  group('WsServicesRegistry resilience', () {
    test('resetAll preserves registered services so setupAll re-subscribes later', () {
      final service = _FakeWsFeatureService();
      WsServicesRegistry.register(service);

      expect(WsServicesRegistry.registeredCount, greaterThanOrEqualTo(1));

      WsServicesRegistry.setupAll();
      expect(service.setupCount, 1);

      WsServicesRegistry.resetAll();
      expect(service.resetCount, 1);
      expect(service.disposeCount, 0);
      expect(WsServicesRegistry.registeredCount, greaterThanOrEqualTo(1));

      WsServicesRegistry.setupAll();
      expect(service.setupCount, 2);
    });
  });

  group('CallController signaling resilience', () {
    test('buffers OFFER and ICE_CANDIDATE arriving before engine initialization completes', () async {
      final fakeWs = _FakeCallWsService();
      final fakeApi = _FakeCallApiService();
      final initCompleter = Completer<void>();
      final fakeEngine = _FakeCallWebRtcEngine(initCompleter: initCompleter);

      final controller = CallController(
        wsService: fakeWs,
        apiService: fakeApi,
        engineFactory: () => fakeEngine,
        isWsConnected: () => true,
        setupSyncInterval: const Duration(seconds: 30),
      );

      // Simulate incoming call
      fakeWs.emit({
        'eventType': 'CALL_INCOMING',
        'callId': 'call-buffer-1',
        'callerId': 'u-caller',
        'peer': {'id': 'u-caller', 'fullName': 'Caller'},
      });
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.status, CallStatus.incoming);

      // Accept call (starts _initEngine which blocks on initCompleter)
      final acceptFuture = controller.acceptIncomingCall();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state.status, CallStatus.accepted);
      expect(fakeEngine.initializeCalled, isTrue);

      // Emit ICE_CANDIDATE *before* OFFER while engine is still initializing
      fakeWs.emit({
        'eventType': 'CALL_SIGNAL',
        'callId': 'call-buffer-1',
        'signalType': 'ICE_CANDIDATE',
        'candidate': 'candidate:1 1 UDP 2122252543 192.168.1.10 50000 typ host',
        'sdpMid': '0',
        'sdpMLineIndex': 0,
      });
      fakeWs.emit({
        'eventType': 'CALL_SIGNAL',
        'callId': 'call-buffer-1',
        'signalType': 'OFFER',
        'sdp': 'v=0\r\nfake-offer-sdp',
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Nothing processed prematurely while PeerConnection is not ready
      expect(fakeEngine.operations, isEmpty);
      expect(fakeWs.sentSignals, isEmpty);

      // Complete engine initialization -> buffered signals should flush with OFFER before ICE_CANDIDATE
      initCompleter.complete();
      await acceptFuture;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(fakeEngine.operations, ['offer', 'ice']);
      expect(fakeWs.sentSignals.length, 1);
      expect(fakeWs.sentSignals.first['signalType'], 'ANSWER');
      expect(fakeWs.sentSignals.first['sdp'], 'fake-answer-sdp');

      controller.dispose();
      fakeWs.close();
    });

    test('watchdog sync exits call screen when terminal WS event was missed', () async {
      final fakeWs = _FakeCallWsService();
      final fakeApi = _FakeCallApiService(
        pollStatusBuilder: (callId) => CallSessionModel(
          callId: callId,
          callerId: 'u-caller',
          receiverId: 'u-receiver',
          status: CallStatus.rejected,
          endReason: 'REJECTED_BY_RECEIVER',
        ),
      );

      final controller = CallController(
        wsService: fakeWs,
        apiService: fakeApi,
        engineFactory: () => _FakeCallWebRtcEngine(),
        isWsConnected: () => true,
        setupSyncInterval: const Duration(milliseconds: 25),
      );

      final started = await controller.startCall(
        targetUserId: 'u-receiver',
        peerName: 'Receiver',
      );
      expect(started, isTrue);
      expect(controller.state.status, CallStatus.connecting);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(controller.state.status, CallStatus.rejected);
      expect(controller.state.errorMessage, 'REJECTED_BY_RECEIVER');

      controller.dispose();
      fakeWs.close();
    });

    test('buffers early CALL_RINGING received while initiateCall is in pending state', () async {
      final fakeWs = _FakeCallWsService();
      final initiateCompleter = Completer<ApiResponse<CallSessionModel>>();
      final fakeApi = _FakeCallApiService(initiateCompleter: initiateCompleter);

      final controller = CallController(
        wsService: fakeWs,
        apiService: fakeApi,
        engineFactory: () => _FakeCallWebRtcEngine(),
        isWsConnected: () => true,
        setupSyncInterval: const Duration(seconds: 30),
      );

      final startFuture = controller.startCall(
        targetUserId: 'u-receiver',
        peerName: 'Receiver',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state.callId, startsWith('pending_'));

      // Backend emits CALL_RINGING before POST /calls HTTP response finishes returning to caller
      fakeWs.emit({
        'eventType': 'CALL_RINGING',
        'callId': 'call-early-1',
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state.status, CallStatus.connecting);

      initiateCompleter.complete(
        ApiResponse(
          success: true,
          message: 'ok',
          data: const CallSessionModel(
            callId: 'call-early-1',
            callerId: 'u-caller',
            receiverId: 'u-receiver',
            status: CallStatus.connecting,
          ),
        ),
      );

      final started = await startFuture;
      expect(started, isTrue);
      expect(controller.state.callId, 'call-early-1');
      expect(controller.state.status, CallStatus.ringing);

      controller.dispose();
      fakeWs.close();
    });
  });
}

class _FakeWsFeatureService implements WsFeatureService {
  int setupCount = 0;
  int resetCount = 0;
  int disposeCount = 0;

  @override
  void setup() => setupCount++;

  @override
  void reset() => resetCount++;

  @override
  void dispose() => disposeCount++;
}

class _FakeCallWsService extends CallWsService {
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  final List<Map<String, dynamic>> sentSignals = [];
  bool subscribed = false;

  @override
  Stream<Map<String, dynamic>> get events => _controller.stream;

  @override
  bool get isSubscribed => subscribed;

  @override
  bool ensureSubscribed() {
    subscribed = true;
    return true;
  }

  void emit(Map<String, dynamic> event) {
    _controller.add(event);
  }

  @override
  bool sendSignal({
    required String callId,
    required String signalType,
    String? sdp,
    String? candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) {
    sentSignals.add({
      'callId': callId,
      'signalType': signalType,
      'sdp': sdp,
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    });
    return true;
  }

  void close() {
    _controller.close();
  }
}

class _FakeCallApiService extends CallApiService {
  _FakeCallApiService({
    this.pollStatusBuilder,
    this.initiateCompleter,
  });

  final CallSessionModel Function(String callId)? pollStatusBuilder;
  final Completer<ApiResponse<CallSessionModel>>? initiateCompleter;

  @override
  Future<ApiResponse<CallSessionModel>> initiateCall({
    required String receiverId,
    String? conversationId,
    bool? isAnonymous,
  }) async {
    if (initiateCompleter != null) {
      return initiateCompleter!.future;
    }
    return ApiResponse(
      success: true,
      message: 'ok',
      data: CallSessionModel(
        callId: 'call-watchdog-1',
        callerId: 'u-caller',
        receiverId: receiverId,
        conversationId: conversationId,
        status: CallStatus.connecting,
      ),
    );
  }

  @override
  Future<ApiResponse<CallSessionModel>> acceptCall(String callId) async {
    return ApiResponse(
      success: true,
      message: 'ok',
      data: CallSessionModel(
        callId: callId,
        callerId: 'u-caller',
        receiverId: 'u-receiver',
        status: CallStatus.accepted,
      ),
    );
  }

  @override
  Future<ApiResponse<CallSessionModel>> getCallStatus(String callId) async {
    final model = pollStatusBuilder != null
        ? pollStatusBuilder!(callId)
        : CallSessionModel(
            callId: callId,
            callerId: 'u-caller',
            receiverId: 'u-receiver',
            status: CallStatus.connecting,
          );
    return ApiResponse(success: true, message: 'ok', data: model);
  }
}

class _FakeCallWebRtcEngine extends CallWebRtcEngine {
  _FakeCallWebRtcEngine({this.initCompleter});

  final Completer<void>? initCompleter;
  bool initializeCalled = false;
  bool _ready = false;
  final List<String> operations = [];

  @override
  bool get isInitialized => _ready;

  @override
  Future<void> initialize({required List<IceServerModel> iceServers}) async {
    initializeCalled = true;
    if (initCompleter != null) {
      await initCompleter!.future;
    }
    _ready = true;
  }

  @override
  Future<RTCSessionDescription> createOffer() async {
    return RTCSessionDescription('fake-offer-sdp', 'offer');
  }

  @override
  Future<RTCSessionDescription> handleRemoteOfferAndCreateAnswer(String sdp) async {
    operations.add('offer');
    return RTCSessionDescription('fake-answer-sdp', 'answer');
  }

  @override
  Future<void> handleRemoteAnswer(String sdp) async {
    operations.add('answer');
  }

  @override
  Future<void> addRemoteIceCandidate({
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    operations.add('ice');
  }

  @override
  Future<void> dispose() async {
    _ready = false;
  }
}
