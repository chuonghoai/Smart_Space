import 'package:mobile_shared/core/api/api_client.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/call/models/call_models.dart';

class CallApiService {
  Future<ApiResponse<CommunicationEligibilityModel>> checkCallPermission({
    required String targetUserId,
    String? conversationId,
    bool? isAnonymous,
  }) async {
    return apiClient.get<CommunicationEligibilityModel>(
      '/calls/permission',
      queryParameters: {
        'targetUserId': targetUserId,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversationId': conversationId,
        if (isAnonymous != null) 'isAnonymous': isAnonymous,
      },
      decoder: (json) {
        final map = json as Map<String, dynamic>;
        return CommunicationEligibilityModel(
          canMessage: map['canMessage'] as bool? ?? false,
          canVoiceCall: map['allowed'] as bool? ?? false,
          isAnonymous: map['isAnonymous'] as bool? ?? false,
          reasonCode: map['reasonCode'] as String?,
          reasonMessage: map['reasonMessage'] as String?,
          eligibleRehandlingReportCount:
              (map['eligibleRehandlingReportCount'] as num?)?.toInt() ?? 0,
        );
      },
    );
  }

  Future<ApiResponse<List<IceServerModel>>> getIceServers() async {
    return apiClient.get<List<IceServerModel>>(
      '/calls/ice-servers',
      decoder: (json) {
        final map = json as Map<String, dynamic>;
        final raw = map['iceServers'] as List<dynamic>? ?? [];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(IceServerModel.fromJson)
            .toList();
      },
    );
  }

  Future<ApiResponse<CallSessionModel>> initiateCall({
    required String receiverId,
    String? conversationId,
    bool? isAnonymous,
  }) async {
    return apiClient.post<CallSessionModel>(
      '/calls',
      data: {
        'receiverId': receiverId,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversationId': conversationId,
        if (isAnonymous != null) 'isAnonymous': isAnonymous,
      },
      decoder: (json) => CallSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CallSessionModel>> getCallStatus(String callId) async {
    return apiClient.get<CallSessionModel>(
      '/calls/$callId',
      decoder: (json) => CallSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CallSessionModel>> acknowledgeRinging(String callId) async {
    return apiClient.post<CallSessionModel>(
      '/calls/$callId/ringing',
      decoder: (json) => CallSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CallSessionModel>> acceptCall(String callId) async {
    return apiClient.post<CallSessionModel>(
      '/calls/$callId/accept',
      decoder: (json) => CallSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CallSessionModel>> rejectCall(String callId, {String? reason}) async {
    return apiClient.post<CallSessionModel>(
      '/calls/$callId/reject',
      data: {
        'callId': callId,
        if (reason != null) 'reason': reason,
      },
      decoder: (json) => CallSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CallSessionModel>> cancelCall(String callId) async {
    return apiClient.post<CallSessionModel>(
      '/calls/$callId/cancel',
      decoder: (json) => CallSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CallSessionModel>> markConnected(String callId) async {
    return apiClient.post<CallSessionModel>(
      '/calls/$callId/connected',
      decoder: (json) => CallSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CallSessionModel>> endCall(String callId, {String? reason}) async {
    return apiClient.post<CallSessionModel>(
      '/calls/$callId/end',
      data: {
        'callId': callId,
        if (reason != null) 'reason': reason,
      },
      decoder: (json) => CallSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CallSessionModel>> markFailed(String callId, {String? reason}) async {
    return apiClient.post<CallSessionModel>(
      '/calls/$callId/fail',
      data: {
        'callId': callId,
        if (reason != null) 'reason': reason,
      },
      decoder: (json) => CallSessionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> relaySignal({
    required String callId,
    required String signalType,
    String? sdp,
    String? candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    return apiClient.post<void>(
      '/calls/$callId/signal',
      data: {
        'callId': callId,
        'signalType': signalType,
        if (sdp != null) 'sdp': sdp,
        if (candidate != null) 'candidate': candidate,
        if (sdpMid != null) 'sdpMid': sdpMid,
        if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
      },
    );
  }
}

final callApiService = CallApiService();
