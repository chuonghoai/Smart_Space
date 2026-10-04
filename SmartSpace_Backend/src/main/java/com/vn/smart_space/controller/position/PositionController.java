package com.vn.smart_space.controller.position;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.admin.PositionRequest;
import com.vn.smart_space.service.position.IPositionService;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/admin/positions")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class PositionController {

    IPositionService positionService;

    @PreAuthorize("hasRole('admin')")
    @GetMapping
    public ResponseEntity<ApiResponse> getPositions(
            @RequestParam(defaultValue = "false") boolean activeOnly) {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", positionService.getPositions(activeOnly)));
    }

    @PreAuthorize("hasRole('admin')")
    @PostMapping
    public ResponseEntity<ApiResponse> createPosition(
            @RequestBody @Valid PositionRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("position.create.success",
                        positionService.createPosition(request, adminId)));
    }

    @PreAuthorize("hasRole('admin')")
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse> updatePosition(
            @PathVariable String id,
            @RequestBody @Valid PositionRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("position.update.success",
                        positionService.updatePosition(id, request, adminId)));
    }

    @PreAuthorize("hasRole('admin')")
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse> deletePosition(
            @PathVariable String id,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        positionService.deletePosition(id, adminId);
        return ResponseEntity.ok(ApiResponse.success("position.delete.success", null));
    }
}
