package com.vn.smart_space.dto.request.chat;

import jakarta.validation.constraints.NotBlank;

public record ChatReadRequest(
        @NotBlank String conversationId
) {
}

