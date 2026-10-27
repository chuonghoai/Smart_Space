package com.vn.smart_space.controller.report;

import com.vn.smart_space.dto.request.report.ReportCompleteRequest;
import com.vn.smart_space.dto.request.report.ReportCreateRequest;
import com.vn.smart_space.dto.request.report.ReportReviewRequest;
import org.springframework.web.bind.annotation.RequestBody;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.dto.response.report.ReportResponse;
import com.vn.smart_space.service.report.IReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reports")
@RequiredArgsConstructor
public class ReportController {

    private final IReportService reportService;

    @GetMapping("/dangerous")
    public ResponseEntity<ApiResponse> getDangerousReports() {
        List<ReportResponse> reports = reportService.getDangerousReports();
        return ResponseEntity.ok(ApiResponse.success("system.success", reports));
    }

    @GetMapping("/recent")
    public ResponseEntity<ApiResponse> getRecentReports(
            @RequestParam(required = false) String filter,
            @RequestParam(name = "user_lat", required = false) Double userLat,
            @RequestParam(name = "user_long", required = false) Double userLong) {

        List<ReportResponse> reports = reportService.getRecentReports(filter, userLat, userLong);
        return ResponseEntity.ok(ApiResponse.success("system.success", reports));
    }

    @GetMapping("/nearby-alerts")
    public ResponseEntity<ApiResponse> checkNearbyAlerts(
            @RequestParam(name = "lat") Double lat,
            @RequestParam(name = "lng") Double lng,
            @RequestParam(name = "radius", defaultValue = "200") Double radius,
            @RequestParam(name = "notify", required = false, defaultValue = "true") Boolean notify,
            @AuthenticationPrincipal Jwt jwt) {
        String userId = null;
        if (jwt != null && jwt.hasClaim("userId")) {
            userId = jwt.getClaim("userId").toString();
        }
        com.vn.smart_space.dto.response.report.ReportNearbyAlertResponse response = 
                reportService.checkNearbyReportsAndAlert(lat, lng, radius, userId, notify);
        return ResponseEntity.ok(ApiResponse.success("system.success", response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse> createReport(
            @org.springframework.security.core.annotation.AuthenticationPrincipal org.springframework.security.oauth2.jwt.Jwt jwt,
            @RequestBody ReportCreateRequest request) {
        String userId = null;
        if (jwt != null && jwt.hasClaim("userId")) {
            userId = jwt.getClaim("userId").toString();
        }
        ReportDetailResponse response = reportService.createReport(request, userId);
        return ResponseEntity.ok(ApiResponse.success("report.create.success", response));
    }

    @GetMapping("/feed")
    public ResponseEntity<ApiResponse> getFeed(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(name = "user_lat", required = false) Double userLat,
            @RequestParam(name = "user_long", required = false) Double userLong) {
        return ResponseEntity.ok(ApiResponse.success("system.success",
                reportService.getFeed(status, page, size, userLat, userLong)));
    }

    @GetMapping("/map")
    public ResponseEntity<ApiResponse> getMapReports(
            @RequestParam(name = "min_lat") Double minLat,
            @RequestParam(name = "max_lat") Double maxLat,
            @RequestParam(name = "min_lng") Double minLng,
            @RequestParam(name = "max_lng") Double maxLng,
            @RequestParam(defaultValue = "300") int limit) {
        return ResponseEntity.ok(ApiResponse.success("system.success",
                reportService.getReportsInBounds(minLat, maxLat, minLng, maxLng, limit)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse> getReportDetail(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String id) {
        String viewerId = jwt != null && jwt.hasClaim("userId") ? jwt.getClaim("userId").toString() : null;
        String scope = jwt != null && jwt.hasClaim("scope") ? jwt.getClaim("scope").toString() : null;
        ReportDetailResponse report = reportService.getReportDetail(id, viewerId, scope);
        return ResponseEntity.ok(ApiResponse.success("system.success", report));
    }

    @GetMapping("/my-reports")
    public ResponseEntity<ApiResponse> getMyReports(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "50") int limit) {
        String userId = jwt.getClaim("userId").toString();
        List<ReportResponse> reports = reportService.getMyReports(userId, status, limit);
        return ResponseEntity.ok(ApiResponse.success("system.success", reports));
    }

    @GetMapping("/staff/assigned")
    public ResponseEntity<ApiResponse> getStaffAssignedReports(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(defaultValue = "all") String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int limit) {
        String staffId = jwt.getClaim("userId").toString();
        return ResponseEntity.ok(ApiResponse.success("system.success", 
                reportService.getStaffAssignedReports(staffId, status, page, limit)));
    }

    @GetMapping("/staff/statistics")
    public ResponseEntity<ApiResponse> getStaffReportStatistics(
            @AuthenticationPrincipal Jwt jwt) {
        String staffId = jwt.getClaim("userId").toString();
        return ResponseEntity.ok(ApiResponse.success("system.success", 
                reportService.getStaffReportStatistics(staffId)));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<ApiResponse> completeReport(
            @PathVariable String id,
            @RequestBody ReportCompleteRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String staffId = jwt != null && jwt.hasClaim("userId") ? jwt.getClaim("userId").toString() : null;
        return ResponseEntity.ok(ApiResponse.success("report.complete.success",
                reportService.completeReport(id, request, staffId)));
    }

    @PostMapping("/{id}/review")
    public ResponseEntity<ApiResponse> reviewReport(
            @PathVariable String id,
            @RequestBody ReportReviewRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String userId = jwt != null && jwt.hasClaim("userId") ? jwt.getClaim("userId").toString() : null;
        return ResponseEntity.ok(ApiResponse.success("report.review.success",
                reportService.reviewReport(id, request, userId)));
    }
}
