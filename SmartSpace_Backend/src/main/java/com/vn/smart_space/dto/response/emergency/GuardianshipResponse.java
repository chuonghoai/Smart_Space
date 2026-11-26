package com.vn.smart_space.dto.response.emergency;

import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Lời mời / quan hệ bảo hộ nhìn từ phía người được thêm vào danh sách. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class GuardianshipResponse {

    String id;

    /** PENDING | ACCEPTED */
    String status;

    String relationship;

    EmergencyContactUserResponse owner;

    /** Số điện thoại của owner (dạng nội địa) để gọi khi có sự cố. */
    @JsonProperty("owner_phone")
    String ownerPhone;

    @JsonProperty("consent_at")
    LocalDateTime consentAt;

    @JsonProperty("created_at")
    LocalDateTime createdAt;
}
