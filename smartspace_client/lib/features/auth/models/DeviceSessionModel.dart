import 'package:flutter/material.dart';

class DeviceSessionModel {
  final String sessionId;
  final String deviceName;
  final String platform; // "android" | "ios" | "web"
  final String? ipAddress;
  final bool isCurrentDevice;
  final int lastActiveAt; // epoch millis

  DeviceSessionModel({
    required this.sessionId,
    required this.deviceName,
    required this.platform,
    this.ipAddress,
    required this.isCurrentDevice,
    required this.lastActiveAt,
  });

  factory DeviceSessionModel.fromJson(Map<String, dynamic> json) {
    return DeviceSessionModel(
      sessionId: json['sessionId'] ?? '',
      deviceName: json['deviceName'] ?? 'Unknown',
      platform: json['platform'] ?? 'web',
      ipAddress: json['ipAddress'],
      isCurrentDevice: json['currentDevice'] ?? false,
      lastActiveAt: json['lastActiveAt'] ?? 0,
    );
  }

  IconData get deviceIcon {
    switch (platform) {
      case 'android':
        return Icons.phone_android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.laptop;
      default:
        return Icons.devices;
    }
  }
}
