package com.vn.smart_space.service.jwt;

import com.nimbusds.jwt.SignedJWT;
import com.vn.smart_space.dto.JwtInfo;
import com.vn.smart_space.dto.TokenPayload;
import com.vn.smart_space.model.User;

public interface IJwtService {
    TokenPayload generateAccessToken(User user, String deviceId);

    TokenPayload generateRefreshToken(User user, boolean rememberMe);

    SignedJWT verifyToken(String token);

    /**
     * Chỉ xác thực chữ ký, KHÔNG kiểm tra hạn dùng. Dùng cho logout: token hết hạn
     * vẫn phải xoá được session của thiết bị, nhưng không chấp nhận token giả mạo.
     */
    SignedJWT verifySignature(String token);

    String buildScope(User user);

    JwtInfo parseToken(String token);

    boolean isTokenBlacklisted(String jwtId);

}
