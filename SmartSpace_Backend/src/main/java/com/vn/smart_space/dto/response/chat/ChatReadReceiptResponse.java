package com.vn.smart_space.dto.response.chat;

import java.io.Serializable;

public record ChatReadReceiptResponse(
        String type,
        String conversationId,
        String readerId,
        String readAt
) implements Serializable {

    public static ChatReadReceiptResponse of(String conversationId, String readerId, String readAt) {
        return new ChatReadReceiptResponse("READ_RECEIPT", conversationId, readerId, readAt);
    }
}

