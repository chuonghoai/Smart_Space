package com.vn.smart_space.dto.response.admin;

import lombok.*;
import lombok.experimental.FieldDefaults;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ReportTrendResponse {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class TrendItem {
        String label;   // "17/09", "Tuần 38", "Tháng 9"
        int count;
        boolean anomaly;
        Double baselineAvg;
    }

    List<TrendItem> items;
    Double baselineAvg14d;
    int anomalyCount;
    boolean insufficientData;
}
