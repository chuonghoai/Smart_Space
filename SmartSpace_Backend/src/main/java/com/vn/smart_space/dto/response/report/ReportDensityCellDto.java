package com.vn.smart_space.dto.response.report;

import java.util.List;

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
public class ReportDensityCellDto {
    String cellId;
    int count;
    String level;
    String color;
    Double latitude;
    Double longitude;
    List<List<Double>> coordinates;
}

