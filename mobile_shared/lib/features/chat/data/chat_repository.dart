import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/chat/data/chat_api_service.dart';
import 'package:mobile_shared/features/chat/models/chat_message_model.dart';
import 'package:mobile_shared/features/chat/models/conversation_info_model.dart';
import 'package:mobile_shared/features/chat/models/conversation_model.dart';
import 'package:mobile_shared/features/chat/models/linked_report_model.dart';
import 'package:mobile_shared/features/chat/models/position_model.dart';
import 'package:mobile_shared/features/chat/services/chat_ws_service.dart';

abstract class ChatRepository {
  Future<ApiResponse<List<ConversationModel>>> getConversations({
    int page = 1,
    int size = 15,
    String role = 'all',
    List<String>? positionIds,
    String? query,
  });

  Future<ApiResponse<ConversationModel>> getConversationDetail(String conversationId);

  Future<ApiResponse<ConversationModel>> createOrGetConversation({
    List<String>? participantIds,
    String? reportId,
    String conversationType = 'PRIVATE',
    String? name,
  });

  Future<ApiResponse<List<ChatMessageModel>>> getMessages(
    String conversationId, {
    int page = 1,
    int size = 20,
  });

  bool get isWsConnected;

  bool sendMessageWs({
    required String conversationId,
    required String content,
    required String tempId,
    String messageType = 'text',
  });

  Future<ApiResponse<ChatMessageModel>> sendMessage({
    required String conversationId,
    required String content,
    String? tempId,
    String messageType = 'text',
  });

  Future<ApiResponse<void>> markAsRead(String conversationId);

  Future<ApiResponse<int>> getUnreadCount();

  Future<ApiResponse<void>> enterPresence(String conversationId);

  Future<ApiResponse<void>> heartbeatPresence(String conversationId);

  Future<ApiResponse<void>> leavePresence(String conversationId);

  Future<ApiResponse<List<ParticipantModel>>> searchUsers({
    required String role,
    required String query,
    List<String>? positionIds,
  });

  Future<ApiResponse<List<PositionModel>>> getPositions();

  Future<ApiResponse<ConversationInfoModel>> getConversationInfo(String conversationId);

  Future<ApiResponse<List<LinkedReportModel>>> getConversationReports(
    String conversationId, {
    int page = 1,
    int size = 10,
  });
}

class ChatRepositoryImpl implements ChatRepository {
  final ChatApiService _apiService;

  ChatRepositoryImpl({ChatApiService? apiService})
      : _apiService = apiService ?? chatApiService;

  @override
  Future<ApiResponse<List<ConversationModel>>> getConversations({
    int page = 1,
    int size = 15,
    String role = 'all',
    List<String>? positionIds,
    String? query,
  }) {
    return _apiService.getConversations(
      page: page,
      size: size,
      role: role,
      positionIds: positionIds,
      query: query,
    );
  }

  @override
  Future<ApiResponse<ConversationModel>> getConversationDetail(String conversationId) {
    return _apiService.getConversationDetail(conversationId);
  }

  @override
  Future<ApiResponse<ConversationModel>> createOrGetConversation({
    List<String>? participantIds,
    String? reportId,
    String conversationType = 'PRIVATE',
    String? name,
  }) {
    return _apiService.createOrGetConversation(
      participantIds: participantIds,
      reportId: reportId,
      conversationType: conversationType,
      name: name,
    );
  }

  @override
  Future<ApiResponse<List<ChatMessageModel>>> getMessages(
    String conversationId, {
    int page = 1,
    int size = 20,
  }) {
    return _apiService.getMessages(conversationId, page: page, size: size);
  }

  @override
  bool get isWsConnected => chatWsService.isConnected;

  @override
  bool sendMessageWs({
    required String conversationId,
    required String content,
    required String tempId,
    String messageType = 'text',
  }) {
    return chatWsService.sendMessage(
      conversationId: conversationId,
      content: content,
      tempId: tempId,
      messageType: messageType,
    );
  }

  @override
  Future<ApiResponse<ChatMessageModel>> sendMessage({
    required String conversationId,
    required String content,
    String? tempId,
    String messageType = 'text',
  }) {
    return _apiService.sendMessage(
      conversationId: conversationId,
      content: content,
      tempId: tempId,
      messageType: messageType,
    );
  }

  @override
  Future<ApiResponse<void>> markAsRead(String conversationId) {
    return _apiService.markAsRead(conversationId);
  }

  @override
  Future<ApiResponse<int>> getUnreadCount() {
    return _apiService.getUnreadCount();
  }

  @override
  Future<ApiResponse<void>> enterPresence(String conversationId) {
    return _apiService.enterPresence(conversationId);
  }

  @override
  Future<ApiResponse<void>> heartbeatPresence(String conversationId) {
    return _apiService.heartbeatPresence(conversationId);
  }

  @override
  Future<ApiResponse<void>> leavePresence(String conversationId) {
    return _apiService.leavePresence(conversationId);
  }

  @override
  Future<ApiResponse<List<ParticipantModel>>> searchUsers({
    required String role,
    required String query,
    List<String>? positionIds,
  }) {
    return _apiService.searchUsers(
      role: role,
      query: query,
      positionIds: positionIds,
    );
  }

  @override
  Future<ApiResponse<List<PositionModel>>> getPositions() {
    return _apiService.getPositions();
  }

  @override
  Future<ApiResponse<ConversationInfoModel>> getConversationInfo(String conversationId) {
    return _apiService.getConversationInfo(conversationId);
  }

  @override
  Future<ApiResponse<List<LinkedReportModel>>> getConversationReports(
    String conversationId, {
    int page = 1,
    int size = 10,
  }) {
    return _apiService.getConversationReports(conversationId, page: page, size: size);
  }
}

final chatRepository = ChatRepositoryImpl();
final chatRepositoryProvider = Provider<ChatRepository>((ref) => chatRepository);

