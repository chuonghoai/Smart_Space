package com.vn.smart_space.dto.response.report;

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
public class ReportDensityStatusResponse {
    String status; // READY, RUNNING, FAILED
    int resolution;
    int totalCells;
    long totalReports;
    String lastCalculatedAt;
    String message;
}

