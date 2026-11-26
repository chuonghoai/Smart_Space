package com.vn.smart_space.dto.response.notification;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class NotificationResponse {
    String id;
    String title;
    String message;
    String imageUrl;
    Boolean isRead;
    Long createdAt;
    String actionData;
}
