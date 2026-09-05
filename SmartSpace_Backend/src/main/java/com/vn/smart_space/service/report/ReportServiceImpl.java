package com.vn.smart_space.service.report;

import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.data.domain.Limit;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.request.report.ReportCreateRequest;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.dto.response.report.ReportResponse;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ReportRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ReportServiceImpl implements IReportService {

    private final ReportRepository reportRepository;
    private final org.springframework.messaging.simp.SimpMessagingTemplate messagingTemplate;
    private final com.vn.smart_space.service.notification.IFCMService fcmService;

    @Override
    @Transactional(readOnly = true)
    public List<ReportResponse> getDangerousReports() {
        List<Report> reports = reportRepository.findTopBySeverityInOrderByCreatedAtDesc(
                Arrays.asList(EReportSeverity.HIGH, EReportSeverity.CRITICAL),
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
        report.setSeverity(EReportSeverity.LOW);
        report.setStatus(EReportStatus.PENDING);
        report.setAddress(request.getAddress());
        report.setLocationDescription(request.getLocationDescription());
        report.setIsAnonymous(request.getIsAnonymous() != null ? request.getIsAnonymous() : false);
        
        if (request.getImageUrls() != null && !request.getImageUrls().isEmpty()) {
            report.setImageUrls(String.join(",", request.getImageUrls()));
            report.setImageUrl(request.getImageUrls().get(0));
        }
        
        if (userId != null) {
            User user = new User();
            user.setId(userId);
            report.setUser(user);
        }
        
        report = reportRepository.save(report);
        
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
                
        // Dispatch to WebSocket
        try {
            messagingTemplate.convertAndSend("/topic/reports", response);
        } catch (Exception e) {
            // log
        }
        
        // Notify Admins/Users
        // Since we are creating, notify users or admins. For now, notify the user.
        if (userId != null) {
            try {
                NotificationRequest notif = 
                    new NotificationRequest(
                        "Tạo phản ánh thành công",
                        "Phản ánh của bạn đã được ghi nhận và đang chờ xử lý.",
                        null
                    );
                fcmService.sendToUser(userId, notif);
            } catch (Exception e) {
                // log
            }
        }
        
        return response;
    }
}
