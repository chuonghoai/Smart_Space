package com.vn.smart_space.dto.response.emergency;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Thông tin tối thiểu của tài khoản trong quan hệ liên hệ khẩn cấp. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class EmergencyContactUserResponse {

    String id;

    @JsonProperty("full_name")
    String fullName;

    @JsonProperty("avatar_url")
    String avatarUrl;
}
