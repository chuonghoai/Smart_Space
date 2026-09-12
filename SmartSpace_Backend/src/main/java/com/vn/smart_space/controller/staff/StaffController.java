package com.vn.smart_space.controller.staff;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.service.staff.IStaffService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin/staffs")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class StaffController {

    IStaffService staffService;

    @GetMapping
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> getStaffs() {
        return ResponseEntity.ok(ApiResponse.success("system.success", staffService.getStaffs()));
    }
}
