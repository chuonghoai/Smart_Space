import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/chat/data/chat_repository.dart';
import 'package:smartspace_staff/features/chat/models/conversation_info_model.dart';

final conversationInfoProvider =
    FutureProvider.family<ConversationInfoModel, String>((ref, conversationId) async {
  final repository = ref.watch(chatRepositoryProvider);
  final response = await repository.getConversationInfo(conversationId);
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.message);
});

