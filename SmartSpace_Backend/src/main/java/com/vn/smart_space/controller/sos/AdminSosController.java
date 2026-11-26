package com.vn.smart_space.controller.sos;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.sos.ResolveSosRequest;
import com.vn.smart_space.service.sos.ISosService;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Ban quản trị theo dõi và xử lý tín hiệu SOS. */
@RestController
@RequestMapping("/admin/sos")
@PreAuthorize("hasRole('admin')")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminSosController {

    ISosService sosService;

    /** status: open | resolved | all */
    @GetMapping
    public ResponseEntity<ApiResponse> list(@RequestParam(defaultValue = "open") String status,
            @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.success("system.success", sosService.list(status, page, size)));
    }

    @GetMapping("/open-count")
    public ResponseEntity<ApiResponse> openCount() {
        return ResponseEntity.ok(ApiResponse.success("system.success", sosService.openCount()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse> detail(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success("system.success", sosService.getDetail(id)));
    }

    @PostMapping("/{id}/acknowledge")
    public ResponseEntity<ApiResponse> acknowledge(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("sos.acknowledged",
                sosService.acknowledge(adminId(jwt), id)));
    }

    @PostMapping("/{id}/resolve")
    public ResponseEntity<ApiResponse> resolve(@PathVariable String id,
            @Valid @RequestBody ResolveSosRequest request, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("sos.resolved",
                sosService.resolve(adminId(jwt), id, request)));
    }

    private static String adminId(Jwt jwt) {
        return jwt.getClaimAsString("userId");
    }
}
