package com.vn.smart_space.utils;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.uber.h3core.H3Core;
import com.uber.h3core.util.LatLng;
import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.dto.response.admin.AdminSpatialAnalyticsResponse;
import com.vn.smart_space.service.report.ReportDensityServiceImpl;

/**
 * Stateless statistical & operational warning algorithms for Admin Smart Analytics (Section 4.1).
 * Kept dependency-free so unit tests can exercise every threshold directly.
 */
public final class AnalyticsStatHelper {

    public static final int SPIKE_WINDOW_DAYS = 14;
    public static final int SPIKE_MIN_ACTIVE_DAYS = 7;
    public static final long SPIKE_MIN_COUNT = 5L;
    public static final double SPIKE_ZSCORE_THRESHOLD = 2.0;
    public static final double SPIKE_RATIO_THRESHOLD = 1.5;

    public static final long SLA_AT_RISK_PROCESSING_HOURS = 24L;
    public static final double SLA_AT_RISK_PENDING_RATIO = 0.5;
    public static final int MIN_SEVERITY_SAMPLES = 10;

    public static final double TEAM_OVERLOAD_MIN_LOAD = 5.0;
    public static final double TEAM_OVERLOAD_MULTIPLIER = 1.5;
    public static final long STAFF_OVERLOAD_OVERDUE_LIMIT = 2L;

    public static final int HOTSPOT_MIN_RECENT_COUNT = 3;
    public static final double HOTSPOT_ACCEL_MULTIPLIER = 2.0;
    public static final int HOTSPOT_H3_RESOLUTION = ReportDensityServiceImpl.H3_RESOLUTION;

    private AnalyticsStatHelper() {
    }

    private static final class H3Holder {
        private static final H3Core INSTANCE = createH3();

        private static H3Core createH3() {
            try {
                return H3Core.newInstance();
            } catch (Exception e) {
                throw new IllegalStateException("Failed to initialize Uber H3", e);
            }
        }
    }

    public static record VolumeSpikeEvaluation(
            long todayCount,
            double baselineAvg14d,
            double baselineStdDev14d,
            double zScore,
            int activeDays,
            boolean isSpike,
            boolean insufficientData) {
    }

    public static record DurationSample(
            EReportSeverity severity,
            long durationMinutes) {
    }

    public static record SpatialReportPoint(
            String id,
            Double latitude,
            Double longitude,
            EReportStatus status,
            EReportSeverity severity,
            LocalDateTime deadline,
            LocalDateTime createdAt,
            String address) {
    }

    public static long severityWeight(EReportSeverity severity) {
        if (severity == null) {
            return 1L;
        }
        return switch (severity) {
            case low -> 1L;
            case medium -> 2L;
            case high -> 3L;
            case critical -> 5L;
        };
    }

    public static double computeMean(List<? extends Number> values) {
        if (values == null || values.isEmpty()) {
            return 0.0;
        }
        double sum = 0.0;
        for (Number v : values) {
            sum += v != null ? v.doubleValue() : 0.0;
        }
        return sum / values.size();
    }

    public static double computeStdDev(List<? extends Number> values, double mean) {
        if (values == null || values.size() <= 1) {
            return 0.0;
        }
        double sumSq = 0.0;
        for (Number v : values) {
            double diff = (v != null ? v.doubleValue() : 0.0) - mean;
            sumSq += diff * diff;
        }
        return Math.sqrt(sumSq / (values.size() - 1));
    }

    public static double computeZScore(double current, double mean, double stdDev) {
        if (stdDev <= 1e-9) {
            return 0.0;
        }
        return (current - mean) / stdDev;
    }

    /**
     * Evaluate whether [todayCount] is an abnormal spike relative to [baseline14d]
     * (ordered or unordered list of the previous 14 days excluding today).
     */
    public static VolumeSpikeEvaluation evaluateVolumeSpike(long todayCount, List<Long> baseline14d) {
        List<Long> safeWindow = baseline14d != null ? baseline14d : Collections.emptyList();
        int activeDays = (int) safeWindow.stream().filter(c -> c != null && c > 0).count();
        boolean insufficientData = activeDays < SPIKE_MIN_ACTIVE_DAYS || safeWindow.isEmpty();

        double mean = computeMean(safeWindow);
        double stdDev = computeStdDev(safeWindow, mean);
        double zScore = computeZScore((double) todayCount, mean, stdDev);

        boolean aboveFloor = todayCount >= SPIKE_MIN_COUNT;
        boolean meetsZ = stdDev > 1e-9 && zScore >= SPIKE_ZSCORE_THRESHOLD;
        boolean meetsRatio = mean > 0.0 && todayCount >= SPIKE_RATIO_THRESHOLD * mean;
        boolean isSpike = !insufficientData && aboveFloor && (meetsZ || meetsRatio);

        return new VolumeSpikeEvaluation(
                todayCount,
                round2(mean),
                round2(stdDev),
                round2(zScore),
                activeDays,
                isSpike,
                insufficientData);
    }

