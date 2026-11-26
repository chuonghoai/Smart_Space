package com.vn.smart_space.dto.request.admin;

import java.util.List;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Đề xuất khóa tài khoản người dùng. Cần ít nhất một bằng chứng (ảnh và/hoặc
 * phản ánh)
 */
public record CreateAccountLockRequest(
                @NotBlank(message = "{lock_request.target.required}") String targetUserId,

                @NotBlank(message = "{lock_request.reason.required}") @Size(min = 20, max = 2000, message = "{lock_request.reason.length}") String reason,

                @Size(max = 5, message = "{lock_request.evidence.too_many_images}") List<String> evidenceImageUrls,

                @Size(max = 10, message = "{lock_request.evidence.too_many_reports}") List<String> reportIds) {
}
