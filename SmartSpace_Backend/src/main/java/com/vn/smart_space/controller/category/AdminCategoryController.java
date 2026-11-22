package com.vn.smart_space.controller.category;

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
import com.vn.smart_space.dto.request.admin.CategoryRequest;
import com.vn.smart_space.service.category.IReportCategoryService;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/admin/categories")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminCategoryController {

    IReportCategoryService categoryService;

    @PreAuthorize("hasRole('admin')")
    @GetMapping
    public ResponseEntity<ApiResponse> getCategories(
            @RequestParam(defaultValue = "false") boolean activeOnly) {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", categoryService.getCategories(activeOnly)));
    }

    @PreAuthorize("hasRole('admin')")
    @PostMapping
    public ResponseEntity<ApiResponse> createCategory(
            @RequestBody @Valid CategoryRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("category.create.success",
                        categoryService.createCategory(request, adminId)));
    }

    @PreAuthorize("hasRole('admin')")
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse> updateCategory(
            @PathVariable String id,
            @RequestBody @Valid CategoryRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("category.update.success",
                        categoryService.updateCategory(id, request, adminId)));
    }

    @PreAuthorize("hasRole('admin')")
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse> deleteCategory(
            @PathVariable String id,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        categoryService.deleteCategory(id, adminId);
        return ResponseEntity.ok(ApiResponse.success("category.delete.success", null));
    }
}
