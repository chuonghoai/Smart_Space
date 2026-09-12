package com.vn.smart_space.service.report;

import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.data.domain.Limit;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.request.admin.ReportAssignRequest;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.request.report.ReportCreateRequest;
import com.vn.smart_space.dto.response.admin.RecentReportResponse;
import com.vn.smart_space.dto.response.notification.NotificationEvent;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.dto.response.report.ReportResponse;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class ReportServiceImpl implements IReportService {

    private final ReportRepository reportRepository;
    private final com.vn.smart_space.repository.UserRepository userRepository;
    private final org.springframework.messaging.simp.SimpMessagingTemplate messagingTemplate;
    private final IFCMService fcmService;
    private final INotificationService notificationService;
    private final com.vn.smart_space.repository.ActivityHistoryRepository activityHistoryRepository;

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
                .createdAt(report.getCreatedAt() != null ? report.getCreatedAt().format(DateTimeFormatter.ISO_DATE_TIME)
                        : null)
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

            com.vn.smart_space.model.ActivityHistory activity = com.vn.smart_space.model.ActivityHistory.builder()
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
                .createdAt(report.getCreatedAt() != null ? report.getCreatedAt().format(DateTimeFormatter.ISO_DATE_TIME) : null)
                .build();
                        
        // Notify Users
        if (userId != null) {
            try {
                String title = "Tạo phản ánh thành công";
                String message = "Phản ánh của bạn đã được ghi nhận và đang chờ xử lý.";
                
                // Standardized actionData: { "type": "...", "payload": { ... } }
                String actionData = "{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"" + report.getId() + "\"}}";
                
                // Create DB Notification
                notificationService.createNotification(userId, title, message, actionData);
                
                // Send WebSocket Event to the user
                NotificationEvent event = 
                    new NotificationEvent(title, message, actionData);
                messagingTemplate.convertAndSendToUser(userId, "/queue/notifications", event);

                // Send FCM
                Map<String, String> fcmData = Map.of(
                    "type", "REPORT_DETAIL",
                    "payload", "{\"reportId\":\"" + report.getId() + "\"}"
                );
                NotificationRequest notif = new NotificationRequest(title, message, fcmData);
                fcmService.sendToUser(userId, notif);
            } catch (Exception e) {
                log.warn("[Notify] Failed to send notification for report {}: {}", report.getId(), e.getMessage());
            }
        }

        // Notify Admins
        try {
            List<User> admins = userRepository.findByRole(com.vn.smart_space.consts.ERole.admin);
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
                    report.getAddress() != null ? report.getAddress().replace("\"", "\\\"") : (report.getLocationDescription() != null ? report.getLocationDescription().replace("\"", "\\\"") : "")
                );

                NotificationEvent adminEvent = new NotificationEvent(adminTitle, adminMessage, adminActionData);
                Map<String, String> adminFcmData = Map.of(
                    "type", "REPORT_DETAIL",
                    "payload", "{\"reportId\":\"" + report.getId() + "\"}"
                );
                NotificationRequest adminNotif = new NotificationRequest(adminTitle, adminMessage, adminFcmData);

                for (User admin : admins) {
                    try {
                        notificationService.createNotification(admin.getId(), adminTitle, adminMessage, adminActionData);
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
                .orElseThrow(() -> new com.vn.smart_space.exception.ResourceNotFoundException("report.not_found"));
        
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
                .createdAt(report.getCreatedAt() != null ? report.getCreatedAt().format(DateTimeFormatter.ISO_DATE_TIME) : null)
                .userName(user != null ? user.getFullName() : null)
                .userPhone(user != null ? user.getPhone() : null)
                .userAvatarUrl(user != null ? user.getAvatarUrl() : null)
                .assignedStaffId(staff != null ? staff.getId() : null)
                .assignedStaffName(staff != null ? staff.getFullName() : null)
                .assignedStaffPhone(staff != null ? staff.getPhone() : null)
                .assignedStaffEmail(staff != null ? staff.getEmail() : null)
                .assignedStaffAvatarUrl(staff != null ? staff.getAvatarUrl() : null)
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
            return RecentReportResponse.builder()
                    .id(r.getId())
                    .title(r.getTitle())
                    .status(r.getStatus())
                    .severity(r.getSeverity())
                    .createdAt(r.getCreatedAt())
                    .imageUrl(r.getImageUrl())
                    .address(r.getAddress() != null && !r.getAddress().trim().isEmpty() ? r.getAddress() : r.getLocationDescription())
                    .assignedStaffName(staff != null ? staff.getFullName() : null)
                    .assignedStaffAvatarUrl(staff != null ? staff.getAvatarUrl() : null)
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
                .orElseThrow(() -> new com.vn.smart_space.exception.ResourceNotFoundException("report.not_found"));

        User staff = userRepository.findById(request.getStaffId())
                .orElseThrow(() -> new com.vn.smart_space.exception.ResourceNotFoundException("staff.not_found"));

        if (request.getSeverity() != null && !request.getSeverity().trim().isEmpty()) {
            try {
                report.setSeverity(EReportSeverity.valueOf(request.getSeverity().toLowerCase()));
            } catch (Exception ignored) {}
        }
        
        report.setAssignedStaff(staff);
        report.setStatus(EReportStatus.processing);
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
            String title = "Phân công phản ánh thành công";
            String message = String.format("Phản ánh '%s' đã được giao cho %s.", report.getTitle(), staff.getFullName());
            String actionData = String.format(
                "{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"%s\", \"title\": \"%s\", \"status\": \"processing\", \"severity\": \"%s\"}}",
                report.getId(),
                report.getTitle() != null ? report.getTitle().replace("\"", "\\\"") : "",
                report.getSeverity() != null ? report.getSeverity().name() : "low"
            );

            NotificationEvent event = new NotificationEvent(title, message, actionData);
            
            for (User a : admins) {
                try {
                    notificationService.createNotification(a.getId(), title, message, actionData);
                    messagingTemplate.convertAndSendToUser(a.getId(), "/queue/notifications", event);
                } catch (Exception ex) {}
            }
        } catch (Exception ignored) {}

        // TODO: Gửi thông báo WebSocket / FCM cho Staff khi module Staff App được triển khai.

        // Notify Client
        if (report.getUser() != null) {
            try {
                String clientTitle = "Phản ánh đang được xử lý";
                String clientMessage = String.format("Phản ánh '%s' của bạn đã được phân công xử lý.", report.getTitle());
                String clientActionData = String.format("{\"type\": \"REPORT_DETAIL\", \"payload\": {\"reportId\": \"%s\"}}", report.getId());
                
                notificationService.createNotification(report.getUser().getId(), clientTitle, clientMessage, clientActionData);
                NotificationEvent clientEvent = new NotificationEvent(clientTitle, clientMessage, clientActionData);
                messagingTemplate.convertAndSendToUser(report.getUser().getId(), "/queue/notifications", clientEvent);
                
                NotificationRequest clientNotif = new NotificationRequest(
                    clientTitle, clientMessage, Map.of("type", "REPORT_DETAIL", "payload", "{\"reportId\":\"" + report.getId() + "\"}")
                );
                fcmService.sendToUser(report.getUser().getId(), clientNotif);
            } catch (Exception ignored) {}
        }

        return getReportDetail(report.getId());
    }
}

