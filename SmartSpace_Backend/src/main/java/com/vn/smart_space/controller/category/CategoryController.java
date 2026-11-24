package com.vn.smart_space.controller.category;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.service.category.IReportCategoryService;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/categories")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class CategoryController {

    IReportCategoryService categoryService;

    @GetMapping
    public ResponseEntity<ApiResponse> getActiveCategories() {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", categoryService.getCategories(true)));
    }
}
