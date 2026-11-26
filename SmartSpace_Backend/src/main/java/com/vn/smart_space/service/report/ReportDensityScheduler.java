package com.vn.smart_space.service.report;

import java.time.Duration;
import java.util.UUID;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class ReportDensityScheduler {

    private static final String SCHEDULER_LOCK_KEY = "lock:map:density:scheduler";

    private final IReportDensityService reportDensityService;
    private final StringRedisTemplate redisTemplate;

    /**
     * Chạy định kỳ lúc 02:00 AM hàng ngày để Full Recalculation toàn bộ mật độ phản ánh.
     * Sử dụng Distributed Lock để đảm bảo trong môi trường multi-instance chỉ có 1 node thực thi.
     */
    @Scheduled(cron = "${app.map.density.cron:0 0 2 * * ?}")
    public void scheduleDailyRecalculation() {
        String lockVal = UUID.randomUUID().toString();
        Boolean acquired = redisTemplate.opsForValue().setIfAbsent(SCHEDULER_LOCK_KEY, lockVal, Duration.ofMinutes(15));

        if (Boolean.FALSE.equals(acquired)) {
            log.info("[ReportDensityScheduler] Another instance is already executing daily recalculation. Skipping.");
            return;
        }

        try {
            log.info("[ReportDensityScheduler] === Daily Density Recalculation Started ===");
            long start = System.currentTimeMillis();
            reportDensityService.triggerFullRecalculation(false);
            long elapsed = System.currentTimeMillis() - start;
            log.info("[ReportDensityScheduler] === Daily Density Recalculation Completed in {} ms ===", elapsed);
        } catch (Exception e) {
            log.error("[ReportDensityScheduler] Error during daily density recalculation: {}", e.getMessage(), e);
        } finally {
            try {
                String current = redisTemplate.opsForValue().get(SCHEDULER_LOCK_KEY);
                if (lockVal.equals(current)) {
                    redisTemplate.delete(SCHEDULER_LOCK_KEY);
                }
            } catch (Exception ignored) {
            }
        }
    }
}

