import 'package:mobile_shared/features/chat/models/linked_report_model.dart';

class MessageMediaModel {
  final String fileName;
  final String fileType;
  final String thumbnailUrl;
  final DateTime? uploadedAt;

  const MessageMediaModel({
    required this.fileName,
    required this.fileType,
    required this.thumbnailUrl,
    this.uploadedAt,
  });

  factory MessageMediaModel.fromJson(Map<String, dynamic> json) {
    return MessageMediaModel(
      fileName: json['fileName'] as String? ?? json['file_name'] as String? ?? '',
      fileType: json['fileType'] as String? ?? json['file_type'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String? ?? '',
      uploadedAt: json['uploadedAt'] != null || json['uploaded_at'] != null
          ? DateTime.tryParse((json['uploadedAt'] ?? json['uploaded_at']).toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'fileType': fileType,
    'thumbnailUrl': thumbnailUrl,
    if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
  };
}

class ChatMessageModel {
  final String? id;
  final String? tempId;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final bool isSending;
  final bool isFailed;
  final List<MessageMediaModel> messageMedia;
  final LinkedReportModel? report;
  final String? localMediaPath;
  final bool isRead;

  bool get isSystem => messageType.toUpperCase() == 'SYSTEM';
  bool get isImage => messageType.toUpperCase() == 'IMAGE';
  bool get isVideo => messageType.toUpperCase() == 'VIDEO';
  bool get isAudio => messageType.toUpperCase() == 'AUDIO';
  bool get isReport => messageType.toUpperCase() == 'REPORT';

  const ChatMessageModel({
    this.id,
    this.tempId,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.content,
    this.messageType = 'TEXT',
    required this.createdAt,
    this.isSending = false,
    this.isFailed = false,
    this.messageMedia = const [],
    this.report,
    this.localMediaPath,
    this.isRead = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    var rawMedia = json['messageMedia'] ?? json['message_media'];
    List<MessageMediaModel> mediaList = [];
    if (rawMedia is List) {
      mediaList = rawMedia
          .map((m) => MessageMediaModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    LinkedReportModel? reportModel;
    if (json['report'] != null && json['report'] is Map<String, dynamic>) {
      reportModel = LinkedReportModel.fromJson(json['report'] as Map<String, dynamic>);
    }

    return ChatMessageModel(
      id: json['id']?.toString(),
      tempId: json['tempId'] as String?,
      conversationId: json['conversationId'] as String? ?? json['conversation_id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? json['sender_id'] as String? ?? '',
      senderName: json['senderName'] as String? ?? json['sender_name'] as String?,
      content: json['content'] as String? ?? '',
      messageType: json['messageType'] as String? ?? json['message_type'] as String? ?? 'TEXT',
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.tryParse((json['createdAt'] ?? json['created_at']).toString()) ?? DateTime.now()
          : DateTime.now(),
      isSending: false,
      isFailed: false,
      messageMedia: mediaList,
      report: reportModel,
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tempId': tempId,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'messageType': messageType,
      'createdAt': createdAt.toIso8601String(),
      if (messageMedia.isNotEmpty) 'messageMedia': messageMedia.map((m) => m.toJson()).toList(),
      if (report != null) 'report': report!.toJson(),
      'isRead': isRead,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? tempId,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    String? messageType,
    DateTime? createdAt,
    bool? isSending,
    bool? isFailed,
    List<MessageMediaModel>? messageMedia,
    LinkedReportModel? report,
    String? localMediaPath,
    bool? isRead,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      tempId: tempId ?? this.tempId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      isSending: isSending ?? this.isSending,
      isFailed: isFailed ?? this.isFailed,
      messageMedia: messageMedia ?? this.messageMedia,
      report: report ?? this.report,
      localMediaPath: localMediaPath ?? this.localMediaPath,
      isRead: isRead ?? this.isRead,
    );
  }
}

