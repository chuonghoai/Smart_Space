package com.vn.smart_space.dto.request.call;

import jakarta.validation.constraints.NotBlank;

public record InitiateCallRequest(
        @NotBlank(message = "{call.receiverId.required}") String receiverId,
        String conversationId,
        Boolean isAnonymous
) {
}
