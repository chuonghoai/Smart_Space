package com.vn.smart_space.service.report;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.context.MessageSource;
import org.springframework.data.domain.Limit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.request.admin.ReportAssignRequest;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.request.report.ReportCompleteRequest;
import com.vn.smart_space.dto.request.report.ReportCreateRequest;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.response.admin.AdminMapReportsResponse;
import com.vn.smart_space.dto.response.admin.MapReportResponse;
import com.vn.smart_space.dto.response.admin.RecentReportResponse;
import com.vn.smart_space.dto.response.admin.ReportListResponse;
import com.vn.smart_space.dto.response.admin.ReportStatisticsResponse;
import com.vn.smart_space.dto.response.admin.ReportTrendResponse;
import com.vn.smart_space.dto.response.notification.NotificationEvent;
import com.vn.smart_space.dto.response.report.MapReportsResponse;
import com.vn.smart_space.dto.response.report.NearbyReportItemResponse;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.dto.response.report.ReportNearbyAlertResponse;
import com.vn.smart_space.dto.response.report.ReportResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.exception.UnauthorizedException;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;
import com.vn.smart_space.model.WalletConfig;
import com.vn.smart_space.service.wallet.IStaffWalletService;
import com.vn.smart_space.service.wallet.IWalletConfigService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class ReportServiceImpl implements IReportService {

    private final ReportRepository reportRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final IFCMService fcmService;
    private final INotificationService notificationService;
    private final ActivityHistoryRepository activityHistoryRepository;
    private final MessageSource messageSource;
    private final IStaffWalletService staffWalletService;
    private final IWalletConfigService walletConfigService;

    private static final int MAP_DEFAULT_LIMIT = 300;
    private static final int MAP_MAX_LIMIT = 500;
    private static final int MAP_PROCESSED_VISIBLE_DAYS = 30;

    @Override
    @Transactional(readOnly = true)
    public List<ReportResponse> getDangerousReports() {
        List<Report> reports = reportRepository.findTopBySeverityInOrderByCreatedAtDesc(
                Arrays.asList(EReportSeverity.high, EReportSeverity.critical),
                Limit.of(5));
        return reports.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReportResponse> getRecentReports(String filter, Double userLat, Double userLong) {
        List<Report> reports;
        boolean calculateDistance = false;

        if ("near_by".equalsIgnoreCase(filter) && userLat != null && userLong != null) {
            reports = reportRepository.findNearestReports(userLat, userLong, Limit.of(5));
            calculateDistance = true;
        } else {
            reports = reportRepository.findTopByOrderByCreatedAtDesc(Limit.of(5));
        }

        final boolean calcDist = calculateDistance;
        return reports.stream().map(r -> {
            ReportResponse res = mapToResponse(r);
            if (calcDist) {
                res.setDistanceInMeters(
                        calculateHaversineDistance(userLat, userLong, r.getLatitude(), r.getLongitude()));
            }
            return res;
        }).collect(Collectors.toList());
    }

    private ReportResponse mapToResponse(Report report) {
        return ReportResponse.builder()
                .id(report.getId())
                .title(report.getTitle())
                .description(report.getDescription())
                .imageUrl(report.getImageUrl())
                .latitude(report.getLatitude())
                .longitude(report.getLongitude())
                .status(report.getStatus().name())
                .severity(report.getSeverity() != null ? report.getSeverity().name() : null)
                .createdAt(report.getCreatedAt() != null ? report.getCreatedAt().format(DateTimeFormatter.ISO_DATE_TIME)
                        : null)
                .assignedAt(report.getAssignedAt() != null
                        ? report.getAssignedAt().toInstant().atZone(java.time.ZoneId.systemDefault())
                                .format(DateTimeFormatter.ISO_DATE_TIME)
                        : null)
                .isReviewResolved(report.getIsReviewResolved())
                .userId(report.getUser() != null ? report.getUser().getId() : null)
                .build();
    }

    private double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371000; // Radius of the earth in meters
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                        * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    @Override
    @Transactional
    public ReportDetailResponse createReport(ReportCreateRequest request, String userId) {

        Report report = new Report();
        report.setTitle(request.getTitle());
        report.setDescription(request.getDescription());
        report.setLatitude(request.getLatitude());
        report.setLongitude(request.getLongitude());
        report.setSeverity(EReportSeverity.low);
        report.setStatus(EReportStatus.pending);
        report.setAddress(request.getAddress());
        report.setLocationDescription(request.getLocationDescription());
        report.setIsAnonymous(request.getIsAnonymous() != null ? request.getIsAnonymous() : false);

        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            report.setImageUrls(String.join(",", request.getImageUrls()));
            report.setImageUrl(request.getImageUrls().get(0));
        }

        if (userId != null) {
            User user = userRepository.findById(userId).orElse(null);
            report.setUser(user);
        }

        report = reportRepository.save(report);

        if (userId != null) {
            User actor = report.getUser();
            String actorName = (actor != null && actor.getFullName() != null && !actor.getFullName().trim().isEmpty())
                    ? actor.getFullName().trim()
                    : (actor != null && actor.getEmail() != null ? actor.getEmail().trim() : "Người dùng");
            String i18nKey = "activity.report.created|" + actorName;

            ActivityHistory activity = ActivityHistory.builder()
                    .actor(actor)
                    .i18nKey(i18nKey)
                    .targetId(report.getId())
                    .build();
            activityHistoryRepository.save(activity);
        }

        ReportDetailResponse response = ReportDetailResponse.builder()
                .id(report.getId())
                .title(report.getTitle())
                .description(report.getDescription())
                .imageUrls(request.getImageUrls())
                .latitude(report.getLatitude())
                .longitude(report.getLongitude())
                .status(report.getStatus().name())
                .severity(report.getSeverity().name())
                .isAnonymous(report.getIsAnonymous())
                .address(report.getAddress())
                .locationDescription(report.getLocationDescription())
                .createdAt(report.getCreatedAt() != null ? report.getCreatedAt().format(DateTimeFormatter.ISO_DATE_TIME)
                        : null)
                .assignedAt(report.getAssignedAt() != null
                        ? report.getAssignedAt().toInstant().atZone(java.time.ZoneId.systemDefault())
                                .format(DateTimeFormatter.ISO_DATE_TIME)
                        : null)
                .userId(userId)
                .build();

        // Notify Users
        if (userId != null) {
            try {
                String title = "Tạo phản ánh thành công";
                String message = "Phản ánh của bạn đã được ghi nhận và đang chờ xử lý.";

                // Standardized actionData: { "type": "...", "payload": { ... } }
                String actionData = "{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"" + report.getId()
                        + "\"}}";

                // Create DB Notification
                notificationService.createNotification(userId, title, message, actionData, report.getImageUrl());

                // Send WebSocket Event to the user
                NotificationEvent event = new NotificationEvent(title, message, actionData, report.getImageUrl(),
                        Map.of("shouldRefresh", true));
                messagingTemplate.convertAndSendToUser(userId, "/queue/notifications", event);

                // Send FCM
                Map<String, String> fcmData = Map.of(
                        "type", "REPORT_DETAIL",
                        "payload", "{\"reportId\":\"" + report.getId() + "\"}");
                NotificationRequest notif = new NotificationRequest(title, message, fcmData);
                fcmService.sendToUser(userId, notif);
            } catch (Exception e) {
                log.warn("[Notify] Failed to send notification for report {}: {}", report.getId(), e.getMessage());
            }
        }

        // Notify Admins
        try {
            List<User> admins = userRepository.findByRole(ERole.admin);
            if (admins != null && !admins.isEmpty()) {
                String adminTitle = "Có phản ánh mới";
                String adminMessage = report.getTitle() != null && !report.getTitle().trim().isEmpty()
                        ? report.getTitle().trim()
                        : "Một phản ánh mới vừa được tạo và đang chờ xử lý.";

                String createdAtStr = report.getCreatedAt() != null
                        ? report.getCreatedAt().format(DateTimeFormatter.ISO_DATE_TIME)
                        : java.time.LocalDateTime.now().format(DateTimeFormatter.ISO_DATE_TIME);

                String adminActionData = String.format(
                        "{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"%s\", \"title\": \"%s\", \"status\": \"%s\", \"severity\": \"%s\", \"createdAt\": \"%s\", \"imageUrl\": \"%s\", \"address\": \"%s\"}}",
                        report.getId(),
                        report.getTitle() != null ? report.getTitle().replace("\"", "\\\"") : "",
                        report.getStatus() != null ? report.getStatus().name() : "pending",
                        report.getSeverity() != null ? report.getSeverity().name() : "low",
                        createdAtStr,
                        report.getImageUrl() != null ? report.getImageUrl() : "",
                        report.getAddress() != null ? report.getAddress().replace("\"", "\\\"")
                                : (report.getLocationDescription() != null
                                        ? report.getLocationDescription().replace("\"", "\\\"")
                                        : ""));

                NotificationEvent adminEvent = new NotificationEvent(adminTitle, adminMessage, adminActionData,
                        report.getImageUrl(), Map.of("shouldRefresh", true));
                Map<String, String> adminFcmData = Map.of(
                        "type", "REPORT_DETAIL",
                        "payload", "{\"reportId\":\"" + report.getId() + "\"}");
                NotificationRequest adminNotif = new NotificationRequest(adminTitle, adminMessage, adminFcmData);

                for (User admin : admins) {
                    try {
                        notificationService.createNotification(admin.getId(), adminTitle, adminMessage,
                                adminActionData, report.getImageUrl());
                        messagingTemplate.convertAndSendToUser(admin.getId(), "/queue/notifications", adminEvent);
                        fcmService.sendToUser(admin.getId(), adminNotif);
                    } catch (Exception ex) {
                        log.warn("[Notify Admin] Failed to notify admin {}: {}", admin.getId(), ex.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            log.warn("[Notify Admin] Error while notifying admins for report {}: {}", report.getId(), e.getMessage());
        }

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public ReportDetailResponse getReportDetail(String reportId) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("report.not_found"));
        return toDetail(report);
    }

    @Override
    @Transactional(readOnly = true)
    public ReportDetailResponse getReportDetail(String reportId, String viewerId, String viewerScope) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("report.not_found"));
        boolean privileged = "ROLE_admin".equals(viewerScope) || "ROLE_staff".equals(viewerScope);
        boolean owner = viewerId != null && report.getUser() != null && viewerId.equals(report.getUser().getId());
        if (privileged || owner) {
            return toDetail(report);
        }
        if (report.getStatus() == EReportStatus.rejected) {
            throw new ResourceNotFoundException("report.not_found");
        }
        return toPublic(toDetail(report));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ReportDetailResponse> getFeed(String status, int page, int size, Double userLat,
            Double userLong) {
        int safePage = Math.max(1, page);
        int safeSize = Math.max(1, Math.min(size, 20));
        EReportStatus filter = null;
        if (status != null && !status.isBlank() && !"all".equalsIgnoreCase(status)) {
            try {
                filter = EReportStatus.valueOf(status.toLowerCase());
            } catch (IllegalArgumentException ignored) {
            }
        }
        if (filter == EReportStatus.rejected) {
            filter = null;
        }
        Page<Report> reportPage = reportRepository.findFeed(EReportStatus.rejected, filter,
                PageRequest.of(safePage - 1, safeSize));
        List<ReportDetailResponse> content = reportPage.getContent().stream().map(r -> {
            ReportDetailResponse res = toPublic(toDetail(r));
            if (userLat != null && userLong != null && r.getLatitude() != null && r.getLongitude() != null) {
                res.setDistanceInMeters(
                        calculateHaversineDistance(userLat, userLong, r.getLatitude(), r.getLongitude()));
            }
            return res;
        }).collect(Collectors.toList());
        return PageResponse.<ReportDetailResponse>builder()
                .currentPage(safePage)
                .pageSize(safeSize)
                .totalPages(reportPage.getTotalPages())
                .totalElements(reportPage.getTotalElements())
                .content(content)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public MapReportsResponse getReportsInBounds(Double minLat, Double maxLat, Double minLng, Double maxLng,
            int limit) {
        validateMapBounds(minLat, maxLat, minLng, maxLng);
        int safeLimit = safeMapLimit(limit, MAP_DEFAULT_LIMIT);

        // Fetch one extra row to know whether the viewport holds more than safeLimit
        // reports
        List<Report> reports = reportRepository.findInBounds(minLat, maxLat, minLng, maxLng,
                EReportStatus.rejected, EReportStatus.processed,
                LocalDateTime.now().minusDays(MAP_PROCESSED_VISIBLE_DAYS),
                Limit.of(safeLimit + 1));

        boolean truncated = reports.size() > safeLimit;
        List<ReportResponse> content = reports.stream()
                .limit(safeLimit)
                .map(this::mapToResponse)
                .collect(Collectors.toList());

        return MapReportsResponse.builder()
                .reports(content)
                .truncated(truncated)
                .build();
    }

    /** Shared by client & admin map: every bound present, in range, and min <= max. */
    private void validateMapBounds(Double minLat, Double maxLat, Double minLng, Double maxLng) {
        if (!isValidLatitude(minLat) || !isValidLatitude(maxLat)
                || !isValidLongitude(minLng) || !isValidLongitude(maxLng)
                || minLat > maxLat || minLng > maxLng) {
            throw new BadRequestException("report.map.invalid_bounds");
        }
    }

    private int safeMapLimit(int limit, int defaultLimit) {
        return limit <= 0 ? defaultLimit : Math.min(limit, MAP_MAX_LIMIT);
    }

    private boolean isValidLatitude(Double value) {
        return value != null && value >= -90 && value <= 90;
    }

    private boolean isValidLongitude(Double value) {
        return value != null && value >= -180 && value <= 180;
    }

    /**
     * Strips contact info for public viewers; also hides identity of anonymous
     * reports.
     */
    private ReportDetailResponse toPublic(ReportDetailResponse res) {
        res.setUserPhone(null);
        res.setAssignedStaffPhone(null);
        res.setAssignedStaffEmail(null);
        if (Boolean.TRUE.equals(res.getIsAnonymous())) {
            res.setUserName(null);
            res.setUserAvatarUrl(null);
        }
        return res;
    }

    private ReportDetailResponse toDetail(Report report) {
        User user = report.getUser();
        User staff = report.getAssignedStaff();

        List<String> images = null;
        if (report.getImageUrls() != null && !report.getImageUrls().trim().isEmpty()) {
            images = Arrays.stream(report.getImageUrls().split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList());
        } else if (report.getImageUrl() != null && !report.getImageUrl().trim().isEmpty()) {
            images = List.of(report.getImageUrl().trim());
        }

        List<String> resolvedImages = null;
        if (report.getResolvedImageUrls() != null && !report.getResolvedImageUrls().trim().isEmpty()) {
            resolvedImages = Arrays.stream(report.getResolvedImageUrls().split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList());
        }

        List<String> reviewImages = null;
        if (report.getReviewImageUrls() != null && !report.getReviewImageUrls().trim().isEmpty()) {
            reviewImages = Arrays.stream(report.getReviewImageUrls().split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .collect(Collectors.toList());
        }

        Double baseCommission = report.getBaseCommission();
        Double deductedCommission = report.getTotalCommissionDeducted() != null ? report.getTotalCommissionDeducted() : 0.0;
        Double finalCommission = baseCommission != null ? Math.max(0.0, baseCommission - deductedCommission) : null;
        Double expectedCommission = null;
        if (report.getStatus() == EReportStatus.processing && !Boolean.TRUE.equals(report.getCommissionAwarded())) {
            try {
                WalletConfig config = walletConfigService.getOrCreateDefaultConfig();
                EReportSeverity sev = report.getSeverity() != null ? report.getSeverity() : EReportSeverity.low;
                expectedCommission = switch (sev) {
                    case low -> config.getCommissionLow();
                    case medium -> config.getCommissionMedium();
                    case high -> config.getCommissionHigh();
                    case critical -> config.getCommissionCritical();
                };
            } catch (Exception ignored) {
            }
        }

        return ReportDetailResponse.builder()
                .id(report.getId())
                .title(report.getTitle())
                .description(report.getDescription())
                .imageUrls(images)
                .latitude(report.getLatitude())
                .longitude(report.getLongitude())
                .status(report.getStatus() != null ? report.getStatus().name() : null)
                .severity(report.getSeverity() != null ? report.getSeverity().name() : null)
                .isAnonymous(report.getIsAnonymous())
                .address(report.getAddress())
                .locationDescription(report.getLocationDescription())
                .createdAt(report.getCreatedAt() != null ? report.getCreatedAt().format(DateTimeFormatter.ISO_DATE_TIME)
                        : null)
                .assignedAt(report.getAssignedAt() != null
                        ? report.getAssignedAt().toInstant().atZone(java.time.ZoneId.systemDefault())
                                .format(DateTimeFormatter.ISO_DATE_TIME)
                        : null)
                .userName(user != null ? user.getFullName() : null)
                .userPhone(user != null ? user.getPhone() : null)
                .userAvatarUrl(user != null ? user.getAvatarUrl() : null)
                .assignedStaffId(staff != null ? staff.getId() : null)
                .assignedStaffName(staff != null ? staff.getFullName() : null)
                .assignedStaffPhone(staff != null ? staff.getPhone() : null)
                .assignedStaffEmail(staff != null ? staff.getEmail() : null)
                .assignedStaffAvatarUrl(staff != null ? staff.getAvatarUrl() : null)
                .resolvedNote(report.getResolvedNote())
                .resolvedImageUrls(resolvedImages)
                .resolvedAt(report.getResolvedAt() != null ? report.getResolvedAt().toInstant()
                        .atZone(java.time.ZoneId.systemDefault()).format(DateTimeFormatter.ISO_DATE_TIME) : null)
                .isReviewResolved(report.getIsReviewResolved())
                .rating(report.getRating())
                .reviewNote(report.getReviewNote())
                .reviewImageUrls(reviewImages)
                .reviewedAt(report.getReviewedAt() != null ? report.getReviewedAt().toInstant()
                        .atZone(java.time.ZoneId.systemDefault()).format(DateTimeFormatter.ISO_DATE_TIME) : null)
                .userId(user != null ? user.getId() : null)
                .baseCommission(baseCommission)
                .deductedCommission(deductedCommission)
                .finalCommission(finalCommission)
                .expectedCommission(expectedCommission)
                .commissionAwarded(report.getCommissionAwarded())
                .rehandlingPenaltyCount(report.getRehandlingPenaltyCount())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<RecentReportResponse> getAdminRecentReports(String tab, int limit) {
        List<EReportStatus> statuses;
        if ("all".equalsIgnoreCase(tab)) {
            statuses = List.of(EReportStatus.pending, EReportStatus.processing);
        } else if ("pending".equalsIgnoreCase(tab)) {
            statuses = List.of(EReportStatus.pending);
        } else if ("processing".equalsIgnoreCase(tab)) {
            statuses = List.of(EReportStatus.processing);
        } else if ("resolved".equalsIgnoreCase(tab)) {
            statuses = List.of(EReportStatus.processed);
        } else {
            statuses = List.of(EReportStatus.pending, EReportStatus.processing);
        }

        List<Report> reports = reportRepository.findByStatusInOrderByCreatedAtDesc(statuses, PageRequest.of(0, limit));

        return reports.stream().map(r -> {
            User staff = r.getAssignedStaff();
            User user = r.getUser();
            boolean anon = Boolean.TRUE.equals(r.getIsAnonymous());
            return RecentReportResponse.builder()
                    .id(r.getId())
                    .title(r.getTitle())
                    .status(r.getStatus())
                    .severity(r.getSeverity())
                    .createdAt(r.getCreatedAt())
                    .imageUrl((r.getImageUrls() != null && !r.getImageUrls().trim().isEmpty())
                            ? r.getImageUrls().split(",")[0].trim()
                            : r.getImageUrl())
                    .address(r.getAddress() != null && !r.getAddress().trim().isEmpty() ? r.getAddress()
                            : r.getLocationDescription())
                    .assignedStaffName(staff != null ? staff.getFullName() : null)
                    .assignedStaffAvatarUrl(staff != null ? staff.getAvatarUrl() : null)
                    .isAnonymous(anon)
                    .userName(user != null ? user.getFullName() : null)
                    .userEmail(user != null ? user.getEmail() : null)
                    .isReviewResolved(r.getIsReviewResolved())
                    .build();
        }).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public ReportDetailResponse assignReport(
            String reportId,
            ReportAssignRequest request,
            String adminId) {

        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("report.not_found"));

        User staff = userRepository.findById(request.getStaffId())
                .orElseThrow(() -> new ResourceNotFoundException("staff.not_found"));

        if (request.getSeverity() != null && !request.getSeverity().trim().isEmpty()) {
            try {
                report.setSeverity(EReportSeverity.valueOf(request.getSeverity().toLowerCase()));
            } catch (Exception ignored) {
            }
        }

        report.setAssignedStaff(staff);
        report.setStatus(EReportStatus.processing);
        report.setAssignedAt(new java.util.Date());
        report = reportRepository.save(report);

        // Save Activity History
        User admin = adminId != null ? userRepository.findById(adminId).orElse(null) : null;
        String adminName = admin != null && admin.getFullName() != null && !admin.getFullName().trim().isEmpty()
                ? admin.getFullName().trim()
                : (admin != null && admin.getEmail() != null ? admin.getEmail().trim() : "Quản trị viên");
        String staffName = staff.getFullName() != null && !staff.getFullName().trim().isEmpty()
                ? staff.getFullName().trim()
                : (staff.getEmail() != null ? staff.getEmail().trim() : "Nhân viên");
        String reportTitle = report.getTitle() != null && !report.getTitle().trim().isEmpty()
                ? report.getTitle().trim()
                : "Phản ánh";
        String i18nKey = "activity.report.assigned|" + adminName + "|" + reportTitle + "|" + staffName;

        ActivityHistory activity = ActivityHistory.builder()
                .actor(admin)
                .i18nKey(i18nKey)
                .targetId(report.getId())
                .build();
        activityHistoryRepository.save(activity);

        // Notify Admins via WebSocket & FCM
        try {
            List<User> admins = userRepository.findByRole(ERole.admin);
            String actionData = String.format(
                    "{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"%s\", \"title\": \"%s\", \"status\": \"processing\", \"severity\": \"%s\"}}",
                    report.getId(),
                    report.getTitle() != null ? report.getTitle().replace("\"", "\\\"") : "",
                    report.getSeverity() != null ? report.getSeverity().name() : "low");

            for (User a : admins) {
                try {
                    java.util.Locale adminLocale = new java.util.Locale(
                            a.getLanguage() != null ? a.getLanguage() : "vi");
                    String title = messageSource.getMessage("notification.report.assigned.admin.title", null,
                            "Phân công phản ánh thành công", adminLocale);
                    String staffN = staff.getFullName() != null && !staff.getFullName().trim().isEmpty()
                            ? staff.getFullName().trim()
                            : (staff.getEmail() != null ? staff.getEmail().trim() : "Nhân viên");
                    String message = messageSource.getMessage("notification.report.assigned.admin.message",
                            new Object[] { report.getTitle(), staffN },
                            String.format("Phản ánh '%s' đã được giao cho %s.", report.getTitle(), staffN),
                            adminLocale);

                    notificationService.createNotification(a.getId(), title, message, actionData, report.getImageUrl());
                    NotificationEvent event = new NotificationEvent(title, message, actionData, report.getImageUrl(),
                            Map.of("shouldRefresh", true));
                    messagingTemplate.convertAndSendToUser(a.getId(), "/queue/notifications", event);
                } catch (Exception ex) {
                }
            }
        } catch (Exception ignored) {
        }

        // Notify Staff via WebSocket & FCM
        if (staff != null) {
            try {
                java.util.Locale staffLocale = new java.util.Locale(
                        staff.getLanguage() != null ? staff.getLanguage() : "vi");
                String staffTitle = messageSource.getMessage("notification.report.assigned.staff.title", null,
                        "Phân công mới", staffLocale);
                String staffMessage = messageSource.getMessage("notification.report.assigned.staff.message",
                        new Object[] { report.getTitle() },
                        String.format("Bạn đã được phân công xử lý phản ánh '%s'.", report.getTitle()), staffLocale);

                String staffActionData = String
                        .format("{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"%s\"}}", report.getId());

                notificationService.createNotification(staff.getId(), staffTitle, staffMessage,
                        staffActionData, report.getImageUrl());
                Map<String, Object> staffData = new java.util.HashMap<>();
                staffData.put("shouldRefresh", true);
                staffData.put("stats", getStaffReportStatistics(staff.getId()));
                NotificationEvent staffEvent = new NotificationEvent(staffTitle, staffMessage, staffActionData,
                        report.getImageUrl(), staffData);
                messagingTemplate.convertAndSendToUser(staff.getId(), "/queue/notifications", staffEvent);

                NotificationRequest staffNotif = new NotificationRequest(
                        staffTitle, staffMessage,
                        Map.of("type", "REPORT_DETAIL", "payload", "{\"reportId\":\"" + report.getId() + "\"}"));
                fcmService.sendToUser(staff.getId(), staffNotif);
            } catch (Exception ignored) {
            }
        }

        // Notify Client
        if (report.getUser() != null) {
            try {
                User client = report.getUser();
                java.util.Locale clientLocale = new java.util.Locale(
                        client.getLanguage() != null ? client.getLanguage() : "vi");
                String clientTitle = messageSource.getMessage("notification.report.assigned.client.title", null,
                        "Phản ánh đang được xử lý", clientLocale);
                String clientMessage = messageSource.getMessage("notification.report.assigned.client.message",
                        new Object[] { report.getTitle() },
                        String.format("Phản ánh '%s' của bạn đã được phân công xử lý.", report.getTitle()),
                        clientLocale);

                String clientActionData = String
                        .format("{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"%s\"}}", report.getId());

                notificationService.createNotification(client.getId(), clientTitle, clientMessage,
                        clientActionData, report.getImageUrl());
                NotificationEvent clientEvent = new NotificationEvent(clientTitle, clientMessage, clientActionData,
                        report.getImageUrl(), Map.of("shouldRefresh", true));
                messagingTemplate.convertAndSendToUser(client.getId(), "/queue/notifications", clientEvent);

                NotificationRequest clientNotif = new NotificationRequest(
                        clientTitle, clientMessage,
                        Map.of("type", "REPORT_DETAIL", "payload", "{\"reportId\":\"" + report.getId() + "\"}"));
                fcmService.sendToUser(report.getUser().getId(), clientNotif);
            } catch (Exception ignored) {
            }
        }

        return getReportDetail(report.getId());
    }

    @Override
    @Transactional
    public ReportDetailResponse completeReport(
            String reportId,
            ReportCompleteRequest request,
            String staffId) {

        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("report.not_found"));

        User staff = staffId != null ? userRepository.findById(staffId).orElse(null) : null;
        if (staff != null && report.getAssignedStaff() == null) {
            report.setAssignedStaff(staff);
        }

        report.setStatus(EReportStatus.processed);
        if (request.getNote() != null && !request.getNote().trim().isEmpty()) {
            report.setResolvedNote(request.getNote().trim());
        }
        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            report.setResolvedImageUrls(String.join(",", request.getImageUrls()));
        }
        report.setResolvedAt(new java.util.Date());

        // Reset previous citizen review when report is completed or re-handled so
        // client can submit a new review
        report.setIsReviewResolved(null);
        report.setRating(null);
        report.setReviewNote(null);
        report.setReviewImageUrls(null);
        report.setReviewedAt(null);

        report = reportRepository.save(report);

        // Process staff wallet commission
        try {
            staffWalletService.processReportCompletedCommission(report);
        } catch (Exception ex) {
            log.error("[Staff Wallet] Error processing commission for report {}: {}", report.getId(), ex.getMessage());
        }

        // Save Activity History
        String staffName = staff != null && staff.getFullName() != null && !staff.getFullName().trim().isEmpty()
                ? staff.getFullName().trim()
                : (staff != null && staff.getEmail() != null ? staff.getEmail().trim() : "Nhân viên");
        String reportTitle = report.getTitle() != null && !report.getTitle().trim().isEmpty()
                ? report.getTitle().trim()
                : "Phản ánh";
        String i18nKey = "activity.report.completed|" + staffName + "|" + reportTitle;

        ActivityHistory activity = ActivityHistory.builder()
                .actor(staff)
                .i18nKey(i18nKey)
                .targetId(report.getId())
                .build();
        activityHistoryRepository.save(activity);

        // Notify Admins via WebSocket only (per requirement: no notification record or
        // FCM push, only realtime event for dashboard refresh)
        try {
            List<User> admins = userRepository.findByRole(ERole.admin);
            String actionData = String.format(
                    "{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"%s\", \"title\": \"%s\", \"status\": \"processed\", \"severity\": \"%s\"}}",
                    report.getId(),
                    report.getTitle() != null ? report.getTitle().replace("\"", "\\\"") : "",
                    report.getSeverity() != null ? report.getSeverity().name() : "low");

            for (User a : admins) {
                try {
                    NotificationEvent event = new NotificationEvent(
                            "Phản ánh hoàn tất",
                            String.format("Nhân viên %s đã xử lý xong phản ánh '%s'.", staffName, report.getTitle()),
                            actionData,
                            report.getImageUrl(),
                            Map.of("shouldRefresh", true, "status", "processed", "reportId", report.getId()));
                    messagingTemplate.convertAndSendToUser(a.getId(), "/queue/notifications", event);
                } catch (Exception ignored) {
                }
            }
        } catch (Exception ignored) {
        }

        // Notify Client (the creator of the report) via In-App Notification, WebSocket
        // & FCM
        if (report.getUser() != null) {
            try {
                User client = report.getUser();
                java.util.Locale clientLocale = new java.util.Locale(
                        client.getLanguage() != null ? client.getLanguage() : "vi");
                String clientTitle = messageSource.getMessage("notification.report.completed.client.title", null,
                        "Phản ánh đã được xử lý", clientLocale);
                String clientMessage = messageSource.getMessage("notification.report.completed.client.message",
                        new Object[] { report.getTitle() },
                        String.format("Phản ánh '%s' của bạn đã hoàn tất việc xử lý.", report.getTitle()),
                        clientLocale);

                String clientActionData = String
                        .format("{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"%s\"}}", report.getId());

                notificationService.createNotification(client.getId(), clientTitle, clientMessage,
                        clientActionData, report.getImageUrl());
                NotificationEvent clientEvent = new NotificationEvent(clientTitle, clientMessage, clientActionData,
                        report.getImageUrl(), Map.of("shouldRefresh", true));
                messagingTemplate.convertAndSendToUser(client.getId(), "/queue/notifications", clientEvent);

                NotificationRequest clientNotif = new NotificationRequest(
                        clientTitle, clientMessage,
                        Map.of("type", "REPORT_DETAIL", "payload", "{\"reportId\":\"" + report.getId() + "\"}"));
                fcmService.sendToUser(report.getUser().getId(), clientNotif);
            } catch (Exception ignored) {
            }
        }

        // Notify Staff via In-App Notification, WebSocket & FCM
        if (staff != null) {
            try {
                java.util.Locale staffLocale = new java.util.Locale(
                        staff.getLanguage() != null ? staff.getLanguage() : "vi");
                String staffTitle = messageSource.getMessage("notification.report.completed.staff.title", null,
                        "Công việc hoàn tất", staffLocale);
                String staffMessage = messageSource.getMessage("notification.report.completed.staff.message",
                        new Object[] { report.getTitle() },
                        String.format("Cảm ơn bạn đã hoàn tất việc xử lý '%s'.", report.getTitle()), staffLocale);

                String staffActionData = String
                        .format("{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"%s\"}}", report.getId());

                notificationService.createNotification(staff.getId(), staffTitle, staffMessage,
                        staffActionData, report.getImageUrl());

                Map<String, Object> staffExtra = new java.util.HashMap<>();
                staffExtra.put("shouldRefresh", true);
                staffExtra.put("stats", getStaffReportStatistics(staff.getId()));
                NotificationEvent staffEvent = new NotificationEvent(staffTitle, staffMessage, staffActionData,
                        report.getImageUrl(), staffExtra);
                messagingTemplate.convertAndSendToUser(staff.getId(), "/queue/notifications", staffEvent);

                NotificationRequest staffNotif = new NotificationRequest(
                        staffTitle, staffMessage,
                        Map.of("type", "REPORT_DETAIL", "payload", "{\"reportId\":\"" + report.getId() + "\"}"));
                fcmService.sendToUser(staff.getId(), staffNotif);
            } catch (Exception ex) {
                log.warn("[Notify Staff] Failed to notify staff {}: {}", staff.getId(), ex.getMessage());
            }
        }

        return getReportDetail(report.getId());
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReportResponse> getMyReports(String userId, String status, int limit) {
        int safeLimit = Math.max(1, Math.min(limit, 100));
        EReportStatus reportStatus = null;

        if (status != null && !status.trim().isEmpty()) {
            try {
                reportStatus = EReportStatus.valueOf(status.toLowerCase());
            } catch (IllegalArgumentException e) {
                log.warn("[MyReports] Invalid status filter: {}", status);
            }
        }

        List<Report> reports;
        if ("rehandling".equalsIgnoreCase(status)) {
            reports = reportRepository.findByUserIdAndIsReviewResolvedFalseOrderByCreatedAtDesc(userId,
                    Limit.of(safeLimit));
        } else if (reportStatus == null) {
            reports = reportRepository.findByUserIdOrderByCreatedAtDesc(userId, Limit.of(safeLimit));
        } else {
            reports = reportRepository.findByUserIdAndStatusOrderByCreatedAtDesc(userId, reportStatus,
                    Limit.of(safeLimit));
        }
        return reports.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public ReportStatisticsResponse getReportStatistics() {
        // Count by status
        List<Object[]> statusRows = reportRepository.countGroupByStatus();
        Map<String, Integer> byStatus = new LinkedHashMap<>();
        // Initialize with 0 for all statuses
        byStatus.put("pending", 0);
        byStatus.put("processing", 0);
        byStatus.put("resolved", 0);
        byStatus.put("rejected", 0);
        for (Object[] row : statusRows) {
            String key = row[0] != null ? row[0].toString().toLowerCase() : "unknown";
            // Map "processed" -> "resolved" to match frontend expectation
            if ("processed".equals(key))
                key = "resolved";
            int count = row[1] != null ? ((Number) row[1]).intValue() : 0;
            byStatus.put(key, count);
        }
        int total = byStatus.values().stream().mapToInt(Integer::intValue).sum();

        // Count by severity
        List<Object[]> severityRows = reportRepository.countGroupBySeverity();
        Map<String, Integer> bySeverity = new LinkedHashMap<>();
        for (Object[] row : severityRows) {
            String key = row[0] != null ? row[0].toString().toLowerCase() : "unknown";
            int count = row[1] != null ? ((Number) row[1]).intValue() : 0;
            bySeverity.put(key, count);
        }

        return ReportStatisticsResponse.builder()
                .total(total)
                .byStatus(byStatus)
                .bySeverity(bySeverity)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public ReportTrendResponse getReportTrend(String period) {
        List<Object[]> rows;
        if ("weekly".equalsIgnoreCase(period)) {
            rows = reportRepository.countWeeklyTrend();
        } else if ("monthly".equalsIgnoreCase(period)) {
            rows = reportRepository.countMonthlyTrend();
        } else {
            // default: daily
            rows = reportRepository.countDailyTrend();
        }

        List<ReportTrendResponse.TrendItem> items = rows.stream()
                .map(row -> ReportTrendResponse.TrendItem.builder()
                        .label(row[0] != null ? row[0].toString() : "")
                        .count(row[1] != null ? ((Number) row[1]).intValue() : 0)
                        .build())
                .collect(Collectors.toList());

        return ReportTrendResponse.builder().items(items).build();
    }

    @Override
    @Transactional(readOnly = true)
    public ReportListResponse getAdminReportList(int page, int size, String status, String severity, String assigneeId,
            String from, String to, String search) {

        // 1. Parse enums (null = no filter)
        EReportStatus statusEnum = null;
        if (status != null && !status.trim().isEmpty() && !"all".equalsIgnoreCase(status)) {
            try {
                statusEnum = EReportStatus.valueOf(status.toLowerCase());
            } catch (Exception ignored) {
            }
        }
        EReportSeverity severityEnum = null;
        if (severity != null && !severity.trim().isEmpty() && !"all".equalsIgnoreCase(severity)) {
            try {
                severityEnum = EReportSeverity.valueOf(severity.toLowerCase());
            } catch (Exception ignored) {
            }
        }

        // 2. Parse dates
        LocalDateTime fromDt = null;
        LocalDateTime toDt = null;
        try {
            if (from != null && !from.trim().isEmpty())
                fromDt = LocalDate.parse(from.trim()).atStartOfDay();
            if (to != null && !to.trim().isEmpty())
                toDt = LocalDate.parse(to.trim()).atTime(23, 59, 59);
        } catch (Exception e) {
            log.warn("[ReportList] Invalid date filter from={} to={}", from, to);
        }

        // 3. Normalize search + assigneeId
        String searchParam = (search != null && !search.trim().isEmpty()) ? search.trim() : null;
        String assigneeParam = (assigneeId != null && !assigneeId.trim().isEmpty()) ? assigneeId.trim() : null;

        // 4. Query
        int safePage = Math.max(1, page);
        int safeSize = Math.max(1, Math.min(size, 100));
        PageRequest pageable = PageRequest.of(safePage - 1, safeSize);
        Page<Report> reportPage = reportRepository.findAllFiltered(
                statusEnum, severityEnum, assigneeParam, fromDt, toDt, searchParam, pageable);

        // 5. Map Report -> RecentReportResponse (bổ sung userName, userEmail)
        List<RecentReportResponse> content = reportPage.getContent().stream().map(r -> {
            User staff = r.getAssignedStaff();
            User user = r.getUser();
            boolean anon = Boolean.TRUE.equals(r.getIsAnonymous());
            return RecentReportResponse.builder()
                    .id(r.getId())
                    .title(r.getTitle())
                    .status(r.getStatus())
                    .severity(r.getSeverity())
                    .createdAt(r.getCreatedAt())
                    .imageUrl(r.getImageUrl())
                    .address(r.getAddress() != null && !r.getAddress().trim().isEmpty()
                            ? r.getAddress()
                            : r.getLocationDescription())
                    .assignedStaffName(staff != null ? staff.getFullName() : null)
                    .assignedStaffAvatarUrl(staff != null ? staff.getAvatarUrl() : null)
                    .latitude(r.getLatitude())
                    .longitude(r.getLongitude())
                    .isAnonymous(anon)
                    .userName(user != null ? user.getFullName() : null)
                    .userEmail(user != null ? user.getEmail() : null)
                    .isReviewResolved(r.getIsReviewResolved())
                    .build();
        }).collect(Collectors.toList());

        // 6. Wrap in PageResponse
        PageResponse<RecentReportResponse> pageResp = PageResponse.<RecentReportResponse>builder()
                .currentPage(safePage)
                .pageSize(safeSize)
                .totalPages(reportPage.getTotalPages())
                .totalElements(reportPage.getTotalElements())
                .content(content)
                .build();

        return ReportListResponse.builder().reports(pageResp).build();
    }

    @Override
    @Transactional
    public ReportDetailResponse updateReportStatus(String reportId, String newStatus, String adminId) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("report.not_found"));
        EReportStatus current = report.getStatus();
        EReportStatus next = EReportStatus.valueOf(newStatus.toLowerCase());
        // Validate flow: pending -> processing -> processed, rejected from
        // pending/processing, and processed -> processing (re-open)
        boolean valid = switch (current) {
            case pending -> next == EReportStatus.processing || next == EReportStatus.rejected;
            case processing -> next == EReportStatus.processed || next == EReportStatus.rejected;
            case processed -> next == EReportStatus.processing;
            default -> false;
        };
        if (!valid)
            throw new BadRequestException("report.invalid.status.transition");
        report.setStatus(next);
        if (next == EReportStatus.processed) {
            report.setIsReviewResolved(null);
            report.setRating(null);
            report.setReviewNote(null);
            report.setReviewImageUrls(null);
            report.setReviewedAt(null);
        }
        Report saved = reportRepository.save(report);

        if (next == EReportStatus.processed) {
            try {
                staffWalletService.processReportCompletedCommission(saved);
            } catch (Exception ex) {
                log.error("[Staff Wallet] Error processing commission for report {}: {}", saved.getId(), ex.getMessage());
            }
        }

        // When admin re-opens from processed back to processing, notify assigned Staff
        if (current == EReportStatus.processed && next == EReportStatus.processing) {
            try {
                staffWalletService.processReportReopenPenalty(saved);
            } catch (Exception ex) {
                log.error("[Staff Wallet] Error processing penalty for report {}: {}", saved.getId(), ex.getMessage());
            }
            User staff = saved.getAssignedStaff();
            if (staff != null) {
                try {
                    java.util.Locale staffLocale = new java.util.Locale(
                            staff.getLanguage() != null ? staff.getLanguage() : "vi");
                    String title = messageSource.getMessage(
                            "notification.report.reopened.staff.title",
                            null,
                            "Yêu cầu xử lý lại phản ánh",
                            staffLocale);
                    String message = messageSource.getMessage(
                            "notification.report.reopened.staff.message",
                            new Object[] { saved.getTitle() },
                            String.format(
                                    "Phản ánh '%s' được đánh giá là chưa được xử lý thỏa đáng và cần được xử lý lại.",
                                    saved.getTitle()),
                            staffLocale);
                    String actionData = String.format(
                            "{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"%s\"}}", saved.getId());

                    notificationService.createNotification(staff.getId(), title, message, actionData,
                            saved.getImageUrl());

                    Map<String, Object> staffExtra = new java.util.HashMap<>();
                    staffExtra.put("shouldRefresh", true);
                    staffExtra.put("stats", getStaffReportStatistics(staff.getId()));
                    NotificationEvent staffEvent = new NotificationEvent(title, message, actionData,
                            saved.getImageUrl(), staffExtra);
                    messagingTemplate.convertAndSendToUser(staff.getId(), "/queue/notifications", staffEvent);

                    NotificationRequest staffNotif = new NotificationRequest(
                            title, message,
                            Map.of("type", "REPORT_DETAIL", "payload", "{\"reportId\":\"" + saved.getId() + "\"}"));
                    fcmService.sendToUser(staff.getId(), staffNotif);
                } catch (Exception ex) {
                    log.warn("[Notify Staff] Failed to notify staff {} on reopen: {}", staff.getId(), ex.getMessage());
                }
            }
        }

        return toDetail(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public AdminMapReportsResponse getAdminMapReports(String status, String severity, String assigneeId,
            String from, String to, Double minLat, Double maxLat, Double minLng, Double maxLng, int limit) {
        // Bounds are optional, but all-or-nothing
        boolean anyBound = minLat != null || maxLat != null || minLng != null || maxLng != null;
        if (anyBound) {
            validateMapBounds(minLat, maxLat, minLng, maxLng);
        }

        // Parse enums
        EReportStatus statusEnum = null;
        if (status != null && !status.trim().isEmpty() && !"all".equalsIgnoreCase(status)) {
            try {
                statusEnum = EReportStatus.valueOf(status.toLowerCase());
            } catch (Exception ignored) {
            }
        }
        EReportSeverity severityEnum = null;
        if (severity != null && !severity.trim().isEmpty() && !"all".equalsIgnoreCase(severity)) {
            try {
                severityEnum = EReportSeverity.valueOf(severity.toLowerCase());
            } catch (Exception ignored) {
            }
        }

        // Parse dates
        LocalDateTime fromDt = null;
        LocalDateTime toDt = null;
        try {
            if (from != null && !from.trim().isEmpty())
                fromDt = LocalDate.parse(from.trim()).atStartOfDay();
            if (to != null && !to.trim().isEmpty())
                toDt = LocalDate.parse(to.trim()).atTime(23, 59, 59);
        } catch (Exception e) {
            log.warn("[MapReports] Invalid date filter from={} to={}", from, to);
        }

        String assigneeParam = (assigneeId != null && !assigneeId.trim().isEmpty()) ? assigneeId.trim() : null;
        int safeLimit = safeMapLimit(limit, MAP_MAX_LIMIT);

        // Fetch one extra row to know whether more reports match than safeLimit
        List<Report> reports = reportRepository.findAdminMapReports(
                statusEnum, severityEnum, assigneeParam, fromDt, toDt,
                minLat, maxLat, minLng, maxLng,
                Limit.of(safeLimit + 1));

        List<MapReportResponse> content = reports.stream()
                .limit(safeLimit)
                .map(r -> MapReportResponse.builder()
                        .id(r.getId())
                        .title(r.getTitle())
                        .status(r.getStatus())
                        .severity(r.getSeverity())
                        .latitude(r.getLatitude())
                        .longitude(r.getLongitude())
                        .imageUrl(r.getImageUrl())
                        .address(r.getAddress() != null && !r.getAddress().trim().isEmpty()
                                ? r.getAddress()
                                : r.getLocationDescription())
                        .createdAt(r.getCreatedAt())
                        .build())
                .collect(Collectors.toList());

        return AdminMapReportsResponse.builder()
                .reports(content)
                .truncated(reports.size() > safeLimit)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<RecentReportResponse> getStaffAssignedReports(String staffId, String status, int page, int limit) {
        int safeLimit = Math.max(1, Math.min(limit, 100));
        int safePage = Math.max(0, page);

        if ("rehandling".equalsIgnoreCase(status)) {
            org.springframework.data.domain.Pageable pageable = org.springframework.data.domain.PageRequest.of(safePage,
                    safeLimit);
            List<Report> reports = reportRepository.findStaffReportsByStatusAndIsReviewResolved(staffId,
                    EReportStatus.processing, false, pageable);
            return reports.stream().map(r -> {
                User staff = r.getAssignedStaff();
                User user = r.getUser();
                boolean anon = Boolean.TRUE.equals(r.getIsAnonymous());
                return RecentReportResponse.builder()
                        .id(r.getId())
                        .title(r.getTitle())
                        .status(r.getStatus())
                        .severity(r.getSeverity())
                        .createdAt(r.getCreatedAt())
                        .imageUrl(r.getImageUrls() != null && !r.getImageUrls().trim().isEmpty()
                                ? r.getImageUrls().trim().replaceAll("^\\[|\\]$", "").replaceAll("\"", "").split(",")[0]
                                        .trim()
                                : r.getImageUrl())
                        .address(r.getAddress() != null && !r.getAddress().trim().isEmpty() ? r.getAddress()
                                : r.getLocationDescription())
                        .assignedStaffName(staff != null ? staff.getFullName() : null)
                        .assignedStaffAvatarUrl(staff != null ? staff.getAvatarUrl() : null)
                        .latitude(r.getLatitude())
                        .longitude(r.getLongitude())
                        .userName(anon ? null : (user != null ? user.getFullName() : null))
                        .userEmail(anon ? null : (user != null ? user.getEmail() : null))
                        .userAvatarUrl(anon ? null : (user != null ? user.getAvatarUrl() : null))
                        .description(r.getDescription())
                        .isReviewResolved(r.getIsReviewResolved())
                        .build();
            }).collect(Collectors.toList());
        }

        List<EReportStatus> statuses;
        if ("resolved".equalsIgnoreCase(status) || "processed".equalsIgnoreCase(status)) {
            statuses = List.of(EReportStatus.processed);
        } else if ("processing".equalsIgnoreCase(status)) {
            statuses = List.of(EReportStatus.processing);
        } else if ("rejected".equalsIgnoreCase(status)) {
            statuses = List.of(EReportStatus.rejected);
        } else {
            // "all" or invalid or null defaults to processing + processed for staff
            // (pending removed)
            statuses = List.of(EReportStatus.processing, EReportStatus.processed);
        }

        org.springframework.data.domain.Pageable pageable = org.springframework.data.domain.PageRequest.of(safePage,
                safeLimit);
        List<Report> reports = reportRepository.findByAssignedStaffIdAndStatusInOrderByCreatedAtDesc(staffId, statuses,
                pageable);

        return reports.stream().map(r -> {
            User staff = r.getAssignedStaff();
            User user = r.getUser();
            boolean anon = Boolean.TRUE.equals(r.getIsAnonymous());
            return RecentReportResponse.builder()
                    .id(r.getId())
                    .title(r.getTitle())
                    .status(r.getStatus())
                    .severity(r.getSeverity())
                    .createdAt(r.getCreatedAt())
                    .imageUrl(r.getImageUrls() != null && !r.getImageUrls().trim().isEmpty()
                            ? r.getImageUrls().trim().replaceAll("^\\[|\\]$", "").replaceAll("\"", "").split(",")[0]
                                    .trim()
                            : r.getImageUrl())
                    .address(r.getAddress() != null && !r.getAddress().trim().isEmpty() ? r.getAddress()
                            : r.getLocationDescription())
                    .assignedStaffName(staff != null ? staff.getFullName() : null)
                    .assignedStaffAvatarUrl(staff != null ? staff.getAvatarUrl() : null)
                    .latitude(r.getLatitude())
                    .longitude(r.getLongitude())
                    .userName(anon ? null : (user != null ? user.getFullName() : null))
                    .userEmail(anon ? null : (user != null ? user.getEmail() : null))
                    .userAvatarUrl(anon ? null : (user != null ? user.getAvatarUrl() : null))
                    .description(r.getDescription())
                    .isReviewResolved(r.getIsReviewResolved())
                    .build();
        }).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public ReportStatisticsResponse getStaffReportStatistics(String staffId) {
        List<Object[]> statusRows = reportRepository.countStaffReportsGroupByStatus(staffId);
        Map<String, Integer> byStatus = new LinkedHashMap<>();
        byStatus.put("processing", 0);
        byStatus.put("resolved", 0);
        byStatus.put("rehandling", 0);
        for (Object[] row : statusRows) {
            String key = row[0] != null ? row[0].toString().toLowerCase() : "unknown";
            if ("processed".equals(key))
                key = "resolved";
            int count = row[1] != null ? ((Number) row[1]).intValue() : 0;
            if (!"pending".equals(key) && !"rejected".equals(key)) {
                byStatus.put(key, count);
            }
        }
        long rehandlingCount = reportRepository.countStaffReportsByStatusAndIsReviewResolved(staffId,
                EReportStatus.processing, false);
        byStatus.put("rehandling", (int) rehandlingCount);

        int total = byStatus.getOrDefault("processing", 0) + byStatus.getOrDefault("resolved", 0);

        return ReportStatisticsResponse.builder()
                .total(total)
                .byStatus(byStatus)
                .bySeverity(new LinkedHashMap<>())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<RecentReportResponse> getUnsatisfactoryReports(String tab) {
        EReportStatus status = "processing".equalsIgnoreCase(tab)
                ? EReportStatus.processing
                : EReportStatus.processed;
        List<Report> reports = reportRepository.findReportsByStatusAndIsReviewResolved(status, false);
        return reports.stream().map(r -> {
            User staff = r.getAssignedStaff();
            User user = r.getUser();
            boolean anon = Boolean.TRUE.equals(r.getIsAnonymous());
            return RecentReportResponse.builder()
                    .id(r.getId())
                    .title(r.getTitle())
                    .status(r.getStatus())
                    .severity(r.getSeverity())
                    .createdAt(r.getCreatedAt())
                    .imageUrl(r.getImageUrls() != null && !r.getImageUrls().trim().isEmpty()
                            ? r.getImageUrls().trim().replaceAll("^\\[|\\]$", "").replaceAll("\"", "").split(",")[0]
                                    .trim()
                            : r.getImageUrl())
                    .address(r.getAddress() != null && !r.getAddress().trim().isEmpty() ? r.getAddress()
                            : r.getLocationDescription())
                    .assignedStaffName(staff != null ? staff.getFullName() : null)
                    .assignedStaffAvatarUrl(staff != null ? staff.getAvatarUrl() : null)
                    .latitude(r.getLatitude())
                    .longitude(r.getLongitude())
                    .userName(anon ? null : (user != null ? user.getFullName() : null))
                    .userEmail(anon ? null : (user != null ? user.getEmail() : null))
                    .userAvatarUrl(anon ? null : (user != null ? user.getAvatarUrl() : null))
                    .description(r.getDescription())
                    .isReviewResolved(r.getIsReviewResolved())
                    .build();
        }).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public ReportDetailResponse reviewReport(String reportId,
            com.vn.smart_space.dto.request.report.ReportReviewRequest request, String userId) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("report.not_found"));

        if (userId != null && report.getUser() != null && !userId.equals(report.getUser().getId())) {
            throw new UnauthorizedException("report.review.unauthorized");
        }

        if (report.getStatus() != EReportStatus.processed) {
            throw new BadRequestException("report.review.not_processed");
        }

        if (report.getReviewedAt() != null || report.getIsReviewResolved() != null) {
            throw new BadRequestException("report.review.already_reviewed");
        }

        if (request.getIsResolved() == null) {
            throw new BadRequestException("report.review.is_resolved_required");
        }

        if (Boolean.TRUE.equals(request.getIsResolved())) {
            Integer rating = request.getRating();
            if (rating == null || rating < 1 || rating > 5) {
                throw new BadRequestException("report.review.rating_invalid");
            }
            report.setIsReviewResolved(true);
            report.setRating(rating);
            report.setReviewNote(
                    request.getReason() != null && !request.getReason().trim().isEmpty() ? request.getReason().trim()
                            : null);
            report.setReviewImageUrls(null);
        } else {
            if (request.getReason() == null || request.getReason().trim().isEmpty()) {
                throw new BadRequestException("report.review.reason_required");
            }
            if (request.getImageUrls() == null || request.getImageUrls().isEmpty()) {
                throw new BadRequestException("report.review.images_required");
            }
            report.setIsReviewResolved(false);
            report.setRating(null);
            report.setReviewNote(request.getReason().trim());
            report.setReviewImageUrls(String.join(",", request.getImageUrls()));
        }

        report.setReviewedAt(new java.util.Date());
        Report saved = reportRepository.save(report);

        // When client submits unresolved review, notify all Admins via WebSocket + DB
        // notification + FCM
        if (Boolean.FALSE.equals(saved.getIsReviewResolved())) {
            try {
                List<User> admins = userRepository.findByRole(ERole.admin);
                if (admins != null && !admins.isEmpty()) {
                    String adminActionData = String.format(
                            "{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"%s\", \"status\": \"processed\"}}",
                            saved.getId());

                    for (User admin : admins) {
                        try {
                            java.util.Locale adminLocale = new java.util.Locale(
                                    admin.getLanguage() != null ? admin.getLanguage() : "vi");
                            String adminTitle = messageSource.getMessage(
                                    "notification.report.review.unresolved.admin.title",
                                    null,
                                    "Phản ánh chưa được xử lý thỏa đáng",
                                    adminLocale);
                            String adminMessage = messageSource.getMessage(
                                    "notification.report.review.unresolved.admin.message",
                                    new Object[] { saved.getTitle() },
                                    String.format("Phản ánh '%s' được đánh giá là chưa được xử lý thỏa đáng.",
                                            saved.getTitle()),
                                    adminLocale);

                            NotificationEvent adminEvent = new NotificationEvent(adminTitle, adminMessage,
                                    adminActionData, saved.getImageUrl(), Map.of("shouldRefresh", true));
                            NotificationRequest adminNotif = new NotificationRequest(adminTitle, adminMessage,
                                    Map.of("type", "REPORT_DETAIL", "payload",
                                            "{\"reportId\":\"" + saved.getId() + "\"}"));

                            notificationService.createNotification(admin.getId(), adminTitle, adminMessage,
                                    adminActionData, saved.getImageUrl());
                            messagingTemplate.convertAndSendToUser(admin.getId(), "/queue/notifications", adminEvent);
                            fcmService.sendToUser(admin.getId(), adminNotif);
                        } catch (Exception ex) {
                            log.warn("[Notify Admin] Failed to notify admin {} about unresolved review: {}",
                                    admin.getId(), ex.getMessage());
                        }
                    }
                }
            } catch (Exception ex) {
                log.warn("[Notify Admin] Failed to send unresolved review notification: {}", ex.getMessage());
            }
        }

        return toDetail(saved);
    }

    private List<String> extractImageUrls(Report r) {
        if (r.getImageUrls() != null && !r.getImageUrls().trim().isEmpty()) {
            String cleaned = r.getImageUrls().trim().replaceAll("^\\[|\\]$", "");
            if (!cleaned.isEmpty()) {
                return Arrays.stream(cleaned.split(","))
                        .map(s -> s.replace("\"", "").trim())
                        .filter(s -> !s.isEmpty())
                        .collect(Collectors.toList());
            }
        }
        if (r.getImageUrl() != null && !r.getImageUrl().trim().isEmpty()) {
            return List.of(r.getImageUrl().trim());
        }
        return List.of();
    }

    private static class UserNearbyAlertRecord {
        private final Set<String> reportIds;
        private final java.time.Instant lastAlertTime;

        public UserNearbyAlertRecord(Set<String> reportIds, java.time.Instant lastAlertTime) {
            this.reportIds = reportIds;
            this.lastAlertTime = lastAlertTime;
        }

        public Set<String> getReportIds() {
            return reportIds;
        }

        public java.time.Instant getLastAlertTime() {
            return lastAlertTime;
        }
    }

    private final Map<String, UserNearbyAlertRecord> userLastAlertCache = new java.util.concurrent.ConcurrentHashMap<>();

    @Override
    @Transactional
    public ReportNearbyAlertResponse checkNearbyReportsAndAlert(Double lat, Double lng, Double radius, String userId) {
        return checkNearbyReportsAndAlert(lat, lng, radius, userId, true);
    }

    @Override
    @Transactional
    public ReportNearbyAlertResponse checkNearbyReportsAndAlert(Double lat, Double lng, Double radius, String userId, Boolean notify) {
        if (lat == null || lng == null) {
            throw new BadRequestException("report.nearby.coordinates_required");
        }
        double searchRadius = radius != null && radius > 0 ? radius : 200.0;

        List<Report> reports = reportRepository.findNearbyActiveReportsWithinRadius(lat, lng, searchRadius, Limit.of(20));

        if (reports.isEmpty()) {
            return ReportNearbyAlertResponse.builder()
                    .count(0)
                    .nearestDistance(null)
                    .reports(List.of())
                    .build();
        }

        List<NearbyReportItemResponse> items = reports.stream().map(r -> {
            double dist = calculateHaversineDistance(lat, lng, r.getLatitude(), r.getLongitude());
            List<String> imgUrls = extractImageUrls(r);
            String primaryImg = !imgUrls.isEmpty() ? imgUrls.get(0) : r.getImageUrl();
            return NearbyReportItemResponse.builder()
                    .id(r.getId())
                    .title(r.getTitle())
                    .description(r.getDescription())
                    .imageUrls(imgUrls)
                    .imageUrl(primaryImg)
                    .latitude(r.getLatitude())
                    .longitude(r.getLongitude())
                    .status(r.getStatus() != null ? r.getStatus().name() : null)
                    .severity(r.getSeverity() != null ? r.getSeverity().name() : null)
                    .distanceInMeters(dist)
                    .createdAt(r.getCreatedAt() != null ? r.getCreatedAt().format(DateTimeFormatter.ISO_DATE_TIME) : null)
                    .build();
        }).collect(Collectors.toList());

        double nearestDistance = items.get(0).getDistanceInMeters() != null ? items.get(0).getDistanceInMeters() : 0.0;
        int count = items.size();
        String nearestReportId = !items.isEmpty() ? items.get(0).getId() : "";
        Set<String> currentReportIds = items.stream().map(NearbyReportItemResponse::getId).collect(Collectors.toSet());

        // Check deduplication cache (10-minute cooldown for identical report set)
        boolean shouldNotify = (notify == null || notify) && userId != null && !userId.isBlank();
        if (shouldNotify) {
            UserNearbyAlertRecord lastAlert = userLastAlertCache.get(userId);
            if (lastAlert != null && lastAlert.getReportIds().equals(currentReportIds)) {
                long minutesSinceLastAlert = java.time.Duration.between(lastAlert.getLastAlertTime(), java.time.Instant.now()).toMinutes();
                if (minutesSinceLastAlert < 10) {
                    shouldNotify = false;
                }
            }
        }

        // If allowed, trigger notifications (WebSocket & FCM) and DB notification
        if (shouldNotify) {
            userLastAlertCache.put(userId, new UserNearbyAlertRecord(currentReportIds, java.time.Instant.now()));
            try {
                User user = userRepository.findById(userId).orElse(null);
                java.util.Locale userLocale = (user != null && user.getLanguage() != null && !user.getLanguage().isBlank())
                        ? new java.util.Locale(user.getLanguage())
                        : (org.springframework.context.i18n.LocaleContextHolder.getLocale() != null
                                ? org.springframework.context.i18n.LocaleContextHolder.getLocale()
                                : new java.util.Locale("vi"));

                String title = messageSource.getMessage(
                        "notification.report.nearby.title",
                        null,
                        userLocale);

                String message = messageSource.getMessage(
                        "notification.report.nearby.message",
                        new Object[] { count, Math.round(nearestDistance) },
                        userLocale);

                String actionData = String.format(
                        "{\"type\": \"NEARBY_REPORTS_ALERT\", \"payload\": {\"count\": %d, \"nearestDistance\": %.1f, \"reportId\": \"%s\", \"nearestReportId\": \"%s\", \"lat\": %s, \"lng\": %s, \"radius\": %s}}",
                        count, nearestDistance, nearestReportId, nearestReportId,
                        lat != null ? lat.toString() : "null",
                        lng != null ? lng.toString() : "null",
                        radius != null ? radius.toString() : "200.0");

                String firstImage = !items.isEmpty() ? items.get(0).getImageUrl() : null;

                // Create DB Notification
                notificationService.createNotification(userId, title, message, actionData, firstImage);

                // Send WebSocket Event
                NotificationEvent event = new NotificationEvent(title, message, actionData, firstImage,
                        Map.of("type", "NEARBY_REPORTS_ALERT", "count", count, "nearestDistance", nearestDistance, "reportId", nearestReportId));
                messagingTemplate.convertAndSendToUser(userId, "/queue/notifications", event);

                // Send FCM
                Map<String, String> fcmData = Map.of(
                        "type", "NEARBY_REPORTS_ALERT",
                        "payload", actionData);
                NotificationRequest notif = new NotificationRequest(title, message, fcmData);
                fcmService.sendToUser(userId, notif);
            } catch (Exception e) {
                log.warn("[NearbyAlert] Failed to send notification for user {}: {}", userId, e.getMessage());
            }
        }

        return ReportNearbyAlertResponse.builder()
                .count(count)
                .nearestDistance(nearestDistance)
                .reports(items)
                .build();
    }

    @Override
    @Transactional
    public ReportDetailResponse updateReport(String reportId, ReportCreateRequest request, String userId) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("report.not_found"));

        if (userId != null && report.getUser() != null && !userId.equals(report.getUser().getId())) {
            throw new UnauthorizedException("report.unauthorized");
        }

        // Business rule: Only pending reports can be edited
        if (report.getStatus() != EReportStatus.pending) {
            throw new BadRequestException("report.edit.only_pending");
        }

        if (request.getTitle() != null && !request.getTitle().trim().isEmpty()) {
            report.setTitle(request.getTitle().trim());
        }
        if (request.getDescription() != null && !request.getDescription().trim().isEmpty()) {
            report.setDescription(request.getDescription().trim());
        }
        if (request.getLatitude() != null) {
            report.setLatitude(request.getLatitude());
        }
        if (request.getLongitude() != null) {
            report.setLongitude(request.getLongitude());
        }
        if (request.getAddress() != null) {
            report.setAddress(request.getAddress().trim());
        }
        if (request.getLocationDescription() != null) {
            report.setLocationDescription(request.getLocationDescription().trim());
        }
        if (request.getIsAnonymous() != null) {
            report.setIsAnonymous(request.getIsAnonymous());
        }
        if (request.getImageUrls() != null) {
            if (!request.getImageUrls().isEmpty()) {
                report.setImageUrls(String.join(",", request.getImageUrls()));
                report.setImageUrl(request.getImageUrls().get(0));
            } else {
                report.setImageUrls(null);
                report.setImageUrl(null);
            }
        }

        report = reportRepository.save(report);

        if (userId != null && report.getUser() != null) {
            User actor = report.getUser();
            String actorName = (actor.getFullName() != null && !actor.getFullName().trim().isEmpty())
                    ? actor.getFullName().trim()
                    : (actor.getEmail() != null ? actor.getEmail().trim() : "Người dùng");
            String i18nKey = "activity.report.updated|" + actorName;

            ActivityHistory activity = ActivityHistory.builder()
                    .actor(actor)
                    .i18nKey(i18nKey)
                    .targetId(report.getId())
                    .build();
            activityHistoryRepository.save(activity);
        }

        return toDetail(report);
    }

    @Override
    @Transactional
    public ReportDetailResponse cancelReport(String reportId, String userId) {
        Report report = reportRepository.findById(reportId)
                .orElseThrow(() -> new ResourceNotFoundException("report.not_found"));

        if (userId != null && report.getUser() != null && !userId.equals(report.getUser().getId())) {
            throw new UnauthorizedException("report.unauthorized");
        }

        // Business rule: Only pending reports can be cancelled
        if (report.getStatus() != EReportStatus.pending) {
            throw new BadRequestException("report.cancel.only_pending");
        }

        report.setStatus(EReportStatus.rejected);
        report = reportRepository.save(report);

        if (userId != null && report.getUser() != null) {
            User actor = report.getUser();
            String actorName = (actor.getFullName() != null && !actor.getFullName().trim().isEmpty())
                    ? actor.getFullName().trim()
                    : (actor.getEmail() != null ? actor.getEmail().trim() : "Người dùng");
            String i18nKey = "activity.report.cancelled|" + actorName;

            ActivityHistory activity = ActivityHistory.builder()
                    .actor(actor)
                    .i18nKey(i18nKey)
                    .targetId(report.getId())
                    .build();
            activityHistoryRepository.save(activity);
        }

        return toDetail(report);
    }
}
