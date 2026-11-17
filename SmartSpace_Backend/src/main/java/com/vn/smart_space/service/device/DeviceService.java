package com.vn.smart_space.service.device;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;

import com.vn.smart_space.dto.request.device.RegisterFcmTokenRequest;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.model.DeviceToken;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.DeviceTokenRepository;
import com.vn.smart_space.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DeviceService implements IDeviceService {

    private final UserRepository userRepository;
    private final DeviceTokenRepository deviceTokenRepository;

    /**
     * Register FCM Token
     * If Exist - Update lastUserAt
     * If Not Exist - Create New
     */
    @Override
    public void registerFcmToken(String userId, String deviceId, RegisterFcmTokenRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BadRequestException("User not found"));

        DeviceToken deviceToken = deviceTokenRepository.findByUserIdAndFcmToken(userId, request.fcmToken())
                .orElse(DeviceToken.builder()
                        .user(user)
                        .fcmToken(request.fcmToken())
                        .build());
        deviceToken.setPlatform(request.platform());
        deviceToken.setDeviceName(request.deviceName());
        // Cập nhật mỗi lần đăng ký: cùng FCM token có thể được đăng ký lại sau khi đăng nhập
        // lại (deviceId mới) — luôn trỏ về phiên hiện tại để đăng xuất từ xa xoá đúng token.
        if (deviceId != null && !deviceId.isBlank()) {
            deviceToken.setDeviceId(deviceId);
        }
        deviceToken.setLastUsedAt(LocalDateTime.now());
        deviceTokenRepository.save(deviceToken);

    }

    // Delete FCM Token when logout
    @Override
    public void clearFcmToken(String fcmToken) {
        deviceTokenRepository.deleteByFcmToken(fcmToken);

    }

}
