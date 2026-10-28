package com.vn.smart_space.dto.response.wallet;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class WalletConfigResponse {
    @JsonProperty("commission_low")
    Double commissionLow;

    @JsonProperty("commission_medium")
    Double commissionMedium;

    @JsonProperty("commission_high")
    Double commissionHigh;

    @JsonProperty("commission_critical")
    Double commissionCritical;

    @JsonProperty("penalty_rate_1")
    Double penaltyRate1;

    @JsonProperty("penalty_rate_2")
    Double penaltyRate2;

    @JsonProperty("penalty_rate_3")
    Double penaltyRate3;
}

