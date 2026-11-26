package com.vn.smart_space.dto.response.sos;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class SosUserResponse {

    String id;

    @JsonProperty("full_name")
    String fullName;

    @JsonProperty("avatar_url")
    String avatarUrl;

    /** Dạng nội địa 0xxxxxxxxx để gọi lại. */
    String phone;
}
