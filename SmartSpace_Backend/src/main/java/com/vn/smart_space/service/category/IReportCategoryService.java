package com.vn.smart_space.service.category;

import java.util.List;

import com.vn.smart_space.dto.request.admin.CategoryRequest;
import com.vn.smart_space.dto.response.category.CategoryResponse;

public interface IReportCategoryService {

    List<CategoryResponse> getCategories(boolean activeOnly);

    CategoryResponse createCategory(CategoryRequest request, String adminId);

    CategoryResponse updateCategory(String id, CategoryRequest request, String adminId);

    void deleteCategory(String id, String adminId);
}
