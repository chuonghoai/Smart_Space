package com.vn.smart_space.dto.response.report;

import java.util.List;
import java.util.Map;

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
public class ReportDensityResponse {
    int resolution;
    Double zoom;
    int totalCells;
    boolean truncated;
    List<ReportDensityCellDto> cells;
    Map<String, Object> geojson;
}

