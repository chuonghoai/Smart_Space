package com.vn.smart_space.service.auth;

import java.util.Map;

import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Đẩy event SESSION_REVOKED qua WebSocket tới mọi thiết bị đang kết nối của user.
 * App so khớp `deviceIds` với deviceId của chính mình: trùng thì tự đăng xuất ngay,
 * không phải chờ tới request kế tiếp bị 401.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SessionRevokedNotifier {

    public static final String DESTINATION = "/queue/session";
    public static final String TYPE_SESSION_REVOKED = "SESSION_REVOKED";

    private final SimpMessagingTemplate messagingTemplate;

    @EventListener
    public void onSessionRevoked(SessionRevokedEvent event) {
        if (event.deviceIds() == null || event.deviceIds().isEmpty()) {
            return;
        }
        try {
            messagingTemplate.convertAndSendToUser(event.userId(), DESTINATION, Map.of(
                    "type", TYPE_SESSION_REVOKED,
                    "deviceIds", event.deviceIds()));
        } catch (Exception e) {
            // Không chặn việc thu hồi: thiết bị vẫn bị đá ra ở request kế tiếp (introspect)
            log.warn("[Session] Failed to push SESSION_REVOKED to user {}: {}", event.userId(), e.getMessage());
        }
    }
}
