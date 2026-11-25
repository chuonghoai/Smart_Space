package com.vn.smart_space.service.call;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import com.vn.smart_space.dto.response.call.IceServerConfigResponse;

class TurnCredentialServiceTest {

    @Test
    void coturnHmacModeGeneratesTimeLimitedCredentials() {
        TurnCredentialService svc = new TurnCredentialService();
        ReflectionTestUtils.setField(svc, "stunUrlsRaw", "stun:stun.l.google.com:19302");
        ReflectionTestUtils.setField(svc, "turnMode", "coturn_hmac");
        ReflectionTestUtils.setField(svc, "turnUrlsRaw", "turn:turn.smartspace.local:3478?transport=udp");
        ReflectionTestUtils.setField(svc, "turnSharedSecret", "super-secret-coturn-key");
        ReflectionTestUtils.setField(svc, "turnTtlSeconds", 3600L);

        IceServerConfigResponse cfg = svc.buildIceServersForUser("u-123");
        assertTrue(cfg.isTurnConfigured());
        assertEquals("coturn_hmac", cfg.getMode());
        assertEquals(2, cfg.getIceServers().size());
        assertTrue(cfg.getIceServers().get(1).getUsername().endsWith(":u-123"));
        assertNotNull(cfg.getIceServers().get(1).getCredential());
        assertFalse(cfg.getIceServers().get(1).getCredential().isBlank());
    }

    @Test
    void stunOnlyModeMarksTurnUnconfigured() {
        TurnCredentialService svc = new TurnCredentialService();
        ReflectionTestUtils.setField(svc, "stunUrlsRaw", "stun:stun.l.google.com:19302");
        ReflectionTestUtils.setField(svc, "turnMode", "stun_only");
        ReflectionTestUtils.setField(svc, "turnTtlSeconds", 3600L);

        IceServerConfigResponse cfg = svc.buildIceServersForUser("u-123");
        assertFalse(cfg.isTurnConfigured());
        assertEquals(1, cfg.getIceServers().size());
    }
}
