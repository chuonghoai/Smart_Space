package com.vn.smart_space.dto.request.wallet;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import lombok.experimental.FieldDefaults;

/** Tỷ lệ bonus nhờ làm giùm (%) theo mức độ, mỗi giá trị trong [0, 100]. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class DelegationRateConfigUpdateRequest {

    @NotNull(message = "delegation.rate.required")
    @DecimalMin(value = "0.0", message = "delegation.rate.range")
    @DecimalMax(value = "100.0", message = "delegation.rate.range")
    @JsonProperty("rate_low")
    Double rateLow;

    @NotNull(message = "delegation.rate.required")
    @DecimalMin(value = "0.0", message = "delegation.rate.range")
    @DecimalMax(value = "100.0", message = "delegation.rate.range")
    @JsonProperty("rate_medium")
    Double rateMedium;

    @NotNull(message = "delegation.rate.required")
    @DecimalMin(value = "0.0", message = "delegation.rate.range")
    @DecimalMax(value = "100.0", message = "delegation.rate.range")
    @JsonProperty("rate_high")
    Double rateHigh;

    @NotNull(message = "delegation.rate.required")
    @DecimalMin(value = "0.0", message = "delegation.rate.range")
    @DecimalMax(value = "100.0", message = "delegation.rate.range")
    @JsonProperty("rate_critical")
    Double rateCritical;
}
