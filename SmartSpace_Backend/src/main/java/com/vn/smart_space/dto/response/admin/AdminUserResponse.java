package com.vn.smart_space.dto.response.admin;

import java.time.LocalDateTime;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Một dòng trong danh sách người dùng (role = client) của Admin. */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AdminUserResponse {
    String id;
    String fullName;
    String email;
    String phoneNumber;
    String avatarUrl;
    String status; // "active" | "blocked"
    long reportCount; // Không tính báo cáo ẩn danh
    LocalDateTime createdAt;
}
