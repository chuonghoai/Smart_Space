package com.vn.smart_space.dto.response.emergency;

import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Liên hệ khẩn cấp nhìn từ phía owner. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EmergencyContactResponse {

    String id;

    String name;

    /** Dạng nội địa 0xxxxxxxxx. */
    String phone;

    String relationship;

    /** PENDING | ACCEPTED | REJECTED | REVOKED */
    String status;

    /** APP | SELF_DECLARED */
    @JsonProperty("consent_channel")
    String consentChannel;

    Integer priority;

    @JsonProperty("linked_user")
    EmergencyContactUserResponse linkedUser;

    /** Email tài khoản liên kết do chính owner nhập; dùng để điền sẵn form sửa. */
    @JsonProperty("account_email")
    String accountEmail;

    @JsonProperty("consent_at")
    LocalDateTime consentAt;

    @JsonProperty("created_at")
    LocalDateTime createdAt;
}
