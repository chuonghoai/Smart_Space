package com.vn.smart_space.controller.staff;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.admin.CreateStaffRequest;
import com.vn.smart_space.dto.request.admin.UpdateStaffRequest;
import com.vn.smart_space.dto.request.admin.UpdateStaffStatusRequest;
import com.vn.smart_space.service.staff.IStaffService;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/admin/staffs")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class StaffController {

        IStaffService staffService;

        @PreAuthorize("hasRole('admin')")
        @GetMapping
        public ResponseEntity<ApiResponse> getStaffs(
                        @RequestParam(defaultValue = "1") int page,
                        @RequestParam(defaultValue = "10") int size,
                        @RequestParam(required = false) String search,
                        @RequestParam(required = false) String status) {

                return ResponseEntity.ok(
                                ApiResponse.success("system.success",
                                                staffService.getStaffsPaged(page, size, search, status)));
        }

        @PreAuthorize("hasRole('admin')")
        @PutMapping("/{id}/status")
        public ResponseEntity<ApiResponse> updateStaffStatus(@PathVariable String id,
                        @RequestBody UpdateStaffStatusRequest request,
                        @AuthenticationPrincipal Jwt jwt) {
                String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
                staffService.updateStaffStatus(id, request, adminId);
                return ResponseEntity.ok(
                                ApiResponse.success("system.success", null));
        }

        @PreAuthorize("hasRole('admin')")
        @PostMapping
        public ResponseEntity<ApiResponse> createStaff(
                        @RequestBody @Valid CreateStaffRequest request,
                        @AuthenticationPrincipal Jwt jwt) {
                String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
                return ResponseEntity.ok(
                                ApiResponse.success("staff.create.success",
                                                staffService.createStaff(request, adminId)));
        }

        @PreAuthorize("hasRole('admin')")
        @PutMapping("/{id}")
        public ResponseEntity<ApiResponse> updateStaff(
                        @PathVariable String id,
                        @RequestBody @Valid UpdateStaffRequest request,
                        @AuthenticationPrincipal Jwt jwt) {
                String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
                return ResponseEntity.ok(
                                ApiResponse.success("staff.update.success",
                                                staffService.updateStaff(id, request, adminId)));
        }

        @PreAuthorize("hasRole('admin')")
        @GetMapping("/chart-data")
        public ResponseEntity<ApiResponse> getChartData() {
                return ResponseEntity.ok(
                                ApiResponse.success("system.success",
                                                staffService.getChartData()));
        }

}
