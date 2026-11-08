package com.vn.smart_space.service.conversation;

import java.util.List;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.conversation.CreateConversationRequest;
import com.vn.smart_space.dto.response.conversation.ConversationDetailResponse;
import com.vn.smart_space.dto.response.conversation.CreateConversationResponse;
import com.vn.smart_space.dto.response.conversation.ParticipantResponse;
import com.vn.smart_space.model.ChatMessage;
import com.vn.smart_space.model.Conversation;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;

public interface IConversationService {

    CreateConversationResponse createConversation(String creatorId, CreateConversationRequest request);

    PageResponse<ConversationDetailResponse> getMyConversation(String userId, int page, int size, String role, String query);

    ConversationDetailResponse getConversationDetail(String userId, String conversationId);

    void markAsRead(String userId, String conversationId);

    Long getUnreadCount(String userId);

    Conversation getOrCreateReportConversation(Report report);

    ChatMessage sendSystemMessage(Conversation conversation, String content, User targetUser);

    void transferReportConversation(Report report, User oldStaff, User newStaff);

    List<ParticipantResponse> searchUsersForChat(String userId, String role, String query);

}
