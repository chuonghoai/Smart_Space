package com.vn.smart_space.configuration.websocket;

import java.security.Principal;

import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import com.vn.smart_space.service.chat.ChatPresenceService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j(topic = "WS-DISCONNECT")
public class WebSocketEventListener {

    private final ChatPresenceService chatPresenceService;

    @EventListener
    public void handleWebSocketDisconnectListener(SessionDisconnectEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        Principal user = headerAccessor.getUser();
        if (user != null && user.getName() != null) {
            String userId = user.getName();
            log.info("WebSocket session disconnected for user: {}", userId);
            chatPresenceService.clearUserPresence(userId);
        }
    }
}

