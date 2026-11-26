package com.vn.smart_space.dto.request.admin;

import jakarta.validation.constraints.Size;

/**
 * Admin chỉ được sửa hồ sơ nhân viên. Email (thông tin đăng nhập) và mật khẩu
 * cố ý KHÔNG có trong request này — các field lạ client gửi kèm sẽ bị bỏ qua.
 */
public record UpdateStaffRequest(
        String fullName,
        String phone,
        String dateOfBirth,
        String gender,
        String avatarUrl,
        String positionId,
        Double baseLatitude,
        Double baseLongitude,
        @Size(max = 255) String baseAddress,
        Boolean clearBaseLocation) {

    public UpdateStaffRequest(
            String fullName,
            String phone,
            String dateOfBirth,
            String gender,
            String avatarUrl,
            String positionId) {
        this(fullName, phone, dateOfBirth, gender, avatarUrl, positionId, null, null, null, null);
    }
}
