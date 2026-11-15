package com.vn.smart_space.dto.response.admin;

import java.time.LocalDateTime;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AdminAccountResponse {
    String id;
    String fullName;
    String email;
    String phoneNumber;
    String avatarUrl;
    String status; // "active" | "blocked"
    LocalDateTime createdAt;
    /** true nếu đây là tài khoản của admin đang gọi API (để UI đánh dấu "Bạn" và chặn tự khóa). */
    boolean currentUser;
}
