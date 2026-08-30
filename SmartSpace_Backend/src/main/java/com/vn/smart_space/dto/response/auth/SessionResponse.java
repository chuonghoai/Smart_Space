package com.vn.smart_space.dto.response.auth;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class SessionResponse {
    String sessionId;
    String deviceName;
    String platform;
    String ipAddress;
    boolean currentDevice;
    long lastActiveAt;
}
