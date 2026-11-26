package com.vn.smart_space.configuration.websocket;

import java.security.Principal;
import java.util.Map;

import org.springframework.context.annotation.Lazy;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;
import org.springframework.web.socket.messaging.SessionSubscribeEvent;
import org.springframework.web.socket.messaging.SessionUnsubscribeEvent;

import com.vn.smart_space.service.call.ICallService;
import com.vn.smart_space.service.chat.ChatPresenceService;

import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j(topic = "WS-DISCONNECT")
public class WebSocketEventListener {

    private final ChatPresenceService chatPresenceService;
    private final WebSocketSessionRegistry wsSessionRegistry;
    private final ICallService callService;

    public WebSocketEventListener(
            ChatPresenceService chatPresenceService,
            WebSocketSessionRegistry wsSessionRegistry,
            @Lazy ICallService callService) {
        this.chatPresenceService = chatPresenceService;
        this.wsSessionRegistry = wsSessionRegistry;
        this.callService = callService;
    }

    @EventListener
    public void handleWebSocketSubscribeListener(SessionSubscribeEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        if ("/user/queue/call".equals(headerAccessor.getDestination())) {
            wsSessionRegistry.markCallQueueSubscribed(headerAccessor.getSessionId(), true);
        }
    }

    @EventListener
    public void handleWebSocketUnsubscribeListener(SessionUnsubscribeEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        if ("/user/queue/call".equals(headerAccessor.getDestination())) {
            wsSessionRegistry.markCallQueueSubscribed(headerAccessor.getSessionId(), false);
        }
    }

    @EventListener
    public void handleWebSocketDisconnectListener(SessionDisconnectEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String sessionId = headerAccessor.getSessionId();
        WebSocketSessionRegistry.ActiveWsSession removed = wsSessionRegistry.removeSession(sessionId);

        Principal user = headerAccessor.getUser();
        String userId = user != null ? user.getName() : null;
        if (userId == null && removed != null) {
            userId = removed.userId();
        }
        String deviceId = removed != null ? removed.deviceId() : null;
        if (deviceId == null) {
            Map<String, Object> attrs = headerAccessor.getSessionAttributes();
            if (attrs != null && attrs.get("deviceId") != null) {
                deviceId = attrs.get("deviceId").toString();
            }
        }

        if (userId != null) {
            log.info("WebSocket session disconnected for user: {} (session={})", userId, sessionId);
            if (!wsSessionRegistry.hasValidConnection(userId)) {
                chatPresenceService.clearUserPresence(userId);
            }
            callService.handleUserWebSocketDisconnected(userId, sessionId, deviceId);
        }
    }
}

