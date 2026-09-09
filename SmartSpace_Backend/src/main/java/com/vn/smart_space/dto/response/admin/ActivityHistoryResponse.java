package com.vn.smart_space.dto.response.admin;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ActivityHistoryResponse {
    String id;
    String actorName;
    String actorAvatarUrl;
    String targetId;
    String message; // localized string based on i18n_key
    LocalDateTime createdAt;
}
