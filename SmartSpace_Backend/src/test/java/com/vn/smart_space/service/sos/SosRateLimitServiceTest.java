package com.vn.smart_space.service.sos;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import com.vn.smart_space.consts.ESosResolution;

@ExtendWith(MockitoExtension.class)
class SosRateLimitServiceTest {

    @Mock
    StringRedisTemplate redisTemplate;
    @Mock
    ValueOperations<String, String> valueOps;

    SosRateLimitService service;

    @BeforeEach
    void setUp() {
        service = new SosRateLimitService(redisTemplate, 180, 1800, 2);
    }

    @Test
    void returnsRemainingCooldownSecondsWhenKeyActive() {
        when(redisTemplate.getExpire("sos:cooldown:u1", TimeUnit.SECONDS)).thenReturn(125L);
        assertEquals(125L, service.getRemainingCooldownSeconds("u1"));
    }

    @Test
    void failsOpenWhenRedisThrowsOnCooldownCheck() {
        when(redisTemplate.getExpire("sos:cooldown:u1", TimeUnit.SECONDS))
                .thenThrow(new RuntimeException("redis down"));
        assertEquals(0L, service.getRemainingCooldownSeconds("u1"));
    }

    @Test
    void recordsLongerCooldownForFalseAlarmThanSafeByUser() {
        when(redisTemplate.opsForValue()).thenReturn(valueOps);

        service.recordCooldown("u1", ESosResolution.SAFE_BY_USER);
        service.recordCooldown("u2", ESosResolution.FALSE_ALARM);

        verify(valueOps).set("sos:cooldown:u1", "SAFE_BY_USER", Duration.ofSeconds(180));
        verify(valueOps).set("sos:cooldown:u2", "FALSE_ALARM", Duration.ofSeconds(1800));
    }

    @Test
    void enforcesDailySmsQuotaAndSetsTtlOnFirstSend() {
        when(redisTemplate.opsForValue()).thenReturn(valueOps);
        when(valueOps.increment("sos:sms:daily:u1")).thenReturn(1L, 2L, 3L);

        assertTrue(service.tryConsumeSmsQuota("u1"));
        assertTrue(service.tryConsumeSmsQuota("u1"));
        assertFalse(service.tryConsumeSmsQuota("u1"));
        verify(redisTemplate).expire(eq("sos:sms:daily:u1"), any(Duration.class));
    }

    @Test
    void checksIfWithinSmsQuotaForResolvedNotification() {
        when(redisTemplate.opsForValue()).thenReturn(valueOps);
        when(valueOps.get("sos:sms:daily:u1")).thenReturn("2");
        when(valueOps.get("sos:sms:daily:u2")).thenReturn("3");

        assertTrue(service.isWithinSmsQuota("u1"));
        assertFalse(service.isWithinSmsQuota("u2"));
    }
}
