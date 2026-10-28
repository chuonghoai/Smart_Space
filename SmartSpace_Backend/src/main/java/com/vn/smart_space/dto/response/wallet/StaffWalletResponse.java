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
public class StaffWalletResponse {
    String id;
    Double balance;
    @JsonProperty("user_id")
    String userId;
    @JsonProperty("updated_at")
    LocalDateTime updatedAt;
}

