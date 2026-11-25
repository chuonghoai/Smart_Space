import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/core/connection/connection_manager.dart';
import 'package:mobile_shared/core/connection/connection_state_provider.dart';
import 'package:mobile_shared/core/websocket/websocket_service.dart';
import 'package:mobile_shared/features/call/models/call_models.dart';
import 'package:mobile_shared/features/call/providers/call_controller.dart';
import 'package:mobile_shared/features/chat/data/chat_repository.dart';
import 'package:mobile_shared/features/chat/models/chat_message_model.dart';
import 'package:mobile_shared/features/chat/models/conversation_model.dart';
import 'package:mobile_shared/features/chat/models/linked_report_model.dart';
import 'package:mobile_shared/features/chat/providers/chat_detail_provider.dart';
import 'package:mobile_shared/features/chat/services/chat_ws_service.dart';

void main() {
  group('CallStatus', () {
    test('parses every lifecycle wire state accurately', () {
      expect(CallStatus.fromBackend('connecting'), CallStatus.connecting);
      expect(CallStatus.fromBackend('ringing'), CallStatus.ringing);
      expect(CallStatus.fromBackend('accepted'), CallStatus.accepted);
      expect(CallStatus.fromBackend('rejected'), CallStatus.rejected);
      expect(CallStatus.fromBackend('ongoing'), CallStatus.ongoing);
      expect(CallStatus.fromBackend('ended'), CallStatus.ended);
      expect(CallStatus.fromBackend('failed'), CallStatus.failed);
      expect(CallStatus.fromBackend('cancelled'), CallStatus.cancelled);
      expect(CallStatus.fromBackend('missed'), CallStatus.missed);
      expect(CallStatus.fromBackend(null), CallStatus.idle);
    });

    test('distinguishes accepted from ongoing and flags terminal states', () {
      expect(CallStatus.accepted.isTerminal, isFalse);
      expect(CallStatus.ongoing.isTerminal, isFalse);
      expect(CallStatus.accepted == CallStatus.ongoing, isFalse);
      expect(CallStatus.ended.isTerminal, isTrue);
      expect(CallStatus.rejected.isTerminal, isTrue);
      expect(CallStatus.cancelled.isTerminal, isTrue);
      expect(CallStatus.missed.isTerminal, isTrue);
      expect(CallStatus.failed.isTerminal, isTrue);
    });
  });

  group('CallSessionModel & IceServerModel', () {
    test('parses CallSessionModel with peer and ICE servers', () {
      final model = CallSessionModel.fromJson({
        'callId': 'call-123',
        'conversationId': 'conv-456',
        'callerId': 'u-caller',
        'receiverId': 'u-receiver',
        'status': 'ringing',
        'isAnonymous': true,
        'peer': {
          'userId': 'u-caller',
          'fullName': 'Người dùng ẩn danh',
          'role': 'resident',
          'isAnonymous': true,
        },
        'iceServers': [
          {
            'urls': ['stun:stun.l.google.com:19302'],
          },
          {
            'urls': ['turn:turn.example.com:3478?transport=udp'],
            'username': '1700000000:u-caller',
            'credential': 'secret',
          },
        ],
      });

      expect(model.callId, 'call-123');
      expect(model.status, CallStatus.ringing);
      expect(model.isAnonymous, isTrue);
      expect(model.peer?.isAnonymous, isTrue);
      expect(model.peer?.avatarUrl, isNull);
      expect(model.iceServers.length, 2);
      expect(model.iceServers[1].toRtcMap()['username'], '1700000000:u-caller');
    });
  });

  group('ChatMessageModel multi-report & legacy parsing', () {
    test('parses multiple attached reports while keeping effectiveReports intact', () {
      final msg = ChatMessageModel.fromJson({
        'id': 'm-1',
        'conversationId': 'conv-1',
        'senderId': 'admin-1',
        'content': 'Vui lòng kiểm tra 2 phản ánh này',
        'messageType': 'REPORT',
        'createdAt': '2026-11-25T10:00:00Z',
        'reports': [
          {
            'id': 'r-1',
            'title': 'Đèn hành lang hỏng',
            'status': 'processing',
            'isReviewResolved': false,
          },
          {
            'id': 'r-2',
            'title': 'Thang máy rung lắc',
            'status': 'processing',
            'needsRehandling': true,
          },
        ],
      });

      expect(msg.isReport, isTrue);
      expect(msg.effectiveReports.length, 2);
      expect(msg.effectiveReports.first.isRehandling, isTrue);
      expect(msg.effectiveReports.last.id, 'r-2');
    });

    test('falls back to single legacy report field when reports array absent', () {
      final msg = ChatMessageModel.fromJson({
        'id': 'm-2',
        'conversationId': 'conv-1',
        'senderId': 'client-1',
        'content': 'Đèn hỏng',
        'messageType': 'REPORT',
        'createdAt': '2026-11-25T10:00:00Z',
        'report': {
          'id': 'r-legacy',
          'title': 'Đèn hỏng',
          'status': 'processing',
        },
      });

      expect(msg.effectiveReports.length, 1);
      expect(msg.effectiveReports.single.id, 'r-legacy');
    });
  });

  group('ConversationModel & LinkedReportModel', () {
    test('parses canVoiceCall and anonymous partner masking safely', () {
      final conv = ConversationModel.fromJson({
        'id': 'conv-admin',
        'conversationType': 'PRIVATE',
        'partnerId': 'client-1',
        'partnerName': 'Người dùng ẩn danh',
        'isAnonymous': true,
        'canSendMessage': true,
        'canVoiceCall': true,
      });

      expect(conv.canSendMessage, isTrue);
      expect(conv.canVoiceCall, isTrue);
      expect(conv.isAnonymous, isTrue);
      expect(conv.partnerPhone, isNull);
    });

    test('LinkedReportModel.isRehandling detects needsRehandling and unresolved review', () {
      const unresolved = LinkedReportModel(
        id: '1',
        title: 'A',
        status: 'processing',
        isReviewResolved: false,
      );
      const resolved = LinkedReportModel(
        id: '2',
        title: 'B',
        status: 'processing',
        isReviewResolved: true,
      );
      expect(unresolved.isRehandling, isTrue);
      expect(resolved.isRehandling, isFalse);
    });
  });

  group('CallController WebSocket-only connect guard', () {
    test('fails immediately without creating session when WebSocket is disconnected', () async {
      webSocketService.setStatusForTest(WebSocketStatus.disconnected);
      final controller = CallController();
      String? requestedScreenId;
      controller.onCallScreenRequested = (id) => requestedScreenId = id;

      final started = await controller.startCall(
        targetUserId: 'receiver-1',
        peerName: 'Staff A',
      );

      expect(started, isFalse);
      expect(controller.state.status, CallStatus.failed);
      expect(requestedScreenId, isNotNull);
      expect(requestedScreenId!.startsWith('pending_'), isTrue);

      controller.dispose();
    });
  });

  group('ConnectionManagerService independent WS + Firebase state rule', () {
    test('turns green only when both WebSocket and Firebase are connected, red otherwise', () {
      ConnectionManagerService.evaluateGlobalConnectionState(
        wsConnected: true,
        wsConnecting: false,
        fcmConnected: true,
        fcmConnecting: false,
      );
      expect(connectionStateProvider.state, GlobalConnectionState.connected);

      // FCM failed while WS is connected -> must turn red (error), not stay green or spin
      ConnectionManagerService.evaluateGlobalConnectionState(
        wsConnected: true,
        wsConnecting: false,
        fcmConnected: false,
        fcmConnecting: false,
      );
      expect(connectionStateProvider.state, GlobalConnectionState.error);

      // WS dropped while FCM is connected -> must turn red (error)
      ConnectionManagerService.evaluateGlobalConnectionState(
        wsConnected: false,
        wsConnecting: false,
        fcmConnected: true,
        fcmConnecting: false,
      );
      expect(connectionStateProvider.state, GlobalConnectionState.error);

      // Active initial/retry handshake -> connecting
      ConnectionManagerService.evaluateGlobalConnectionState(
        wsConnected: true,
        wsConnecting: false,
        fcmConnected: false,
        fcmConnecting: true,
      );
      expect(connectionStateProvider.state, GlobalConnectionState.connecting);

      // WebSocketService send/subscribe no longer throws ConnectionNotReadyException
      connectionStateProvider.setError();
      webSocketService.setStatusForTest(WebSocketStatus.disconnected);
      expect(() => webSocketService.send(destination: '/smartspace/test', body: '{}'), returnsNormally);
    });
  });

  group('ChatDetailNotifier draft resolution', () {
    test('ensureConversationCreated resolves real conversation ID and loads messages', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      FlutterSecureStorage.setMockInitialValues({});
      final fakeRepo = _FakeChatRepoForDraftTest();
      final notifier = ChatDetailNotifier(
        conversationId: 'new_client_u-99',
        repository: fakeRepo,
        wsService: ChatWsService(),
      );

      expect(notifier.state.isDraft, isTrue);
      final resolvedId = await notifier.ensureConversationCreated();
      expect(resolvedId, 'conv-real-99');
      expect(notifier.state.isDraft, isFalse);
      expect(notifier.state.conversationId, 'conv-real-99');
      expect(notifier.state.messages.length, 1);
      expect(notifier.state.messages.first.content, 'Existing hello');

      notifier.dispose();
    });
  });
}

