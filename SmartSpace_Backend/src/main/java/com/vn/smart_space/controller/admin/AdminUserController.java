package com.vn.smart_space.controller.admin;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.service.admin.IAdminUserService;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/admin/users")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminUserController {

        IAdminUserService adminUserService;

        @PreAuthorize("hasRole('admin')")
        @GetMapping
        public ResponseEntity<ApiResponse> getUsers(
                        @RequestParam(defaultValue = "1") int page,
                        @RequestParam(defaultValue = "10") int size,
                        @RequestParam(required = false) String search,
                        @RequestParam(defaultValue = "newest") String sort) {
                return ResponseEntity.ok(
                                ApiResponse.success("system.success",
                                                adminUserService.getUsersPaged(page, size, search, sort)));
        }

        @PreAuthorize("hasRole('admin')")
        @GetMapping("/statistics")
        public ResponseEntity<ApiResponse> getStatistics() {
                return ResponseEntity.ok(
                                ApiResponse.success("system.success", adminUserService.getStatistics()));
        }

        @PreAuthorize("hasRole('admin')")
        @GetMapping("/trend")
        public ResponseEntity<ApiResponse> getRegistrationTrend(
                        @RequestParam(defaultValue = "daily") String period) {
                return ResponseEntity.ok(
                                ApiResponse.success("system.success",
                                                adminUserService.getRegistrationTrend(period)));
        }

        @PreAuthorize("hasRole('admin')")
        @GetMapping("/{id}")
        public ResponseEntity<ApiResponse> getUserDetail(@PathVariable String id) {
                return ResponseEntity.ok(
                                ApiResponse.success("system.success", adminUserService.getUserDetail(id)));
        }

}
