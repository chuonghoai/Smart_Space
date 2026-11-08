import 'package:smartspace_staff/features/chat/models/linked_report_model.dart';

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
    );
  }
}

