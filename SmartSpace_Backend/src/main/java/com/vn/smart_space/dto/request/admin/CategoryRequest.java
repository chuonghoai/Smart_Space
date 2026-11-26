package com.vn.smart_space.dto.request.admin;

import java.util.List;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CategoryRequest(
        @NotBlank(message = "{category.code.required}") @Size(max = 50) String code,
        @NotBlank(message = "{category.name_vi.required}") @Size(max = 120) String nameVi,
        @NotBlank(message = "{category.name_en.required}") @Size(max = 120) String nameEn,
        String description,
        @Size(max = 50) String iconKey,
        String defaultSeverity,
        Boolean isActive,
        Integer displayOrder,
        List<String> positionIds) {
}
