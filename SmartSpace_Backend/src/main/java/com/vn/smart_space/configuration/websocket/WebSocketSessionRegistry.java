package com.vn.smart_space.configuration.websocket;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.messaging.simp.user.SimpUser;
import org.springframework.messaging.simp.user.SimpUserRegistry;
import org.springframework.stereotype.Component;

import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j(topic = "WS-REGISTRY")
public class WebSocketSessionRegistry {

    public record ActiveWsSession(
            String sessionId,
            String userId,
            String deviceId,
            Instant connectedAt,
            Instant lastHeartbeatAt,
            Instant tokenExpiresAt,
            boolean authenticated,
            boolean subscribedToCallQueue) {
    }

    private final Map<String, ActiveWsSession> sessionsById = new ConcurrentHashMap<>();
    private final Map<String, Set<String>> sessionIdsByUser = new ConcurrentHashMap<>();

    @Autowired(required = false)
    private SimpUserRegistry simpUserRegistry;

    @Value("${webrtc.ws.heartbeat-timeout-seconds:35}")
    private long heartbeatTimeoutSeconds = 35L;

    public void setHeartbeatTimeoutSeconds(long heartbeatTimeoutSeconds) {
        this.heartbeatTimeoutSeconds = heartbeatTimeoutSeconds;
    }

    public void registerSession(String sessionId, String userId, String deviceId, Instant tokenExpiresAt) {
        if (sessionId == null || sessionId.isBlank() || userId == null || userId.isBlank()) {
            return;
        }
        Instant now = Instant.now();
        String effectiveDeviceId = (deviceId != null && !deviceId.isBlank()) ? deviceId : sessionId;
        ActiveWsSession session = new ActiveWsSession(
                sessionId, userId, effectiveDeviceId, now, now, tokenExpiresAt, true, false);
        sessionsById.put(sessionId, session);
        sessionIdsByUser.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet()).add(sessionId);
        log.debug("Registered WS session {} for user {} (device={})", sessionId, userId, effectiveDeviceId);
    }

    public void markCallQueueSubscribed(String sessionId, boolean subscribed) {
        if (sessionId == null || sessionId.isBlank()) {
            return;
        }
        sessionsById.computeIfPresent(sessionId, (id, existing) -> new ActiveWsSession(
                existing.sessionId(),
                existing.userId(),
                existing.deviceId(),
                existing.connectedAt(),
                Instant.now(),
                existing.tokenExpiresAt(),
                existing.authenticated(),
                subscribed));
    }

    public void touchSession(String sessionId) {
        if (sessionId == null || sessionId.isBlank()) {
            return;
        }
        sessionsById.computeIfPresent(sessionId, (id, existing) -> new ActiveWsSession(
                existing.sessionId(),
                existing.userId(),
                existing.deviceId(),
                existing.connectedAt(),
                Instant.now(),
                existing.tokenExpiresAt(),
                existing.authenticated(),
                existing.subscribedToCallQueue()));
    }

    public ActiveWsSession removeSession(String sessionId) {
        if (sessionId == null || sessionId.isBlank()) {
            return null;
        }
        ActiveWsSession removed = sessionsById.remove(sessionId);
        if (removed != null) {
            Set<String> userSessions = sessionIdsByUser.get(removed.userId());
            if (userSessions != null) {
                userSessions.remove(sessionId);
                if (userSessions.isEmpty()) {
                    sessionIdsByUser.remove(removed.userId(), userSessions);
                }
            }
            log.debug("Removed WS session {} for user {}", sessionId, removed.userId());
        }
        return removed;
    }

    public boolean hasValidConnection(String userId) {
        return !getValidSessions(userId).isEmpty();
    }

    public boolean hasValidCallConnection(String userId) {
        return getValidSessions(userId).stream().anyMatch(ActiveWsSession::subscribedToCallQueue);
    }

    public List<ActiveWsSession> getValidSessions(String userId) {
        if (userId == null || userId.isBlank()) {
            return List.of();
        }
        Set<String> ids = sessionIdsByUser.get(userId);
        if (ids == null || ids.isEmpty()) {
            return List.of();
        }

        Instant now = Instant.now();
        List<ActiveWsSession> valid = new ArrayList<>();
        for (String sessionId : List.copyOf(ids)) {
            ActiveWsSession s = sessionsById.get(sessionId);
            if (s == null) {
                ids.remove(sessionId);
                continue;
            }
            if (!isSessionCurrentlyValid(s, now)) {
                removeSession(sessionId);
                continue;
            }
            valid.add(s);
        }
        return valid;
    }

    public List<ActiveWsSession> evictStaleSessions() {
        Instant now = Instant.now();
        List<ActiveWsSession> evicted = new ArrayList<>();
        for (ActiveWsSession s : List.copyOf(sessionsById.values())) {
            if (!isSessionCurrentlyValid(s, now)) {
                ActiveWsSession removed = removeSession(s.sessionId());
                if (removed != null) {
                    evicted.add(removed);
                }
            }
        }
        return evicted;
    }

    private boolean isSessionCurrentlyValid(ActiveWsSession s, Instant now) {
        if (!s.authenticated()) {
            return false;
        }
        if (s.tokenExpiresAt() != null && now.isAfter(s.tokenExpiresAt())) {
            return false;
        }
        long timeout = Math.max(15L, heartbeatTimeoutSeconds);
        if (Duration.between(s.lastHeartbeatAt(), now).getSeconds() > timeout) {
            return false;
        }
        if (simpUserRegistry != null
                && Duration.between(s.connectedAt(), now).getSeconds() >= 5L) {
            SimpUser brokerUser = simpUserRegistry.getUser(s.userId());
            if (brokerUser == null || brokerUser.getSession(s.sessionId()) == null) {
                return false;
            }
        }
        return true;
    }
}
