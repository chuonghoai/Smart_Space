package com.vn.smart_space.dto.response.sos;

import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonProperty;

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
public class SosLocationPointResponse {

    Double latitude;

    Double longitude;

    Double accuracy;

    @JsonProperty("recorded_at")
    LocalDateTime recordedAt;
}
