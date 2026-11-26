package com.vn.smart_space.service.chat;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.chat.ChatMessageRequest;
import com.vn.smart_space.dto.response.chat.ChatMessageResponse;

public interface IChatMessageService {

    ChatMessageResponse sendMessage(String senderId, ChatMessageRequest request);

    PageResponse<ChatMessageResponse> getMessagesByConversation(String userId, String conversationId, int page, int size);

}
