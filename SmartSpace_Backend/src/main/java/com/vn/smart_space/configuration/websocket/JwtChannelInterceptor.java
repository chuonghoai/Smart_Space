package com.vn.smart_space.configuration.websocket;

import java.time.Instant;

import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessagingException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.stereotype.Component;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j(topic = "WS-AUTH")
@RequiredArgsConstructor
public class JwtChannelInterceptor implements ChannelInterceptor {

    private final JwtDecoder jwtDecoder;
    private final JwtAuthenticationConverter jwtAuthenticationConverter;
    private final WebSocketSessionRegistry wsSessionRegistry;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) {
            return message;
        }

        String sessionId = accessor.getSessionId();
        StompCommand command = accessor.getCommand();

        if (StompCommand.CONNECT.equals(command)) {
            String authHeader = accessor.getFirstNativeHeader("Authorization");

            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                throw new MessagingException("auth.token.missing_or_invalid");
            }

            String token = authHeader.substring(7);
            try {
                Jwt jwt = jwtDecoder.decode(token);
                AbstractAuthenticationToken auth = jwtAuthenticationConverter.convert(jwt);

                String userId = jwt.getClaimAsString("userId");
                String deviceId = jwt.getClaimAsString("deviceId");
                Instant tokenExpiresAt = jwt.getExpiresAt();

                // Wrap auth so that principal.getName() returns userId (not email/subject).
                // This is required because convertAndSendToUser() matches by
                // principal.getName().
                if (userId != null && !userId.isEmpty()) {
                    accessor.setUser(new UserIdAuthenticationToken(auth, userId));
                } else {
                    accessor.setUser(auth);
                }

                if (accessor.getSessionAttributes() != null && userId != null) {
                    accessor.getSessionAttributes().put("userId", userId);
                    if (deviceId != null && !deviceId.isBlank()) {
                        accessor.getSessionAttributes().put("deviceId", deviceId);
                    }
                    if (tokenExpiresAt != null) {
                        accessor.getSessionAttributes().put("tokenExpiresAt", tokenExpiresAt);
                    }
                }

                wsSessionRegistry.registerSession(sessionId, userId, deviceId, tokenExpiresAt);
                log.info("WebSocket CONNECT authenticated: user={}, session={}", jwt.getSubject(), sessionId);
            } catch (Exception e) {
                log.error("WebSocket Authentication failed: {}", e.getMessage());
                throw new MessagingException("auth.token.invalid");
            }
        } else {
            if (sessionId != null && !StompCommand.DISCONNECT.equals(command)) {
                wsSessionRegistry.touchSession(sessionId);
            }
            if (StompCommand.SUBSCRIBE.equals(command) && sessionId != null) {
                String dest = accessor.getDestination();
                if ("/user/queue/call".equals(dest)) {
                    wsSessionRegistry.markCallQueueSubscribed(sessionId, true);
                }
            }
        }
        return message;
    }
}