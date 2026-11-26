package com.vn.smart_space.utils;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Gom nhóm dữ liệu theo thời gian cho các biểu đồ xu hướng (daily / weekly / monthly).
 * Mỗi bucket được định danh bằng ngày bắt đầu: ngày (daily), thứ Hai (weekly), ngày 1 (monthly).
 * Các bucket không có dữ liệu vẫn được trả về với giá trị 0 (zero-fill).
 */
public final class TrendBucketHelper {

    public static final int DAILY_BUCKETS = 30;
    public static final int WEEKLY_BUCKETS = 12;
    public static final int MONTHLY_BUCKETS = 12;

    private TrendBucketHelper() {
    }

    /** "weekly" | "monthly" | "daily" (mặc định cho mọi giá trị khác). */
    public static String normalizePeriod(String period) {
        if ("weekly".equalsIgnoreCase(period)) {
            return "weekly";
        }
        if ("monthly".equalsIgnoreCase(period)) {
            return "monthly";
        }
        return "daily";
    }

    /** Danh sách ngày bắt đầu của các bucket, cũ → mới, bucket cuối chứa [today]. */
    public static List<LocalDate> buckets(String period, LocalDate today) {
        LocalDate first;
        int count;
        ChronoUnit unit;
        switch (normalizePeriod(period)) {
            case "weekly" -> {
                first = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                        .minusWeeks(WEEKLY_BUCKETS - 1L);
                count = WEEKLY_BUCKETS;
                unit = ChronoUnit.WEEKS;
            }
            case "monthly" -> {
                first = today.withDayOfMonth(1).minusMonths(MONTHLY_BUCKETS - 1L);
                count = MONTHLY_BUCKETS;
                unit = ChronoUnit.MONTHS;
            }
            default -> {
                first = today.minusDays(DAILY_BUCKETS - 1L);
                count = DAILY_BUCKETS;
                unit = ChronoUnit.DAYS;
            }
        }

        List<LocalDate> result = new ArrayList<>(count);
        for (int i = 0; i < count; i++) {
            result.add(first.plus(i, unit));
        }
        return result;
    }

    /** Map bucket → 0, giữ thứ tự thời gian. */
    public static Map<LocalDate, Long> emptyCounts(List<LocalDate> buckets) {
        Map<LocalDate, Long> counts = new LinkedHashMap<>();
        buckets.forEach(b -> counts.put(b, 0L));
        return counts;
    }

    /** Cộng 1 vào bucket chứa [date]; bỏ qua nếu nằm ngoài khoảng. */
    public static void increment(Map<LocalDate, Long> counts, LocalDate date, String period) {
        if (date == null) {
            return;
        }
        counts.computeIfPresent(toBucket(date, normalizePeriod(period)), (k, v) -> v + 1);
    }

    private static LocalDate toBucket(LocalDate date, String period) {
        return switch (period) {
            case "weekly" -> date.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
            case "monthly" -> date.withDayOfMonth(1);
            default -> date;
        };
    }
}
