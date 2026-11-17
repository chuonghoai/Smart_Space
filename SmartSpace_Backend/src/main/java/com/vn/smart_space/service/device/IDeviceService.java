package com.vn.smart_space.service.device;

import com.vn.smart_space.dto.request.device.RegisterFcmTokenRequest;

public interface IDeviceService {

    /** @param deviceId claim "deviceId" của access token — gắn FCM token với phiên đăng nhập */
    void registerFcmToken(String userId, String deviceId, RegisterFcmTokenRequest request);

    void clearFcmToken(String fcmToken);
}
