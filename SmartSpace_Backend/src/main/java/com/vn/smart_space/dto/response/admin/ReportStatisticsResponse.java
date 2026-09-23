package com.vn.smart_space.dto.response.admin;

import lombok.*;
import lombok.experimental.FieldDefaults;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ReportStatisticsResponse {
    int total;
    Map<String, Integer> byStatus;     // {pending: 30, processing: 45, resolved: 60, rejected: 15}
    Map<String, Integer> bySeverity;   // {low: 40, medium: 50, high: 35, critical: 25}
}
