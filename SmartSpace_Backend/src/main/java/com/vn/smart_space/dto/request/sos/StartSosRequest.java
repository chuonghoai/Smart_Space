package com.vn.smart_space.dto.request.sos;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class StartSosRequest {

    @NotNull(message = "sos.location.required")
    @DecimalMin(value = "-90.0", message = "sos.location.invalid")
    @DecimalMax(value = "90.0", message = "sos.location.invalid")
    Double latitude;

    @NotNull(message = "sos.location.required")
    @DecimalMin(value = "-180.0", message = "sos.location.invalid")
    @DecimalMax(value = "180.0", message = "sos.location.invalid")
    Double longitude;

    @PositiveOrZero(message = "sos.location.invalid")
    Double accuracy;

    @Size(max = 500, message = "sos.message.too_long")
    String message;
}
