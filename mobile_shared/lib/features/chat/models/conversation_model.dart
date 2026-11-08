class ConversationModel {
  final String id;
  final String? name;
  final String? conversationAvatar;
  final String conversationType;
  final String? partnerId;
  final String? partnerName;
  final String? partnerAvatarUrl;
  final String? partnerRole;
  final String? partnerPosition;
  final String? partnerPhone;
  final bool isAnonymous;
  final String? reportId;
  final String? reportTitle;
  final String? reportStatus;
  final bool canSendMessage;
  final int unreadCount;
  final String? lastMessageId;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final String? identifiedConversationId;
  final String? anonymousConversationId;
  final bool hasIdentifiedContext;
  final bool hasAnonymousContext;
  final String? lastMessageContext;
  final int identifiedUnreadCount;
  final int anonymousUnreadCount;

  const ConversationModel({
    required this.id,
    this.name,
    this.conversationAvatar,
    this.conversationType = 'PRIVATE',
    this.partnerId,
    this.partnerName,
    this.partnerAvatarUrl,
    this.partnerRole,
    this.partnerPosition,
    this.partnerPhone,
    this.isAnonymous = false,
    this.reportId,
    this.reportTitle,
    this.reportStatus,
    this.canSendMessage = true,
    this.unreadCount = 0,
    this.lastMessageId,
    this.lastMessageContent,
    this.lastMessageTime,
    required this.createdAt,
    this.identifiedConversationId,
    this.anonymousConversationId,
    this.hasIdentifiedContext = false,
    this.hasAnonymousContext = false,
    this.lastMessageContext,
    this.identifiedUnreadCount = 0,
    this.anonymousUnreadCount = 0,
  });

  bool get isClient => partnerRole?.toLowerCase() == 'client';
  bool get isStaff => partnerRole?.toLowerCase() == 'staff';
  bool get isAdmin => partnerRole?.toLowerCase() == 'admin';

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String?,
      conversationAvatar: json['conversationAvatar'] as String? ?? json['conversation_avatar'] as String?,
      conversationType: json['conversationType'] as String? ?? json['conversation_type'] as String? ?? 'PRIVATE',
      partnerId: json['partnerId'] as String? ?? json['partner_id'] as String?,
      partnerName: json['partnerName'] as String? ?? json['partner_name'] as String?,
      partnerAvatarUrl: json['partnerAvatarUrl'] as String? ?? json['partner_avatar_url'] as String?,
      partnerRole: json['partnerRole'] as String? ?? json['partner_role'] as String?,
      partnerPosition: json['partnerPosition'] as String? ?? json['partner_position'] as String?,
      partnerPhone: json['partnerPhone'] as String? ?? json['partner_phone'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? json['is_anonymous'] as bool? ?? false,
      reportId: json['reportId'] as String? ?? json['report_id'] as String?,
      reportTitle: json['reportTitle'] as String? ?? json['report_title'] as String?,
      reportStatus: json['reportStatus'] as String? ?? json['report_status'] as String?,
      canSendMessage: json['canSendMessage'] as bool? ?? json['can_send_message'] as bool? ?? true,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? (json['unread_count'] as num?)?.toInt() ?? 0,
      lastMessageId: json['lastMessageId'] as String? ?? json['last_message_id'] as String?,
      lastMessageContent: json['lastMessageContent'] as String? ?? json['last_message_content'] as String?,
      lastMessageTime: json['lastMessageTime'] != null || json['last_message_time'] != null
          ? DateTime.tryParse((json['lastMessageTime'] ?? json['last_message_time']).toString())
          : null,
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.tryParse((json['createdAt'] ?? json['created_at']).toString()) ?? DateTime.now()
          : DateTime.now(),
      identifiedConversationId: json['identifiedConversationId'] as String? ?? json['identified_conversation_id'] as String?,
      anonymousConversationId: json['anonymousConversationId'] as String? ?? json['anonymous_conversation_id'] as String?,
      hasIdentifiedContext: json['hasIdentifiedContext'] as bool? ?? json['has_identified_context'] as bool? ?? false,
      hasAnonymousContext: json['hasAnonymousContext'] as bool? ?? json['has_anonymous_context'] as bool? ?? false,
      lastMessageContext: json['lastMessageContext'] as String? ?? json['last_message_context'] as String?,
      identifiedUnreadCount: (json['identifiedUnreadCount'] as num?)?.toInt() ?? (json['identified_unread_count'] as num?)?.toInt() ?? 0,
      anonymousUnreadCount: (json['anonymousUnreadCount'] as num?)?.toInt() ?? (json['anonymous_unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'conversationAvatar': conversationAvatar,
      'conversationType': conversationType,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'partnerAvatarUrl': partnerAvatarUrl,
      'partnerRole': partnerRole,
      'partnerPosition': partnerPosition,
      'partnerPhone': partnerPhone,
      'isAnonymous': isAnonymous,
      'reportId': reportId,
      'reportTitle': reportTitle,
      'reportStatus': reportStatus,
      'canSendMessage': canSendMessage,
      'unreadCount': unreadCount,
      'lastMessageId': lastMessageId,
      'lastMessageContent': lastMessageContent,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'identifiedConversationId': identifiedConversationId,
      'anonymousConversationId': anonymousConversationId,
      'hasIdentifiedContext': hasIdentifiedContext,
      'hasAnonymousContext': hasAnonymousContext,
      'lastMessageContext': lastMessageContext,
      'identifiedUnreadCount': identifiedUnreadCount,
      'anonymousUnreadCount': anonymousUnreadCount,
    };
  }

  ConversationModel copyWith({
    String? id,
    String? name,
    String? conversationAvatar,
    String? conversationType,
    String? partnerId,
    String? partnerName,
    String? partnerAvatarUrl,
    String? partnerRole,
    String? partnerPosition,
    String? partnerPhone,
    bool? isAnonymous,
    String? reportId,
    String? reportTitle,
    String? reportStatus,
    bool? canSendMessage,
    int? unreadCount,
    String? lastMessageId,
    String? lastMessageContent,
    DateTime? lastMessageTime,
    DateTime? createdAt,
    String? identifiedConversationId,
    String? anonymousConversationId,
    bool? hasIdentifiedContext,
    bool? hasAnonymousContext,
    String? lastMessageContext,
    int? identifiedUnreadCount,
    int? anonymousUnreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      conversationAvatar: conversationAvatar ?? this.conversationAvatar,
      conversationType: conversationType ?? this.conversationType,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      partnerAvatarUrl: partnerAvatarUrl ?? this.partnerAvatarUrl,
      partnerRole: partnerRole ?? this.partnerRole,
      partnerPosition: partnerPosition ?? this.partnerPosition,
      partnerPhone: partnerPhone ?? this.partnerPhone,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      reportId: reportId ?? this.reportId,
      reportTitle: reportTitle ?? this.reportTitle,
      reportStatus: reportStatus ?? this.reportStatus,
      canSendMessage: canSendMessage ?? this.canSendMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt ?? this.createdAt,
      identifiedConversationId: identifiedConversationId ?? this.identifiedConversationId,
      anonymousConversationId: anonymousConversationId ?? this.anonymousConversationId,
      hasIdentifiedContext: hasIdentifiedContext ?? this.hasIdentifiedContext,
      hasAnonymousContext: hasAnonymousContext ?? this.hasAnonymousContext,
      lastMessageContext: lastMessageContext ?? this.lastMessageContext,
      identifiedUnreadCount: identifiedUnreadCount ?? this.identifiedUnreadCount,
      anonymousUnreadCount: anonymousUnreadCount ?? this.anonymousUnreadCount,
    );
  }
}

class ParticipantModel {
  final String userId;
  final String name;
  final String? avatarUrl;
  final String role;
  final String? position;

  const ParticipantModel({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.position,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'staff',
      position: json['position'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatarUrl': avatarUrl,
      'role': role,
      'position': position,
    };
  }
}

