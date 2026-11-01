package com.vn.smart_space.dto.response.delegation;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import lombok.experimental.FieldDefaults;

/** Đồng nghiệp để chọn khi nhờ làm giùm — chỉ thông tin hiển thị, không lộ email/SĐT. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class StaffColleagueResponse {

    String id;

    @JsonProperty("full_name")
    String fullName;

    @JsonProperty("avatar_url")
    String avatarUrl;

    @JsonProperty("position_name")
    String positionName;
}
