package com.vn.smart_space.controller.admin;

import com.vn.smart_space.dto.response.admin.ActivityHistoryResponse;
import com.vn.smart_space.dto.response.admin.AdminOverviewResponse;
import com.vn.smart_space.dto.response.admin.RecentReportResponse;
import com.vn.smart_space.service.admin.AdminHomeService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Locale;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminHomeController {

    AdminHomeService adminHomeService;

    @GetMapping("/home/overview")
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<AdminOverviewResponse> getOverview() {
        return ResponseEntity.ok(adminHomeService.getOverview());
    }

    @GetMapping("/activities")
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<List<ActivityHistoryResponse>> getRecentActivities(
            @RequestParam(defaultValue = "6") int limit,
            Locale locale) {
        return ResponseEntity.ok(adminHomeService.getRecentActivities(limit, locale));
    }

    @GetMapping("/reports/recent")
    @PreAuthorize("hasAuthority('admin')")
    public ResponseEntity<List<RecentReportResponse>> getRecentReports(
            @RequestParam(defaultValue = "all") String tab,
            @RequestParam(defaultValue = "6") int limit) {
        return ResponseEntity.ok(adminHomeService.getRecentReports(tab, limit));
    }
}
