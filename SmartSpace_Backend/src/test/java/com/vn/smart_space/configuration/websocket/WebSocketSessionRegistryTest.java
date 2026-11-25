package com.vn.smart_space.configuration.websocket;

import static org.junit.jupiter.api.Assertions.*;

import java.time.Instant;
import java.util.List;

import org.junit.jupiter.api.Test;

class WebSocketSessionRegistryTest {

    @Test
    void registersAndRequiresCallQueueSubscription() {
        WebSocketSessionRegistry registry = new WebSocketSessionRegistry();
        registry.registerSession("s1", "user-1", "dev-1", Instant.now().plusSeconds(300));

        assertTrue(registry.hasValidConnection("user-1"));
        assertFalse(registry.hasValidCallConnection("user-1"));

        registry.markCallQueueSubscribed("s1", true);
        assertTrue(registry.hasValidCallConnection("user-1"));

        registry.removeSession("s1");
        assertFalse(registry.hasValidConnection("user-1"));
        assertFalse(registry.hasValidCallConnection("user-1"));
    }

    @Test
    void evictsExpiredJwtSessionsAutomatically() {
        WebSocketSessionRegistry registry = new WebSocketSessionRegistry();
        registry.registerSession("s-exp", "user-exp", "dev-1", Instant.now().minusSeconds(1));
        registry.markCallQueueSubscribed("s-exp", true);

        assertFalse(registry.hasValidCallConnection("user-exp"));
        assertEquals(0, registry.getValidSessions("user-exp").size());
    }

    @Test
    void supportsMultipleDevicesPerUserIndependently() {
        WebSocketSessionRegistry registry = new WebSocketSessionRegistry();
        registry.registerSession("s-a", "user-multi", "dev-a", Instant.now().plusSeconds(300));
        registry.markCallQueueSubscribed("s-a", true);
        registry.registerSession("s-b", "user-multi", "dev-b", Instant.now().plusSeconds(300));
        registry.markCallQueueSubscribed("s-b", true);

        assertEquals(2, registry.getValidSessions("user-multi").size());
        registry.removeSession("s-a");
        assertTrue(registry.hasValidCallConnection("user-multi"));
        List<WebSocketSessionRegistry.ActiveWsSession> remaining = registry.getValidSessions("user-multi");
        assertEquals(1, remaining.size());
        assertEquals("dev-b", remaining.get(0).deviceId());
    }
}
