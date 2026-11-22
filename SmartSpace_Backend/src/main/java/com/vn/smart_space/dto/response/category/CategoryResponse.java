package com.vn.smart_space.dto.response.category;

import java.util.List;

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
public class CategoryResponse {

    String id;
    String code;
    String nameVi;
    String nameEn;
    String description;
    String iconKey;
    String defaultSeverity;
    boolean active;
    int displayOrder;
    long reportCount;
    List<PositionSummary> positions;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class PositionSummary {
        String id;
        String code;
        String name;
        boolean active;
    }

}
