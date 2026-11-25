enum CallStatus {
  idle,
  connecting,
  ringing,
  incoming,
  accepted,
  ongoing,
  ended,
  rejected,
  failed,
  cancelled,
  missed;

  static CallStatus fromBackend(String? value) {
    switch (value?.toUpperCase()) {
      case 'CONNECTING':
        return CallStatus.connecting;
      case 'RINGING':
        return CallStatus.ringing;
      case 'ACCEPTED':
        return CallStatus.accepted;
      case 'REJECTED':
        return CallStatus.rejected;
      case 'ONGOING':
        return CallStatus.ongoing;
      case 'ENDED':
        return CallStatus.ended;
      case 'FAILED':
        return CallStatus.failed;
      case 'CANCELLED':
        return CallStatus.cancelled;
      case 'MISSED':
        return CallStatus.missed;
      default:
        return CallStatus.idle;
    }
  }

  bool get isTerminal =>
      this == ended ||
      this == rejected ||
      this == failed ||
      this == cancelled ||
      this == missed;

  bool get isActive =>
      this == connecting ||
      this == ringing ||
      this == incoming ||
      this == accepted ||
      this == ongoing;
}

enum AudioOutputRoute {
  earpiece,
  speaker,
  bluetooth,
  wiredHeadset,
  browserDefault,
}

class IceServerModel {
  final List<String> urls;
  final String? username;
  final String? credential;

  const IceServerModel({
    required this.urls,
    this.username,
    this.credential,
  });

  factory IceServerModel.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['urls'];
    List<String> urlList = [];
    if (rawUrls is List) {
      urlList = rawUrls.map((e) => e.toString()).toList();
    } else if (rawUrls is String && rawUrls.isNotEmpty) {
      urlList = [rawUrls];
    }
    return IceServerModel(
      urls: urlList,
      username: json['username'] as String?,
      credential: json['credential'] as String?,
    );
  }

  Map<String, dynamic> toRtcMap() {
    return {
      'urls': urls.length == 1 ? urls.first : urls,
      if (username != null && username!.isNotEmpty) 'username': username,
      if (credential != null && credential!.isNotEmpty) 'credential': credential,
    };
  }
}

class CallPeerModel {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? role;
  final String? position;
  final bool isAnonymous;

  const CallPeerModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.role,
    this.position,
    this.isAnonymous = false,
  });

  factory CallPeerModel.fromJson(Map<String, dynamic> json) {
    return CallPeerModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      role: json['role']?.toString(),
      position: json['position'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? json['is_anonymous'] as bool? ?? false,
    );
  }
}

class CallSessionModel {
  final String callId;
  final String callerId;
  final String receiverId;
  final String? conversationId;
  final bool isAnonymous;
  final CallStatus status;
  final CallPeerModel? peer;
  final List<IceServerModel> iceServers;
  final DateTime? expiresAt;
  final int ringTimeoutSeconds;
  final int signalingTimeoutSeconds;
  final int? durationSeconds;
  final String? endReason;

  const CallSessionModel({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    this.conversationId,
    this.isAnonymous = false,
    required this.status,
    this.peer,
    this.iceServers = const [],
    this.expiresAt,
    this.ringTimeoutSeconds = 45,
    this.signalingTimeoutSeconds = 25,
    this.durationSeconds,
    this.endReason,
  });

  factory CallSessionModel.fromJson(Map<String, dynamic> json) {
    final rawIce = json['iceServers'] as List<dynamic>? ?? [];
    final iceList = rawIce
        .whereType<Map<String, dynamic>>()
        .map(IceServerModel.fromJson)
        .toList();

    return CallSessionModel(
      callId: json['callId']?.toString() ?? '',
      callerId: json['callerId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      conversationId: json['conversationId']?.toString(),
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      status: CallStatus.fromBackend(json['status']?.toString()),
      peer: json['peer'] is Map<String, dynamic>
          ? CallPeerModel.fromJson(json['peer'] as Map<String, dynamic>)
          : null,
      iceServers: iceList,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      ringTimeoutSeconds: (json['ringTimeoutSeconds'] as num?)?.toInt() ?? 45,
      signalingTimeoutSeconds: (json['signalingTimeoutSeconds'] as num?)?.toInt() ?? 25,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      endReason: json['endReason']?.toString(),
    );
  }
}

class CommunicationEligibilityModel {
  final bool canMessage;
  final bool canVoiceCall;
  final bool isAnonymous;
  final String? reasonCode;
  final String? reasonMessage;
  final int eligibleRehandlingReportCount;

  const CommunicationEligibilityModel({
    required this.canMessage,
    required this.canVoiceCall,
    this.isAnonymous = false,
    this.reasonCode,
    this.reasonMessage,
    this.eligibleRehandlingReportCount = 0,
  });

  factory CommunicationEligibilityModel.fromJson(Map<String, dynamic> json) {
    return CommunicationEligibilityModel(
      canMessage: json['canMessage'] as bool? ?? false,
      canVoiceCall: json['canVoiceCall'] as bool? ?? false,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      reasonCode: json['reasonCode'] as String?,
      reasonMessage: json['reasonMessage'] as String?,
      eligibleRehandlingReportCount:
          (json['eligibleRehandlingReportCount'] as num?)?.toInt() ?? 0,
    );
  }
}
