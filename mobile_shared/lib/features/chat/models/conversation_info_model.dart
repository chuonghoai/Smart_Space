import 'package:mobile_shared/features/chat/models/linked_report_model.dart';

class ConversationInfoModel {
  final String id;
  final String? partnerId;
  final String? partnerName;
  final String? partnerAvatarUrl;
  final String? partnerRole;
  final String? partnerPosition;
  final String? partnerPhone;
  final String? partnerEmail;
  final bool isAnonymous;
  final bool canSendMessage;
  final List<LinkedReportModel> activeReports;
  final DateTime? createdAt;
  final String? identifiedConversationId;
  final String? anonymousConversationId;
  final bool hasIdentifiedContext;
  final bool hasAnonymousContext;
  final String? activeContext;
  final int identifiedUnreadCount;
  final int anonymousUnreadCount;
  final bool canSendIdentifiedMessage;
  final bool canSendAnonymousMessage;

  const ConversationInfoModel({
    required this.id,
    this.partnerId,
    this.partnerName,
    this.partnerAvatarUrl,
    this.partnerRole,
    this.partnerPosition,
    this.partnerPhone,
    this.partnerEmail,
    this.isAnonymous = false,
    this.canSendMessage = true,
    this.activeReports = const [],
    this.createdAt,
    this.identifiedConversationId,
    this.anonymousConversationId,
    this.hasIdentifiedContext = false,
    this.hasAnonymousContext = false,
    this.activeContext,
    this.identifiedUnreadCount = 0,
    this.anonymousUnreadCount = 0,
    this.canSendIdentifiedMessage = true,
    this.canSendAnonymousMessage = true,
  });

  factory ConversationInfoModel.fromJson(Map<String, dynamic> json) {
    var rawReports = json['activeReports'] as List<dynamic>? ?? [];
    List<LinkedReportModel> reports = rawReports
        .map((e) => LinkedReportModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ConversationInfoModel(
      id: json['id'] as String? ?? '',
      partnerId: json['partnerId'] as String?,
      partnerName: json['partnerName'] as String?,
      partnerAvatarUrl: json['partnerAvatarUrl'] as String?,
      partnerRole: json['partnerRole'] as String?,
      partnerPosition: json['partnerPosition'] as String?,
      partnerPhone: json['partnerPhone'] as String?,
      partnerEmail: json['partnerEmail'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      canSendMessage: json['canSendMessage'] as bool? ?? true,
      activeReports: reports,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      identifiedConversationId: json['identifiedConversationId'] as String? ?? json['identified_conversation_id'] as String?,
      anonymousConversationId: json['anonymousConversationId'] as String? ?? json['anonymous_conversation_id'] as String?,
      hasIdentifiedContext: json['hasIdentifiedContext'] as bool? ?? json['has_identified_context'] as bool? ?? false,
      hasAnonymousContext: json['hasAnonymousContext'] as bool? ?? json['has_anonymous_context'] as bool? ?? false,
      activeContext: json['activeContext'] as String? ?? json['active_context'] as String?,
      identifiedUnreadCount: (json['identifiedUnreadCount'] as num?)?.toInt() ?? (json['identified_unread_count'] as num?)?.toInt() ?? 0,
      anonymousUnreadCount: (json['anonymousUnreadCount'] as num?)?.toInt() ?? (json['anonymous_unread_count'] as num?)?.toInt() ?? 0,
      canSendIdentifiedMessage: json['canSendIdentifiedMessage'] as bool? ?? json['can_send_identified_message'] as bool? ?? true,
      canSendAnonymousMessage: json['canSendAnonymousMessage'] as bool? ?? json['can_send_anonymous_message'] as bool? ?? true,
    );
  }
}

