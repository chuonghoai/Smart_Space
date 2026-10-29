package com.vn.smart_space.dto.response.wallet;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class StaffWalletSummaryResponse {
    String id;

    @JsonProperty("user_id")
    String userId;

    @JsonProperty("full_name")
    String fullName;

    String email;

    @JsonProperty("phone_number")
    String phoneNumber;

    @JsonProperty("avatar_url")
    String avatarUrl;

    Double balance;

    @JsonProperty("updated_at")
    LocalDateTime updatedAt;
}

