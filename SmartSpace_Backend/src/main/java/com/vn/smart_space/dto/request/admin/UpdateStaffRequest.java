package com.vn.smart_space.dto.request.admin;

public record UpdateStaffRequest(
        String fullName,
        String email,
        String phone,
        String dateOfBirth,
        String gender,
        String avatarUrl) {
}
