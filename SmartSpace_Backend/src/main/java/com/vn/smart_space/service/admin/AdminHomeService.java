package com.vn.smart_space.service.admin;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.response.admin.ActivityHistoryResponse;
import com.vn.smart_space.dto.response.admin.AdminOverviewResponse;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.report.ReportServiceImpl;
import com.vn.smart_space.utils.AnalyticsStatHelper;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.context.MessageSource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminHomeService {

    UserRepository userRepository;
    ReportRepository reportRepository;
    ActivityHistoryRepository activityHistoryRepository;
    MessageSource messageSource;

    public AdminOverviewResponse getOverview() {
        long unsatisfactoryProcessedCount = reportRepository.countByStatusAndIsReviewResolved(EReportStatus.processed, false);
        long rehandlingProcessingCount = reportRepository.countByStatusAndIsReviewResolved(EReportStatus.processing, false);
        // Cùng định nghĩa với Thống kê phản ánh: "Đang xử lý" không gồm báo cáo xử lý lại,
        // "Xử lý lại" = chờ giao lại (processed) + đang làm lại (processing).
        long processingCount = Math.max(0,
                reportRepository.countByStatus(EReportStatus.processing) - rehandlingProcessingCount);

        LocalDate today = LocalDate.now();
        LocalDateTime now = LocalDateTime.now();

        // 1. Volume Spike (14 prior days + today) & 7-day Inflow/Outflow pulse
        LocalDateTime since14d = today.minusDays(AnalyticsStatHelper.SPIKE_WINDOW_DAYS).atStartOfDay();
        Map<LocalDate, Long> createdCounts = new HashMap<>();
        for (LocalDateTime dt : reportRepository.findCreatedAtSince(since14d)) {
            if (dt != null) {
                createdCounts.merge(dt.toLocalDate(), 1L, Long::sum);
            }
        }
        List<Long> window14d = new ArrayList<>(AnalyticsStatHelper.SPIKE_WINDOW_DAYS);
        for (int i = AnalyticsStatHelper.SPIKE_WINDOW_DAYS; i >= 1; i--) {
            window14d.add(createdCounts.getOrDefault(today.minusDays(i), 0L));
        }
        long todayCount = createdCounts.getOrDefault(today, 0L);
        AnalyticsStatHelper.VolumeSpikeEvaluation spikeEval =
                AnalyticsStatHelper.evaluateVolumeSpike(todayCount, window14d);

        AdminOverviewResponse.VolumeSpikeAlert volumeSpike = AdminOverviewResponse.VolumeSpikeAlert.builder()
                .isSpike(spikeEval.isSpike())
                .insufficientData(spikeEval.insufficientData())
                .todayCount(spikeEval.todayCount())
                .baselineAvg14d(spikeEval.baselineAvg14d())
                .baselineStdDev14d(spikeEval.baselineStdDev14d())
                .zScore(spikeEval.zScore())
                .activeDays(spikeEval.activeDays())
                .build();

        Map<LocalDate, Long> resolvedCounts = new HashMap<>();
        LocalDateTime since7d = today.minusDays(6).atStartOfDay();
        for (LocalDateTime dt : reportRepository.findResolvedAtSince(EReportStatus.processed, since7d)) {
            if (dt != null) {
                resolvedCounts.merge(dt.toLocalDate(), 1L, Long::sum);
            }
        }
        DateTimeFormatter dayFmt = DateTimeFormatter.ofPattern("dd/MM");
        List<AdminOverviewResponse.DailyPulseItem> pulse7Days = AnalyticsStatHelper.buildConsecutiveDays(today, 7)
                .stream()
                .map(d -> AdminOverviewResponse.DailyPulseItem.builder()
                        .date(d.format(dayFmt))
                        .inflow(createdCounts.getOrDefault(d, 0L))
                        .outflow(resolvedCounts.getOrDefault(d, 0L))
                        .build())
                .collect(Collectors.toList());

        // 2. Severity historical avg resolution minutes (last 90d) for Early SLA Breach Warning
        Map<EReportSeverity, Long> avgMinutesBySeverity = new EnumMap<>(EReportSeverity.class);
        Map<EReportSeverity, Integer> sampleCountsBySeverity = new EnumMap<>(EReportSeverity.class);
        List<AnalyticsStatHelper.DurationSample> durationSamples = new ArrayList<>();
        for (Object[] row : reportRepository.findCompletedDurationsSince(EReportStatus.processed, now.minusDays(90))) {
            EReportSeverity sev = row[0] instanceof EReportSeverity s ? s : null;
            LocalDateTime assignedAt = AnalyticsStatHelper.toLocalDateTime(row[1] instanceof java.util.Date d ? d : null);
            LocalDateTime resolvedAt = row[2] instanceof LocalDateTime ldt ? ldt : null;
            if (sev != null && assignedAt != null && resolvedAt != null && !resolvedAt.isBefore(assignedAt)) {
                durationSamples.add(new AnalyticsStatHelper.DurationSample(
                        sev, Duration.between(assignedAt, resolvedAt).toMinutes()));
            }
        }
        Map<EReportSeverity, Long> fallbackDays = new EnumMap<>(EReportSeverity.class);
        for (EReportSeverity s : EReportSeverity.values()) {
            fallbackDays.put(s, ReportServiceImpl.deadlineDaysForSeverity(s));
        }
        AnalyticsStatHelper.computeP90Thresholds(
                durationSamples, fallbackDays, avgMinutesBySeverity, sampleCountsBySeverity, null);

        // 3. Evaluate open reports (pending + processing) for At-Risk, Pending >24h & Staff Overload
        List<Report> activeReports = reportRepository.findActiveReportsWithStaff(
                List.of(EReportStatus.pending, EReportStatus.processing));
        long pendingAtRisk = 0;
        long processingAtRisk = 0;
        long pendingOver24h = 0;
        LocalDateTime cutoff24h = now.minusHours(24);

        Map<String, Long> staffWeightedLoad = new HashMap<>();
        Map<String, Long> staffOverdueCount = new HashMap<>();

        for (Report r : activeReports) {
            LocalDateTime deadline = ReportServiceImpl.resolveDeadline(r);
            boolean atRisk = AnalyticsStatHelper.isSlaAtRisk(
                    r.getStatus(), r.getCreatedAt(), deadline, r.getSeverity(),
                    avgMinutesBySeverity, sampleCountsBySeverity, now);
            if (atRisk) {
                if (r.getStatus() == EReportStatus.pending) {
                    pendingAtRisk++;
                } else if (r.getStatus() == EReportStatus.processing) {
                    processingAtRisk++;
                }
            }
            if (r.getStatus() == EReportStatus.pending
                    && r.getCreatedAt() != null
                    && r.getCreatedAt().isBefore(cutoff24h)) {
                pendingOver24h++;
            }
            if (r.getStatus() == EReportStatus.processing && r.getAssignedStaff() != null) {
                String staffId = r.getAssignedStaff().getId();
                staffWeightedLoad.merge(staffId, AnalyticsStatHelper.severityWeight(r.getSeverity()), Long::sum);
                if (deadline != null && !deadline.isAfter(now)) {
                    staffOverdueCount.merge(staffId, 1L, Long::sum);
                }
            }
        }

        List<User> activeStaffs = userRepository.findByRole(ERole.staff).stream()
                .filter(u -> u.getStatus() != EUserStatus.blocked)
                .collect(Collectors.toList());
        double totalWeight = 0.0;
        for (User u : activeStaffs) {
            totalWeight += staffWeightedLoad.getOrDefault(u.getId(), 0L);
        }
        double teamAvgLoad = activeStaffs.isEmpty() ? 0.0 : totalWeight / activeStaffs.size();
        long overloadedStaffCount = 0;
        for (User u : activeStaffs) {
            long w = staffWeightedLoad.getOrDefault(u.getId(), 0L);
            long od = staffOverdueCount.getOrDefault(u.getId(), 0L);
            if (AnalyticsStatHelper.isOverloaded(w, teamAvgLoad, od)) {
                overloadedStaffCount++;
            }
        }

        return AdminOverviewResponse.builder()
                .userCount(userRepository.countByRole(ERole.client))
                .staffCount(userRepository.countByRole(ERole.staff))
                .adminCount(userRepository.countByRole(ERole.admin))
                .issueCount(reportRepository.countByStatusIn(List.of(EReportStatus.pending, EReportStatus.processing)))
                .pendingCount(reportRepository.countByStatus(EReportStatus.pending))
                .processingCount(processingCount)
                .rehandlingCount(unsatisfactoryProcessedCount + rehandlingProcessingCount)
                .unsatisfactoryProcessedCount(unsatisfactoryProcessedCount)
                .rehandlingProcessingCount(rehandlingProcessingCount)
                .volumeSpike(volumeSpike)
                .atRiskCount(pendingAtRisk + processingAtRisk)
                .pendingAtRiskCount(pendingAtRisk)
                .processingAtRiskCount(processingAtRisk)
                .overloadedStaffCount(overloadedStaffCount)
                .pendingOver24hCount(pendingOver24h)
                .pulse7Days(pulse7Days)
                .build();
    }

    public List<ActivityHistoryResponse> getRecentActivities(int limit, Locale locale) {
        List<ActivityHistory> activities = activityHistoryRepository.findRecentActivities(PageRequest.of(0, limit));
        return activities.stream().map(a -> mapToResponse(a, locale)).collect(Collectors.toList());
    }

    public PageResponse<ActivityHistoryResponse> getPaginatedActivities(
            int page, int size, String roleParam, String topicParam, String actorIdParam, Locale locale) {
        ERole role = null;
        if (roleParam != null && !roleParam.trim().isEmpty() && !"all".equalsIgnoreCase(roleParam.trim())) {
            try {
                role = ERole.valueOf(roleParam.trim().toLowerCase());
            } catch (Exception ignored) {
            }
        }

        String topicPrefix = null;
        if (topicParam != null && !topicParam.trim().isEmpty() && !"all".equalsIgnoreCase(topicParam.trim())) {
            String t = topicParam.trim().toLowerCase();
            switch (t) {
                case "news":
                    topicPrefix = "activity.news.";
                    break;
                case "report_create":
                    topicPrefix = "activity.report.created";
                    break;
                case "report_assign":
                    topicPrefix = "activity.report.assigned";
                    break;
                case "report_process":
                    topicPrefix = "activity.report.completed";
                    break;
                case "admin":
                    topicPrefix = "activity.admin.";
                    break;
                default:
                    topicPrefix = null;
            }
        }

        int pageIndex = Math.max(0, page - 1);
        Pageable pageable = PageRequest.of(pageIndex, size);
        String actorId = (actorIdParam != null && !actorIdParam.isBlank()) ? actorIdParam.trim() : null;
        Page<ActivityHistory> activityPage = activityHistoryRepository.findActivitiesWithFilter(
                role, actorId, topicPrefix, pageable);

        List<ActivityHistoryResponse> content = activityPage.getContent().stream()
                .map(a -> mapToResponse(a, locale))
                .collect(Collectors.toList());

        return PageResponse.<ActivityHistoryResponse>builder()
                .currentPage(page)
                .pageSize(size)
                .totalPages(activityPage.getTotalPages())
                .totalElements(activityPage.getTotalElements())
                .content(content)
                .build();
    }

    private ActivityHistoryResponse mapToResponse(ActivityHistory a, Locale locale) {
        String message = "";
        if (a.getI18nKey() != null && !a.getI18nKey().trim().isEmpty()) {
            String raw = a.getI18nKey().trim();
            String lang = (locale != null && "en".equalsIgnoreCase(locale.getLanguage())) ? "en" : "vi";
            Locale activeLocale = Locale.forLanguageTag(lang);
            if (raw.contains("|")) {
                String[] parts = raw.split("\\|", -1);
                String key = parts[0];
                Object[] args = java.util.Arrays.copyOfRange(parts, 1, parts.length);
                message = messageSource.getMessage(key, args, key, activeLocale);
            } else {
                int lastSpaceIndex = raw.lastIndexOf(' ');
                if (lastSpaceIndex != -1) {
                    String prefix = raw.substring(0, lastSpaceIndex).trim();
                    String key = raw.substring(lastSpaceIndex + 1).trim();

                    Object[] args;
                    if ("activity.report.assigned".equals(key)) {
                        String reportTitle = messageSource.getMessage("report.default_title", null, "Phản ánh", activeLocale);
                        String staffName = messageSource.getMessage("staff.default_name", null, "nhân viên", activeLocale);
                        if (a.getTargetId() != null) {
                            var optReport = reportRepository.findById(a.getTargetId());
                            if (optReport.isPresent()) {
                                var rep = optReport.get();
                                if (rep.getTitle() != null && !rep.getTitle().trim().isEmpty()) {
                                    reportTitle = rep.getTitle().trim();
                                }
                                if (rep.getAssignedStaff() != null && rep.getAssignedStaff().getFullName() != null) {
                                    staffName = rep.getAssignedStaff().getFullName().trim();
                                }
                            }
                        }
                        args = new Object[]{prefix, reportTitle, staffName};
                    } else {
                        args = new Object[]{prefix};
                    }

                    String translated = messageSource.getMessage(key, args, key, activeLocale);
                    message = prefix.isEmpty() ? translated : (translated.contains(prefix) ? translated : prefix + " " + translated);
                } else {
                    String fallbackActor = (a.getActor() != null && a.getActor().getFullName() != null
                            && !a.getActor().getFullName().isBlank())
                            ? a.getActor().getFullName().trim()
                            : (a.getActor() != null && a.getActor().getEmail() != null
                                    ? a.getActor().getEmail().trim()
                                    : "");
                    Object[] bareArgs = fallbackActor.isEmpty() ? null : new Object[]{fallbackActor};
                    message = messageSource.getMessage(raw, bareArgs, raw, activeLocale);
                }
            }
            if (message != null) {
                message = message.replaceAll("\\s*\"?\\{\\d+\\}\"?\\s*", " ").replaceAll("\\s+", " ").trim();
            }
        }
        String actorName = a.getActor() != null ? a.getActor().getFullName() : null;
        String actorAvatar = a.getActor() != null ? a.getActor().getAvatarUrl() : null;

        String targetType = "OTHER";
        if (a.getI18nKey() != null) {
            String lowerKey = a.getI18nKey().toLowerCase();
            if (lowerKey.contains("news")) {
                targetType = "NEWS";
            } else if (lowerKey.contains("report")) {
                targetType = "REPORT";
            } else if (lowerKey.contains("staff") || lowerKey.contains("user") || lowerKey.contains("position")) {
                targetType = "USER";
            }
        }

        return ActivityHistoryResponse.builder()
                .id(a.getId())
                .actorName(actorName)
                .actorAvatarUrl(actorAvatar)
                .targetId(a.getTargetId())
                .targetType(targetType)
                .message(message)
                .createdAt(a.getCreatedAt())
                .build();
    }
}