    /**
     * Evaluates daily spike flags across consecutive daily counts ordered oldest -> newest.
     * Index 0..i-1 (up to 14 prior days) forms the moving baseline for each day i.
     */
    public static List<Boolean> detectSeriesAnomalies(List<Long> countsOldestToNewest) {
        if (countsOldestToNewest == null || countsOldestToNewest.isEmpty()) {
            return Collections.emptyList();
        }
        List<Boolean> flags = new ArrayList<>(countsOldestToNewest.size());
        for (int i = 0; i < countsOldestToNewest.size(); i++) {
            int start = Math.max(0, i - SPIKE_WINDOW_DAYS);
            List<Long> window = countsOldestToNewest.subList(start, i);
            if (window.size() < SPIKE_MIN_ACTIVE_DAYS) {
                flags.add(false);
                continue;
            }
            VolumeSpikeEvaluation eval = evaluateVolumeSpike(countsOldestToNewest.get(i), window);
            flags.add(eval.isSpike());
        }
        return flags;
    }

    /**
     * Linearly interpolated percentile on already-known durations (in minutes).
     * Returns null if values is empty.
     */
    public static Long computePercentile(List<Long> values, double percentile) {
        if (values == null || values.isEmpty()) {
            return null;
        }
        List<Long> sorted = new ArrayList<>(values.size());
        for (Long v : values) {
            if (v != null && v >= 0) {
                sorted.add(v);
            }
        }
        if (sorted.isEmpty()) {
            return null;
        }
        Collections.sort(sorted);
        double clampedP = Math.max(0.0, Math.min(1.0, percentile));
        double idx = clampedP * (sorted.size() - 1);
        int lower = (int) Math.floor(idx);
        int upper = (int) Math.ceil(idx);
        if (lower == upper) {
            return sorted.get(lower);
        }
        double interpolated = sorted.get(lower) + (idx - lower) * (sorted.get(upper) - sorted.get(lower));
        return Math.round(interpolated);
    }

    /**
     * Computes P90 and mean resolution minutes per severity from 90-day completed samples.
     * When sample count for a severity < 10, falls back to 80% of severity's SLA deadline window
     * and marks insufficientSamples=true.
     */
    public static Map<EReportSeverity, Long> computeP90Thresholds(
            List<DurationSample> samples,
            Map<EReportSeverity, Long> fallbackDeadlineDays,
            Map<EReportSeverity, Long> outAvgMinutes,
            Map<EReportSeverity, Integer> outSampleCounts,
            Map<EReportSeverity, Boolean> outInsufficientSamples) {
        Map<EReportSeverity, List<Long>> grouped = new EnumMap<>(EReportSeverity.class);
        for (EReportSeverity s : EReportSeverity.values()) {
            grouped.put(s, new ArrayList<>());
        }
        if (samples != null) {
            for (DurationSample sample : samples) {
                if (sample != null && sample.severity() != null && sample.durationMinutes() >= 0) {
                    grouped.get(sample.severity()).add(sample.durationMinutes());
                }
            }
        }

        Map<EReportSeverity, Long> p90Map = new EnumMap<>(EReportSeverity.class);
        for (EReportSeverity s : EReportSeverity.values()) {
            List<Long> list = grouped.get(s);
            int count = list.size();
            if (outSampleCounts != null) {
                outSampleCounts.put(s, count);
            }
            if (outAvgMinutes != null) {
                outAvgMinutes.put(s, count > 0 ? Math.round(computeMean(list)) : null);
            }
            boolean insufficient = count < MIN_SEVERITY_SAMPLES;
            if (outInsufficientSamples != null) {
                outInsufficientSamples.put(s, insufficient);
            }
            if (!insufficient) {
                p90Map.put(s, computePercentile(list, 0.90));
            } else {
                long days = fallbackDeadlineDays != null ? fallbackDeadlineDays.getOrDefault(s, 3L) : 3L;
                long fallbackMinutes = Math.round(days * 24.0 * 60.0 * 0.8);
                p90Map.put(s, fallbackMinutes);
            }
        }
        return p90Map;
    }

