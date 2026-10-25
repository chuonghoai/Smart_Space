package com.vn.smart_space.dto.response.admin;

import java.util.List;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Admin map reports. {@code truncated} = more matching reports exist than {@code limit}. */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AdminMapReportsResponse {
    List<MapReportResponse> reports;
    boolean truncated;
}
