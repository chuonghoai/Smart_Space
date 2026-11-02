package com.vn.smart_space.dto.request.admin;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record CreateStaffRequest(
                @NotBlank(message = "{user.fullName.required}") String fullName,
                @NotBlank(message = "{auth.email.required}") @Email(message = "{auth.email.invalid}") String email,
                String phone,
                String dateOfBirth,
                String gender,
                String avatarUrl,
                String positionId) {
}
