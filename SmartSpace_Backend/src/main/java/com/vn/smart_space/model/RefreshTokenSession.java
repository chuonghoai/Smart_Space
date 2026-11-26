package com.vn.smart_space.model;

import java.util.concurrent.TimeUnit;
import org.springframework.data.annotation.Id;
import org.springframework.data.redis.core.RedisHash;
import org.springframework.data.redis.core.TimeToLive;
import org.springframework.data.redis.core.index.Indexed;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
@RedisHash("refresh_token_session")
public class RefreshTokenSession {

    @Id
    String id; // Format: "{userId}:{deviceId}"

    @Indexed
    String userId;

    String deviceId;
    String refreshToken;
    String deviceName;
    String platform;
    String ipAddress;
    long lastActiveAt;

    @TimeToLive(unit = TimeUnit.SECONDS)
    Long ttl;
}
