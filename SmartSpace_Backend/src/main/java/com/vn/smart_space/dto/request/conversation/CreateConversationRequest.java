package com.vn.smart_space.dto.request.conversation;

import java.util.List;

import com.vn.smart_space.consts.EConversationType;

import jakarta.validation.constraints.NotNull;

public record CreateConversationRequest(
        String name,
        String conversationAvatar,
        @NotNull(message = "{conversation.type.required}") EConversationType conversationType,
        List<String> participantIds,
        String reportId
) {
}
