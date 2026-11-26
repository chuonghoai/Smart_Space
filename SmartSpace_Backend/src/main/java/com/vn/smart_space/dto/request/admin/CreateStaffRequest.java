package com.vn.smart_space.dto.request.admin;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateStaffRequest(
        @NotBlank(message = "{user.fullName.required}") String fullName,
        @NotBlank(message = "{auth.email.required}") @Email(message = "{auth.email.invalid}") String email,
        String phone,
        String dateOfBirth,
        String gender,
        String avatarUrl,
        String positionId,
        Double baseLatitude,
        Double baseLongitude,
        @Size(max = 255) String baseAddress) {

    public CreateStaffRequest(
            String fullName,
            String email,
            String phone,
            String dateOfBirth,
            String gender,
            String avatarUrl,
            String positionId) {
        this(fullName, email, phone, dateOfBirth, gender, avatarUrl, positionId, null, null, null);
    }
}
