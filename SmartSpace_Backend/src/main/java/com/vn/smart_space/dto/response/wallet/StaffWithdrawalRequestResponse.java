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
public class StaffWithdrawalRequestResponse {
    String id;

    @JsonProperty("user_id")
    String userId;

    @JsonProperty("staff_name")
    String staffName;

    @JsonProperty("staff_email")
    String staffEmail;

    @JsonProperty("staff_phone")
    String staffPhone;

    @JsonProperty("staff_avatar")
    String staffAvatar;

    Double amount;

    @JsonProperty("bank_code")
    String bankCode;

    @JsonProperty("bank_name")
    String bankName;

    @JsonProperty("bank_account_number")
    String bankAccountNumber;

    @JsonProperty("bank_account_name")
    String bankAccountName;

    @JsonProperty("qr_code_url")
    String qrCodeUrl;

    String status;

    String note;

    @JsonProperty("admin_note")
    String adminNote;

    @JsonProperty("created_at")
    LocalDateTime createdAt;

    @JsonProperty("processed_at")
    LocalDateTime processedAt;
}

