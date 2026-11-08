import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_shared/features/chat/models/chat_message_model.dart';

final chatLocalStorageServiceProvider = Provider<ChatLocalStorageService>((ref) {
  return ChatLocalStorageService();
});

class ChatLocalStorageService {
  static const String _messagesPrefix = 'cached_chat_messages_';

  Future<void> saveMessages(String conversationId, List<ChatMessageModel> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = messages.map((m) => m.toJson()).toList();
      await prefs.setString('$_messagesPrefix$conversationId', jsonEncode(listJson));
    } catch (_) {}
  }

  Future<List<ChatMessageModel>> getCachedMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_messagesPrefix$conversationId');
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearCachedMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_messagesPrefix$conversationId');
    } catch (_) {}
  }
}
