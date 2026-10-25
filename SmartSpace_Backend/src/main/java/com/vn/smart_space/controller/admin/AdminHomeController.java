package com.vn.smart_space.controller.admin;

import com.vn.smart_space.dto.ApiResponse;
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

import java.util.Locale;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminHomeController {

    AdminHomeService adminHomeService;

    @GetMapping("/home/overview")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> getOverview() {
        return ResponseEntity.ok(ApiResponse.success("system.success", adminHomeService.getOverview()));
    }

    @GetMapping("/activities")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> getRecentActivities(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(defaultValue = "4") int limit,
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String topic,
            Locale locale) {
        if (page != null) {
            int pageSize = size != null ? size : 10;
            return ResponseEntity.ok(ApiResponse.success("system.success",
                    adminHomeService.getPaginatedActivities(page, pageSize, role, topic, locale)));
        }
        return ResponseEntity.ok(ApiResponse.success("system.success", adminHomeService.getRecentActivities(limit, locale)));
    }
}

