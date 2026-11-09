package com.vn.smart_space.dto.response.report;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/**
 * Số liệu thẻ tổng hợp "Phản ánh của tôi" (Client), đếm trên toàn bộ phản ánh của người dùng.
 * rehandling = số phản ánh người dùng đánh giá chưa được giải quyết (is_review_resolved = false).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class MyReportsSummaryResponse {
    long total;
    long pending;
    long processing;
    long processed;
    long rejected;
    long rehandling;
}
