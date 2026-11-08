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

  bool get isSystem => messageType.toUpperCase() == 'SYSTEM';

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
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
