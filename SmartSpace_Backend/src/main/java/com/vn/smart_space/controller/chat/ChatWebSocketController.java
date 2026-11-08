package com.vn.smart_space.controller.chat;

import java.security.Principal;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

import com.vn.smart_space.dto.request.chat.ChatMessageRequest;
import com.vn.smart_space.service.chat.IChatMessageService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Controller
@RequiredArgsConstructor
@Slf4j(topic = "CHAT-WS")
public class ChatWebSocketController {

    private final IChatMessageService chatMessageService;

    @MessageMapping("/chat.send")
    public void sendChatMessage(
            @Payload @Valid ChatMessageRequest request,
            Principal principal) {
        if (principal == null) {
            log.warn("Unauthorized WebSocket message attempt to /chat.send");
            return;
        }

        String senderId = principal.getName();
        log.info("Received WebSocket chat message from user {} for conversation {}", senderId, request.conversationId());
        chatMessageService.sendMessage(senderId, request);
    }
}

