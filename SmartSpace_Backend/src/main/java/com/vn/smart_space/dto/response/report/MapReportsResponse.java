package com.vn.smart_space.dto.response.report;

import java.util.List;

import lombok.Builder;
import lombok.Data;

/** Reports inside a map viewport. {@code truncated} = more reports exist than {@code limit}. */
@Data
@Builder
public class MapReportsResponse {
    private List<ReportResponse> reports;
    private boolean truncated;
}
