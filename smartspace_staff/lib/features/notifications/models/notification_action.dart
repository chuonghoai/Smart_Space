import 'dart:convert';

class NotificationAction {
  final String type;
  final Map<String, dynamic> payload;

  NotificationAction({
    required this.type,
    required this.payload,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      type: json['type'] as String? ?? '',
      payload: _parsePayload(json['payload']),
    );
  }

  static Map<String, dynamic> _parsePayload(dynamic payloadData) {
    if (payloadData == null) return {};
    if (payloadData is Map<String, dynamic>) return payloadData;
    if (payloadData is String) {
      try {
        final decoded = jsonDecode(payloadData);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }
    return {};
  }
}
