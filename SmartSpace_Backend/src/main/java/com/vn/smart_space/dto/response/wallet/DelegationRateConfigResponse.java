package com.vn.smart_space.dto.response.wallet;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import lombok.experimental.FieldDefaults;

/** Tỷ lệ bonus nhờ làm giùm (%) kèm hoa hồng hiện tại theo mức độ để Admin xem ví dụ số tiền. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class DelegationRateConfigResponse {

    @JsonProperty("rate_low")
    Double rateLow;

    @JsonProperty("rate_medium")
    Double rateMedium;

    @JsonProperty("rate_high")
    Double rateHigh;

    @JsonProperty("rate_critical")
    Double rateCritical;

    @JsonProperty("commission_low")
    Double commissionLow;

    @JsonProperty("commission_medium")
    Double commissionMedium;

    @JsonProperty("commission_high")
    Double commissionHigh;

    @JsonProperty("commission_critical")
    Double commissionCritical;
}
