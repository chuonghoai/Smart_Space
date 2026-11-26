package com.vn.smart_space.service.sos;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import com.vn.smart_space.consts.ESosResolution;

import lombok.extern.slf4j.Slf4j;

/**
 * Giới hạn chống spam SOS lưu trên Redis: cooldown sau khi kết thúc SOS và hạn mức SMS theo ngày.
 * Fail-open khi Redis gián đoạn để không chặn nhầm tình huống khẩn cấp thật.
 */
@Slf4j
@Service
public class SosRateLimitService {

    static final String COOLDOWN_KEY_PREFIX = "sos:cooldown:";
    static final String SMS_DAILY_KEY_PREFIX = "sos:sms:daily:";
    private static final Duration SMS_WINDOW = Duration.ofHours(24);

    private final StringRedisTemplate redisTemplate;
    private final long safeCooldownSeconds;
    private final long falseAlarmCooldownSeconds;
    private final int smsDailyLimit;

    public SosRateLimitService(
            StringRedisTemplate redisTemplate,
            @Value("${app.sos.anti-spam.safe-cooldown-seconds:180}") long safeCooldownSeconds,
            @Value("${app.sos.anti-spam.false-alarm-cooldown-seconds:1800}") long falseAlarmCooldownSeconds,
            @Value("${app.sos.anti-spam.sms-daily-limit:2}") int smsDailyLimit) {
        this.redisTemplate = redisTemplate;
        this.safeCooldownSeconds = safeCooldownSeconds;
        this.falseAlarmCooldownSeconds = falseAlarmCooldownSeconds;
        this.smsDailyLimit = smsDailyLimit;
    }

    /** Số giây còn lại trong thời gian chờ trước khi user được tạo SOS mới (0 = không bị chặn). */
    public long getRemainingCooldownSeconds(String userId) {
        try {
            Long ttl = redisTemplate.getExpire(cooldownKey(userId), TimeUnit.SECONDS);
            return ttl != null && ttl > 0 ? ttl : 0L;
        } catch (Exception e) {
            log.warn("[SOS] Redis cooldown check failed for user={}, failing open: {}", userId, e.getMessage());
            return 0L;
        }
    }

    /** Đặt cooldown sau khi kết thúc SOS: báo động nhầm bị chờ lâu hơn tự báo an toàn. */
    public void recordCooldown(String userId, ESosResolution resolution) {
        long seconds = resolution == ESosResolution.FALSE_ALARM ? falseAlarmCooldownSeconds : safeCooldownSeconds;
        if (seconds <= 0) {
            return;
        }
        try {
            redisTemplate.opsForValue().set(
                    cooldownKey(userId),
                    resolution != null ? resolution.name() : "CLOSED",
                    Duration.ofSeconds(seconds));
        } catch (Exception e) {
            log.warn("[SOS] Redis cooldown write failed for user={}: {}", userId, e.getMessage());
        }
    }

    /**
     * Ghi nhận 1 lượt gửi SMS SOS trong cửa sổ 24 giờ.
     *
     * @return true nếu còn hạn mức SMS; false nếu đã vượt mức (vẫn gửi push/WS bình thường)
     */
    public boolean tryConsumeSmsQuota(String userId) {
        if (smsDailyLimit <= 0) {
            return false;
        }
        String key = smsDailyKey(userId);
        try {
            Long count = redisTemplate.opsForValue().increment(key);
            if (count == null) {
                return true;
            }
            if (count == 1L) {
                redisTemplate.expire(key, SMS_WINDOW);
            }
            return count <= smsDailyLimit;
        } catch (Exception e) {
            log.warn("[SOS] Redis SMS quota check failed for user={}, failing open: {}", userId, e.getMessage());
            return true;
        }
    }

    /** Kiểm tra user có nằm trong hạn mức SMS không để gửi tin báo kết thúc SOS. */
    public boolean isWithinSmsQuota(String userId) {
        if (smsDailyLimit <= 0) {
            return false;
        }
        try {
            String raw = redisTemplate.opsForValue().get(smsDailyKey(userId));
            if (raw == null || raw.isBlank()) {
                return true;
            }
            return Long.parseLong(raw) <= smsDailyLimit;
        } catch (Exception e) {
            log.warn("[SOS] Redis SMS quota read failed for user={}, failing open: {}", userId, e.getMessage());
            return true;
        }
    }

    private static String cooldownKey(String userId) {
        return COOLDOWN_KEY_PREFIX + userId;
    }

    private static String smsDailyKey(String userId) {
        return SMS_DAILY_KEY_PREFIX + userId;
    }
}
