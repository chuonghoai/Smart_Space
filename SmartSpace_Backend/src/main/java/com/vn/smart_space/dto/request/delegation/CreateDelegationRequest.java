package com.vn.smart_space.dto.request.delegation;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class CreateDelegationRequest {

    @NotBlank(message = "delegation.report_id.required")
    @JsonProperty("report_id")
    String reportId;

    @NotBlank(message = "delegation.helper_id.required")
    @JsonProperty("helper_id")
    String helperId;

    @Size(max = 500, message = "delegation.note.too_long")
    String note;
}
