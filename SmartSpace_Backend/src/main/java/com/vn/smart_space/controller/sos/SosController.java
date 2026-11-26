package com.vn.smart_space.controller.sos;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.sos.SosLocationRequest;
import com.vn.smart_space.dto.request.sos.StartSosRequest;
import com.vn.smart_space.service.sos.ISosService;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

/** SOS phía cư dân: gửi tín hiệu, cập nhật vị trí, báo an toàn, và xem SOS của người mình bảo hộ. */
@RestController
@RequestMapping("/sos")
@PreAuthorize("hasRole('client')")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SosController {

    ISosService sosService;

    @PostMapping
    public ResponseEntity<ApiResponse> start(@Valid @RequestBody StartSosRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("sos.started", sosService.start(userId(jwt), request)));
    }

    @GetMapping("/active")
    public ResponseEntity<ApiResponse> active(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("system.success", sosService.getActive(userId(jwt))));
    }

    @PatchMapping("/{id}/location")
    public ResponseEntity<ApiResponse> updateLocation(@PathVariable String id,
            @Valid @RequestBody SosLocationRequest request, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("system.success",
                sosService.updateLocation(userId(jwt), id, request)));
    }

    @PostMapping("/{id}/safe")
    public ResponseEntity<ApiResponse> markSafe(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("sos.safe", sosService.markSafe(userId(jwt), id)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse> get(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("system.success", sosService.getForViewer(userId(jwt), id)));
    }

    private static String userId(Jwt jwt) {
        return jwt.getClaimAsString("userId");
    }
}
