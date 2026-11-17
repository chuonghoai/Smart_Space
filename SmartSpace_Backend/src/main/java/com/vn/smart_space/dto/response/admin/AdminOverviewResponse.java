package com.vn.smart_space.dto.response.admin;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AdminOverviewResponse {
    long userCount;
    long staffCount;
    long adminCount;
    long issueCount;
    long pendingCount;
    long processingCount; // Không gồm báo cáo xử lý lại
    long rehandlingCount; // = unsatisfactoryProcessedCount + rehandlingProcessingCount
    long unsatisfactoryProcessedCount;
    long rehandlingProcessingCount;
}
