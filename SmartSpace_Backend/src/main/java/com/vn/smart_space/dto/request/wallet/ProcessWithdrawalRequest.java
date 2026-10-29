package com.vn.smart_space.dto.request.wallet;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ProcessWithdrawalRequest {

    @NotBlank(message = "wallet.withdraw.status.required")
    String status; // APPROVED or REJECTED

    @JsonProperty("admin_note")
    String adminNote;
}