class _FakeChatRepoForDraftTest extends ChatRepositoryImpl {
  @override
  Future<ApiResponse<ConversationModel>> createOrGetConversation({
    List<String>? participantIds,
    String? reportId,
    String conversationType = 'PRIVATE',
    String? name,
    bool? isAnonymous,
  }) async {
    return ApiResponse(
      success: true,
      message: 'ok',
      data: ConversationModel(
        id: 'conv-real-99',
        conversationType: 'PRIVATE',
        partnerId: 'u-99',
        partnerName: 'Client 99',
        partnerRole: 'client',
        createdAt: DateTime.utc(2026, 11, 25, 10, 0),
      ),
    );
  }

  @override
  Future<ApiResponse<ConversationModel>> getConversationDetail(
    String conversationId,
  ) async {
    return ApiResponse(
      success: true,
      message: 'ok',
      data: ConversationModel(
        id: conversationId,
        conversationType: 'PRIVATE',
        partnerId: 'u-99',
        partnerName: 'Client 99',
        partnerRole: 'client',
        createdAt: DateTime.utc(2026, 11, 25, 10, 0),
      ),
    );
  }

  @override
  Future<ApiResponse<List<ChatMessageModel>>> getMessages(
    String conversationId, {
    int page = 1,
    int size = 20,
  }) async {
    return ApiResponse(
      success: true,
      message: 'ok',
      data: [
        ChatMessageModel(
          id: 'msg-1',
          conversationId: conversationId,
          senderId: 'u-99',
          content: 'Existing hello',
          messageType: 'TEXT',
          createdAt: DateTime.utc(2026, 11, 25, 10, 0),
        ),
      ],
    );
  }

  @override
  Future<ApiResponse<void>> enterPresence(String conversationId) async =>
      ApiResponse(success: true, message: 'ok');

  @override
  Future<ApiResponse<void>> leavePresence(String conversationId) async =>
      ApiResponse(success: true, message: 'ok');

  @override
  Future<ApiResponse<void>> markAsRead(String conversationId) async =>
      ApiResponse(success: true, message: 'ok');
}
