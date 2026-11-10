package com.vn.smart_space.dto.request.chat;

import jakarta.validation.constraints.NotBlank;

public record ChatTypingRequest(
        @NotBlank String conversationId,
        boolean isTyping
) {
}

