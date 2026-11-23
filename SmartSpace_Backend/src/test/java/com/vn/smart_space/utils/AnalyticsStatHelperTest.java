package com.vn.smart_space.utils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.EnumMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.context.support.ResourceBundleMessageSource;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.dto.response.admin.AdminSpatialAnalyticsResponse;

class AnalyticsStatHelperTest {

    @Test
    void volumeSpike_requiresSufficientActiveDaysAndThreshold() {
        List<Long> sparse = Arrays.asList(0L, 0L, 1L, 0L, 2L, 0L, 0L, 0L, 0L, 1L, 0L, 0L, 0L, 0L);
        var evalSparse = AnalyticsStatHelper.evaluateVolumeSpike(12L, sparse);
        assertTrue(evalSparse.insufficientData());
        assertFalse(evalSparse.isSpike());

        List<Long> active = Arrays.asList(3L, 4L, 2L, 3L, 5L, 3L, 4L, 2L, 3L, 4L, 3L, 2L, 4L, 3L);
        var evalNormal = AnalyticsStatHelper.evaluateVolumeSpike(4L, active);
        assertFalse(evalNormal.insufficientData());
        assertFalse(evalNormal.isSpike());

        var evalSpike = AnalyticsStatHelper.evaluateVolumeSpike(10L, active);
        assertFalse(evalSpike.insufficientData());
        assertTrue(evalSpike.isSpike());
        assertTrue(evalSpike.zScore() >= 2.0);
    }

    @Test
    void slaAtRisk_detectsPendingOver50PercentAndProcessingWithinThreshold() {
        LocalDateTime now = LocalDateTime.of(2026, 11, 20, 12, 0);
        LocalDateTime created = now.minusHours(30);
        LocalDateTime deadlinePending = created.plusHours(48); // >50% elapsed (30/48)
        assertTrue(AnalyticsStatHelper.isSlaAtRisk(
                EReportStatus.pending, created, deadlinePending, EReportSeverity.high, Map.of(), Map.of(), now));

        LocalDateTime deadlineFreshPending = now.plusHours(40); // created 4h ago -> 4/44 < 50%
        assertFalse(AnalyticsStatHelper.isSlaAtRisk(
                EReportStatus.pending, now.minusHours(4), deadlineFreshPending, EReportSeverity.high, Map.of(), Map.of(), now));

        // Processing with 12h left (<= 24h)
        assertTrue(AnalyticsStatHelper.isSlaAtRisk(
                EReportStatus.processing, created, now.plusHours(12), EReportSeverity.medium, Map.of(), Map.of(), now));

        // Processing already overdue is NOT marked atRisk (already overdue)
        assertFalse(AnalyticsStatHelper.isSlaAtRisk(
                EReportStatus.processing, created, now.minusHours(1), EReportSeverity.medium, Map.of(), Map.of(), now));
    }

    @Test
    void p90Thresholds_usesFallbackBelow10SamplesAndComputesPercentileAbove10() {
        Map<EReportSeverity, Long> fallbackDays = new EnumMap<>(EReportSeverity.class);
        for (EReportSeverity s : EReportSeverity.values()) {
            fallbackDays.put(s, 3L);
        }
        List<AnalyticsStatHelper.DurationSample> samples = new ArrayList<>();
        // 12 samples for high severity: 100..1200 minutes
        for (int i = 1; i <= 12; i++) {
            samples.add(new AnalyticsStatHelper.DurationSample(EReportSeverity.high, i * 100L));
        }
        Map<EReportSeverity, Integer> counts = new EnumMap<>(EReportSeverity.class);
        Map<EReportSeverity, Boolean> insuff = new EnumMap<>(EReportSeverity.class);
        Map<EReportSeverity, Long> p90 = AnalyticsStatHelper.computeP90Thresholds(
                samples, fallbackDays, null, counts, insuff);

        assertFalse(insuff.get(EReportSeverity.high));
        assertTrue(insuff.get(EReportSeverity.low));
        assertEquals(Math.round(3L * 24 * 60 * 0.8), p90.get(EReportSeverity.low));
        assertNotNull(p90.get(EReportSeverity.high));
        assertTrue(p90.get(EReportSeverity.high) >= 1000L && p90.get(EReportSeverity.high) <= 1200L);
        assertNull(AnalyticsStatHelper.computePercentile(List.of(), 0.90));
    }