    /**
     * Checks whether an active (non-overdue) report is at early risk of breaching its SLA deadline.
     */
    public static boolean isSlaAtRisk(
            EReportStatus status,
            LocalDateTime createdAt,
            LocalDateTime effectiveDeadline,
            EReportSeverity severity,
            Map<EReportSeverity, Long> avgMinutesBySeverity,
            Map<EReportSeverity, Integer> sampleCountsBySeverity,
            LocalDateTime now) {
        if (effectiveDeadline == null || now == null || !effectiveDeadline.isAfter(now)) {
            return false;
        }
        if (status == EReportStatus.pending) {
            if (createdAt == null || !effectiveDeadline.isAfter(createdAt)) {
                return false;
            }
            long totalMinutes = Duration.between(createdAt, effectiveDeadline).toMinutes();
            long elapsedMinutes = Duration.between(createdAt, now).toMinutes();
            return totalMinutes > 0 && elapsedMinutes >= Math.round(totalMinutes * SLA_AT_RISK_PENDING_RATIO);
        }
        if (status == EReportStatus.processing) {
            long remainingMinutes = Duration.between(now, effectiveDeadline).toMinutes();
            long thresholdMinutes = SLA_AT_RISK_PROCESSING_HOURS * 60L;
            if (severity != null && sampleCountsBySeverity != null
                    && sampleCountsBySeverity.getOrDefault(severity, 0) >= MIN_SEVERITY_SAMPLES
                    && avgMinutesBySeverity != null && avgMinutesBySeverity.get(severity) != null) {
                thresholdMinutes = Math.max(thresholdMinutes, avgMinutesBySeverity.get(severity));
            }
            return remainingMinutes <= thresholdMinutes;
        }
        return false;
    }

    public static long computeProcessingElapsedMinutes(Date assignedAt, LocalDateTime createdAt, LocalDateTime now) {
        if (now == null) {
            return 0L;
        }
        LocalDateTime anchor = assignedAt != null ? toLocalDateTime(assignedAt) : createdAt;
        if (anchor == null || anchor.isAfter(now)) {
            return 0L;
        }
        return Duration.between(anchor, now).toMinutes();
    }

    public static boolean isProcessingBottleneck(
            EReportStatus status,
            EReportSeverity severity,
            Date assignedAt,
            LocalDateTime createdAt,
            Map<EReportSeverity, Long> p90BySeverity,
            LocalDateTime now) {
        if (status != EReportStatus.processing || p90BySeverity == null) {
            return false;
        }
        EReportSeverity effectiveSeverity = severity != null ? severity : EReportSeverity.low;
        Long threshold = p90BySeverity.get(effectiveSeverity);
        if (threshold == null || threshold <= 0) {
            return false;
        }
        return computeProcessingElapsedMinutes(assignedAt, createdAt, now) > threshold;
    }

    public static boolean isOverloaded(long weightedLoad, double teamAvgWeightedLoad, long overdueCount) {
        double threshold = Math.max(TEAM_OVERLOAD_MIN_LOAD, TEAM_OVERLOAD_MULTIPLIER * teamAvgWeightedLoad);
        return weightedLoad > threshold || overdueCount >= STAFF_OVERLOAD_OVERDUE_LIMIT;
    }

    public static String assignmentHint(long weightedLoad, double teamAvgWeightedLoad, boolean overloaded) {
        if (overloaded) {
            return "overloaded";
        }
        if (weightedLoad == 0 || weightedLoad <= Math.max(2.0, teamAvgWeightedLoad * 0.75)) {
            return "recommended";
        }
        return "normal";
    }

