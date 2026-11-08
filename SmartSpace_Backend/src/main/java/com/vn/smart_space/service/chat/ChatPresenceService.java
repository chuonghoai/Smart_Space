package com.vn.smart_space.service.chat;

import java.time.Duration;
import java.util.Set;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j(topic = "CHAT-PRESENCE")
public class ChatPresenceService {

    private static final String PRESENCE_PREFIX = "chat:presence:";
    private static final Duration TTL = Duration.ofSeconds(60);

    private final StringRedisTemplate redisTemplate;

    public void enterConversation(String userId, String conversationId) {
        try {
            String key = buildKey(userId, conversationId);
            redisTemplate.opsForValue().set(key, "1", TTL);
            log.debug("User {} entered conversation {}", userId, conversationId);
        } catch (Exception e) {
            log.warn("Redis error on enterConversation for user {}: {}", userId, e.getMessage());
        }
    }

    public void heartbeat(String userId, String conversationId) {
        try {
            String key = buildKey(userId, conversationId);
            redisTemplate.expire(key, TTL);
            log.debug("Heartbeat for user {} in conversation {}", userId, conversationId);
        } catch (Exception e) {
            log.warn("Redis error on heartbeat for user {}: {}", userId, e.getMessage());
        }
    }

    public void leaveConversation(String userId, String conversationId) {
        try {
            String key = buildKey(userId, conversationId);
            redisTemplate.delete(key);
            log.debug("User {} left conversation {}", userId, conversationId);
        } catch (Exception e) {
            log.warn("Redis error on leaveConversation for user {}: {}", userId, e.getMessage());
        }
    }

    public boolean isUserViewingConversation(String userId, String conversationId) {
        try {
            String key = buildKey(userId, conversationId);
            Boolean hasKey = redisTemplate.hasKey(key);
            return Boolean.TRUE.equals(hasKey);
        } catch (Exception e) {
            log.warn("Redis error checking presence for user {}: {}", userId, e.getMessage());
            return false;
        }
    }

    public void clearUserPresence(String userId) {
        try {
            Set<String> keys = redisTemplate.keys(PRESENCE_PREFIX + userId + ":*");
            if (keys != null && !keys.isEmpty()) {
                redisTemplate.delete(keys);
                log.debug("Cleared {} presence keys for user {}", keys.size(), userId);
            }
        } catch (Exception e) {
            log.warn("Failed to clear presence keys for user {}: {}", userId, e.getMessage());
        }
    }

    private String buildKey(String userId, String conversationId) {
        return PRESENCE_PREFIX + userId + ":" + conversationId;
    }
}
