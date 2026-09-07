package com.vn.smart_space.dto.request.auth;

import com.vn.smart_space.consts.ERole;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class GoogleLoginRequest {
    @NotBlank(message = "{auth.idToken.required}")
    String idToken;

    @NotBlank(message = "{auth.deviceId.required}")
    String deviceId;
    
    String deviceName;
    String platform;
    String ipAddress;

    @NotNull(message = "{auth.role.required}")
    ERole role;

    String language;
}
