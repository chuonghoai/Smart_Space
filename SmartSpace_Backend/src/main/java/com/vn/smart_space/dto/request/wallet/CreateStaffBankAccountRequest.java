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
public class CreateStaffBankAccountRequest {

    @JsonProperty("bank_code")
    String bankCode;

    @NotBlank(message = "wallet.withdraw.bank_name.required")
    @JsonProperty("bank_name")
    String bankName;

    @NotBlank(message = "wallet.withdraw.account_number.required")
    @JsonProperty("bank_account_number")
    String bankAccountNumber;

    @NotBlank(message = "wallet.withdraw.account_name.required")
    @JsonProperty("bank_account_name")
    String bankAccountName;
}

