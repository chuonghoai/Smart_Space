package com.vn.smart_space.controller.chat;

import java.security.Principal;
import java.util.Map;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import com.vn.smart_space.dto.request.chat.ChatMessageRequest;
import com.vn.smart_space.dto.request.chat.ChatReadRequest;
import com.vn.smart_space.dto.request.chat.ChatTypingRequest;
import com.vn.smart_space.service.chat.IChatMessageService;
import com.vn.smart_space.service.conversation.IConversationService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Controller
@RequiredArgsConstructor
@Slf4j(topic = "CHAT-WS")
public class ChatWebSocketController {

    private final IChatMessageService chatMessageService;
    private final IConversationService conversationService;
    private final SimpMessagingTemplate messagingTemplate;

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

    @MessageMapping("/chat.read")
    public void markConversationAsRead(
            @Payload @Valid ChatReadRequest request,
            Principal principal) {
        if (principal == null) {
            log.warn("Unauthorized WebSocket message attempt to /chat.read");
            return;
        }

        String userId = principal.getName();
        log.info("Received WebSocket mark as read from user {} for conversation {}", userId, request.conversationId());
        conversationService.markAsRead(userId, request.conversationId());
    }

    @MessageMapping("/chat.typing")
    public void handleTypingIndicator(
            @Payload @Valid ChatTypingRequest request,
            Principal principal) {
        if (principal == null) {
            return;
        }

        String userId = principal.getName();
        try {
            Map<String, Object> typingEvent = Map.of(
                    "type", "TYPING",
                    "conversationId", request.conversationId(),
                    "userId", userId,
                    "isTyping", request.isTyping()
            );
            messagingTemplate.convertAndSend((String) ("/topic/conversation." + request.conversationId()), (Object) typingEvent);
        } catch (Exception e) {
            log.warn("Failed to broadcast typing event for conversation {}: {}", request.conversationId(), e.getMessage());
        }
    }
}

