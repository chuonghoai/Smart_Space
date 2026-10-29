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
public class StaffWalletTransactionResponse {
    String id;
    String type;
    Double amount;
    @JsonProperty("balance_after")
    Double balanceAfter;
    @JsonProperty("report_id")
    String reportId;
    @JsonProperty("report_title")
    String reportTitle;
    @JsonProperty("withdrawal_id")
    String withdrawalId;
    @JsonProperty("title_i18n_key")
    String titleI18nKey;
    @JsonProperty("title_params")
    String titleParams;
    String title;
    @JsonProperty("created_at")
    LocalDateTime createdAt;
}
