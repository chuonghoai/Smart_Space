package com.vn.smart_space.dto.request.wallet;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class WalletConfigUpdateRequest {
    @NotNull(message = "commission.low.required")
    @DecimalMin(value = "0.0", message = "commission.low.min")
    @JsonProperty("commission_low")
    Double commissionLow;

    @NotNull(message = "commission.medium.required")
    @DecimalMin(value = "0.0", message = "commission.medium.min")
    @JsonProperty("commission_medium")
    Double commissionMedium;

    @NotNull(message = "commission.high.required")
    @DecimalMin(value = "0.0", message = "commission.high.min")
    @JsonProperty("commission_high")
    Double commissionHigh;

    @NotNull(message = "commission.critical.required")
    @DecimalMin(value = "0.0", message = "commission.critical.min")
    @JsonProperty("commission_critical")
    Double commissionCritical;

    @NotNull(message = "penalty.rate1.required")
    @DecimalMin(value = "0.0", message = "penalty.rate1.min")
    @JsonProperty("penalty_rate_1")
    Double penaltyRate1;

    @NotNull(message = "penalty.rate2.required")
    @DecimalMin(value = "0.0", message = "penalty.rate2.min")
    @JsonProperty("penalty_rate_2")
    Double penaltyRate2;

    @NotNull(message = "penalty.rate3.required")
    @DecimalMin(value = "0.0", message = "penalty.rate3.min")
    @JsonProperty("penalty_rate_3")
    Double penaltyRate3;
}

