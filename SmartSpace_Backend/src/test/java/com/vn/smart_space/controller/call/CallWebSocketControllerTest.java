package com.vn.smart_space.controller.call;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

import java.security.Principal;
import java.time.Instant;

import org.junit.jupiter.api.Test;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import com.vn.smart_space.configuration.websocket.WebSocketSessionRegistry;
import com.vn.smart_space.service.call.ICallService;

class CallWebSocketControllerTest {

    @Test
    void onPingTouchesSessionWithoutSpoofingCallQueueSubscription() {
        WebSocketSessionRegistry registry = new WebSocketSessionRegistry();
        registry.registerSession("sess-1", "user-1", "dev-1", Instant.now().plusSeconds(300));

        CallWebSocketController controller = new CallWebSocketController(
                mock(ICallService.class),
                mock(SimpMessagingTemplate.class),
                registry);

        SimpMessageHeaderAccessor accessor = SimpMessageHeaderAccessor.create();
        accessor.setSessionId("sess-1");
        Principal principal = () -> "user-1";

        controller.onPing(accessor, principal);

        assertTrue(registry.hasValidConnection("user-1"));
        assertFalse(registry.hasValidCallConnection("user-1"));

        registry.markCallQueueSubscribed("sess-1", true);
        assertTrue(registry.hasValidCallConnection("user-1"));
    }
}
