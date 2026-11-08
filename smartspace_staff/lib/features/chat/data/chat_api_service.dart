import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/chat/models/chat_message_model.dart';
import 'package:smartspace_staff/features/chat/models/conversation_model.dart';
import 'package:smartspace_staff/features/chat/models/position_model.dart';

class ChatApiService {
  Future<ApiResponse<List<ConversationModel>>> getConversations({
    int page = 1,
    int size = 15,
    String role = 'all',
    List<String>? positionIds,
    String? query,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'role': role,
      if (positionIds != null && positionIds.isNotEmpty)
        'positionIds': positionIds.join(','),
      if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
    };
    return apiClient.get<List<ConversationModel>>(
      '/conversations/my-conversation',
      queryParameters: queryParams,
      decoder: (json) {
        if (json is Map && json['content'] is List) {
          return (json['content'] as List)
              .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (json is List) {
          return json
              .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <ConversationModel>[];
      },
    );
  }

  Future<ApiResponse<ConversationModel>> getConversationDetail(
    String conversationId,
  ) async {
    return apiClient.get<ConversationModel>(
      '/conversations/$conversationId',
      decoder: (json) => ConversationModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ConversationModel>> createOrGetConversation({
    List<String>? participantIds,
    String? reportId,
    String conversationType = 'PRIVATE',
    String? name,
  }) async {
    return apiClient.post<ConversationModel>(
      '/conversations',
      data: {
        'participantIds': participantIds ?? [],
        'conversationType': conversationType,
        if (reportId != null && reportId.isNotEmpty) 'reportId': reportId,
        if (name != null && name.isNotEmpty) 'name': name,
      },
      decoder: (json) => ConversationModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<ChatMessageModel>>> getMessages(
    String conversationId, {
    int page = 1,
    int size = 20,
  }) async {
    return apiClient.get<List<ChatMessageModel>>(
      '/chat-messages/conversation/$conversationId',
      queryParameters: {
        'page': page,
        'size': size,
      },
      decoder: (json) {
        if (json is Map && json['content'] is List) {
          return (json['content'] as List)
              .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (json is List) {
          return json
              .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <ChatMessageModel>[];
      },
    );
  }

  Future<ApiResponse<ChatMessageModel>> sendMessage({
    required String conversationId,
    required String content,
    String? tempId,
    String messageType = 'text',
  }) async {
    return apiClient.post<ChatMessageModel>(
      '/chat-messages',
      data: {
        'conversationId': conversationId,
        'content': content,
        'tempId': ?tempId,
        'messageType': messageType,
      },
      decoder: (json) => ChatMessageModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> markAsRead(String conversationId) async {
    return apiClient.post<void>('/conversations/$conversationId/read');
  }

  Future<ApiResponse<int>> getUnreadCount() async {
    return apiClient.get<int>(
      '/conversations/unread-count',
      decoder: (json) => (json as num?)?.toInt() ?? 0,
    );
  }

  Future<ApiResponse<void>> enterPresence(String conversationId) async {
    return apiClient.post<void>('/conversations/$conversationId/presence/enter');
  }

  Future<ApiResponse<void>> heartbeatPresence(String conversationId) async {
    return apiClient.post<void>('/conversations/$conversationId/presence/heartbeat');
  }

  Future<ApiResponse<void>> leavePresence(String conversationId) async {
    return apiClient.post<void>('/conversations/$conversationId/presence/leave');
  }

  Future<ApiResponse<List<ParticipantModel>>> searchUsers({
    required String role,
    required String query,
    List<String>? positionIds,
  }) async {
    return apiClient.get<List<ParticipantModel>>(
      '/conversations/search-users',
      queryParameters: {
        'role': role,
        'query': query,
        if (positionIds != null && positionIds.isNotEmpty)
          'positionIds': positionIds.join(','),
      },
      decoder: (json) {
        if (json is List) {
          return json
              .map((e) => ParticipantModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <ParticipantModel>[];
      },
    );
  }

  Future<ApiResponse<List<PositionModel>>> getPositions() async {
    return apiClient.get<List<PositionModel>>(
      '/conversations/positions',
      decoder: (json) {
        if (json is List) {
          return json
              .map((e) => PositionModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <PositionModel>[];
      },
    );
  }
}

final chatApiService = ChatApiService();