    @Test
    void staffWeightedWorkload_evaluatesSeverityAndOverloadHints() {
        assertEquals(1L, AnalyticsStatHelper.severityWeight(EReportSeverity.low));
        assertEquals(5L, AnalyticsStatHelper.severityWeight(EReportSeverity.critical));
        assertFalse(AnalyticsStatHelper.isOverloaded(4L, 3.0, 0L));
        assertTrue(AnalyticsStatHelper.isOverloaded(8L, 4.0, 0L)); // > max(5, 1.5*4=6)
        assertTrue(AnalyticsStatHelper.isOverloaded(2L, 4.0, 2L)); // >= 2 overdue
        assertEquals("recommended", AnalyticsStatHelper.assignmentHint(1L, 4.0, false));
        assertEquals("overloaded", AnalyticsStatHelper.assignmentHint(9L, 4.0, true));
    }

    @Test
    void h3Hotspots_detectsAcceleratingCellAndComputesRiskScore() {
        LocalDateTime now = LocalDateTime.of(2026, 11, 20, 12, 0);
        double lat = 10.8505;
        double lng = 106.7719;
        List<AnalyticsStatHelper.SpatialReportPoint> points = List.of(
                new AnalyticsStatHelper.SpatialReportPoint("1", lat, lng, EReportStatus.pending, EReportSeverity.critical,
                        now.plusHours(10), now.minusDays(2), "Khu A"),
                new AnalyticsStatHelper.SpatialReportPoint("2", lat, lng, EReportStatus.processing, EReportSeverity.high,
                        now.minusHours(2), now.minusDays(5), "Khu A"),
                new AnalyticsStatHelper.SpatialReportPoint("3", lat, lng, EReportStatus.processed, EReportSeverity.low,
                        now.plusDays(1), now.minusDays(10), "Khu A"),
                new AnalyticsStatHelper.SpatialReportPoint("4", lat, lng, EReportStatus.processed, EReportSeverity.low,
                        now.plusDays(1), now.minusDays(60), "Khu A") // prev 90d avg = 1/3 = 0.33
        );
        List<AdminSpatialAnalyticsResponse.HotspotItem> hotspots =
                AnalyticsStatHelper.computeH3Hotspots(points, now, 10);
        assertEquals(1, hotspots.size());
        var h = hotspots.get(0);
        assertTrue(h.isAccelerating());
        assertEquals(3L, h.getCountLast30d());
        assertEquals("Khu A", h.getSampleAddress());
        // risk = pending(1)*2 + highCritical(2)*3 + overdue(1)*4 = 2 + 6 + 4 = 12
        assertEquals(12L, h.getRiskScore());
    }

    @Test
    void messageBundles_containCancelledAndUpdatedReportActivityKeys() {
        ResourceBundleMessageSource ms = new ResourceBundleMessageSource();
        ms.setBasename("i18n/messages");
        ms.setDefaultEncoding("UTF-8");

        String viCancelled = ms.getMessage("activity.report.cancelled", new Object[] { "An" }, Locale.forLanguageTag("vi"));
        String enCancelled = ms.getMessage("activity.report.cancelled", new Object[] { "An" }, Locale.ENGLISH);
        String viUpdated = ms.getMessage("activity.report.updated", new Object[] { "An" }, Locale.forLanguageTag("vi"));
        String enUpdated = ms.getMessage("activity.report.updated", new Object[] { "An" }, Locale.ENGLISH);

        assertFalse(viCancelled.contains("activity.report.cancelled"));
        assertTrue(viCancelled.contains("An"));
        assertFalse(enCancelled.contains("activity.report.cancelled"));
        assertTrue(enCancelled.contains("An"));
        assertFalse(viUpdated.contains("activity.report.updated"));
        assertFalse(enUpdated.contains("activity.report.updated"));
    }
}
