package com.vn.smart_space.dto.request.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Mở khóa tài khoản người dùng — bắt buộc ghi lý do (lưu vào nhật ký hoạt động). */
public record UnlockUserRequest(
        @NotBlank(message = "{user.unlock.reason.required}")
        @Size(min = 10, max = 500, message = "{user.unlock.reason.length}")
        String reason) {
}
