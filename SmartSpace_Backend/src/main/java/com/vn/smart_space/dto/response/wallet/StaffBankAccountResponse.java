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
public class StaffBankAccountResponse {

    String id;

    @JsonProperty("user_id")
    String userId;

    @JsonProperty("bank_code")
    String bankCode;

    @JsonProperty("bank_name")
    String bankName;

    @JsonProperty("bank_account_number")
    String bankAccountNumber;

    @JsonProperty("bank_account_name")
    String bankAccountName;

    @JsonProperty("created_at")
    LocalDateTime createdAt;
}

