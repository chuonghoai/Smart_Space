import 'dart:convert';
import 'package:smartspace_client/features/notifications/models/notification_action.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;
  final NotificationAction? actionData;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
    this.actionData,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'],
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
              : DateTime.now(),
      actionData: json['action_data'] != null 
          ? NotificationAction.fromJson(_parseActionData(json['action_data']))
          : json['actionData'] != null
              ? NotificationAction.fromJson(_parseActionData(json['actionData']))
              : null,
    );
  }

  static Map<String, dynamic> _parseActionData(dynamic actionDataStr) {
    if (actionDataStr is Map<String, dynamic>) {
      return actionDataStr;
    }
    if (actionDataStr is String) {
      try {
        final decoded = jsonDecode(actionDataStr);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return {};
  }
}
