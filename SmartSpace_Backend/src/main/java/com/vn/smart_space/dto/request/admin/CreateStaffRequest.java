package com.vn.smart_space.dto.request.admin;

public record CreateStaffRequest(
        String fullName,
        String email,
        String phone,
        String password,
        String dateOfBirth,
        String gender,
        String avatarUrl) {
}