    /**
     * Groups non-rejected reports into Uber H3 Resolution-11 cells and identifies hotspots
     * whose recent 30-day inflow accelerates >= 2x over the previous 90-day 30d baseline.
     */
    public static List<AdminSpatialAnalyticsResponse.HotspotItem> computeH3Hotspots(
            List<SpatialReportPoint> points,
            LocalDateTime now,
            int limit) {
        if (points == null || points.isEmpty()) {
            return Collections.emptyList();
        }
        LocalDateTime cutoff30d = now.minusDays(30);
        LocalDateTime cutoff120d = now.minusDays(120);

        final class CellAccumulator {
            long countLast30d;
            long prev90dCount;
            long pendingCount;
            long processingCount;
            long highCriticalCount;
            long overdueCount;
            LocalDateTime latestCreatedAt;
            String sampleAddress;
        }

        H3Core h3 = H3Holder.INSTANCE;
        Map<String, CellAccumulator> cells = new HashMap<>();

        for (SpatialReportPoint p : points) {
            if (p == null || p.latitude() == null || p.longitude() == null || p.status() == EReportStatus.rejected) {
                continue;
            }
            if (Math.abs(p.latitude()) > 90.0 || Math.abs(p.longitude()) > 180.0) {
                continue;
            }
            String cellId;
            try {
                cellId = h3.latLngToCellAddress(p.latitude(), p.longitude(), HOTSPOT_H3_RESOLUTION);
            } catch (Exception ignored) {
                continue;
            }

            CellAccumulator acc = cells.computeIfAbsent(cellId, k -> new CellAccumulator());
            if (p.createdAt() != null) {
                if (!p.createdAt().isBefore(cutoff30d)) {
                    acc.countLast30d++;
                } else if (!p.createdAt().isBefore(cutoff120d)) {
                    acc.prev90dCount++;
                }
                if (acc.latestCreatedAt == null || p.createdAt().isAfter(acc.latestCreatedAt)) {
                    if (p.address() != null && !p.address().isBlank()) {
                        acc.latestCreatedAt = p.createdAt();
                        acc.sampleAddress = p.address().trim();
                    }
                }
            }

            boolean isActive = p.status() == EReportStatus.pending || p.status() == EReportStatus.processing;
            if (isActive) {
                if (p.status() == EReportStatus.pending) {
                    acc.pendingCount++;
                } else {
                    acc.processingCount++;
                }
                if (p.severity() == EReportSeverity.high || p.severity() == EReportSeverity.critical) {
                    acc.highCriticalCount++;
                }
                if (p.deadline() != null && !p.deadline().isAfter(now)) {
                    acc.overdueCount++;
                }
            }
        }

        List<AdminSpatialAnalyticsResponse.HotspotItem> items = new ArrayList<>();
        for (Map.Entry<String, CellAccumulator> entry : cells.entrySet()) {
            CellAccumulator acc = entry.getValue();
            if (acc.countLast30d == 0 && acc.pendingCount == 0 && acc.processingCount == 0) {
                continue;
            }
            double prevAvg = round2(acc.prev90dCount / 3.0);
            boolean isAccelerating = acc.countLast30d >= HOTSPOT_MIN_RECENT_COUNT
                    && (prevAvg == 0.0 || acc.countLast30d >= HOTSPOT_ACCEL_MULTIPLIER * prevAvg);
            double growthRatio = prevAvg > 0.0
                    ? round2(acc.countLast30d / prevAvg)
                    : (acc.countLast30d > 0 ? (double) acc.countLast30d : 0.0);
            long riskScore = acc.pendingCount * 2L + acc.highCriticalCount * 3L + acc.overdueCount * 4L;

            LatLng center = h3.cellToLatLng(entry.getKey());
            items.add(AdminSpatialAnalyticsResponse.HotspotItem.builder()
                    .h3Index(entry.getKey())
                    .centerLat(center.lat)
                    .centerLng(center.lng)
                    .sampleAddress(acc.sampleAddress)
                    .countLast30d(acc.countLast30d)
                    .prev90dAvg30d(prevAvg)
                    .growthRatio(growthRatio)
                    .isAccelerating(isAccelerating)
                    .pendingCount(acc.pendingCount)
                    .processingCount(acc.processingCount)
                    .highCriticalCount(acc.highCriticalCount)
                    .overdueCount(acc.overdueCount)
                    .riskScore(riskScore)
                    .build());
        }

        items.sort(Comparator
                .comparingLong(AdminSpatialAnalyticsResponse.HotspotItem::getRiskScore).reversed()
                .thenComparing(Comparator.comparing(
                        AdminSpatialAnalyticsResponse.HotspotItem::isAccelerating).reversed())
                .thenComparing(Comparator.comparingLong(
                        AdminSpatialAnalyticsResponse.HotspotItem::getCountLast30d).reversed()));

        int safeLimit = limit > 0 ? Math.min(limit, items.size()) : items.size();
        return items.subList(0, safeLimit);
    }

    public static List<LocalDate> buildConsecutiveDays(LocalDate endInclusive, int days) {
        List<LocalDate> result = new ArrayList<>(days);
        LocalDate start = endInclusive.minusDays(days - 1L);
        for (int i = 0; i < days; i++) {
            result.add(start.plusDays(i));
        }
        return result;
    }

    public static LocalDateTime toLocalDateTime(Date date) {
        return date == null
                ? null
                : LocalDateTime.ofInstant(Instant.ofEpochMilli(date.getTime()), ZoneId.systemDefault());
    }

    public static Date toDate(LocalDateTime dateTime) {
        return dateTime == null
                ? null
                : Date.from(dateTime.atZone(ZoneId.systemDefault()).toInstant());
    }

    public static double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
