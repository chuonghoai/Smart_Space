import 'dart:convert' as dart_convert;

import 'package:flutter/foundation.dart';
import 'package:mobile_shared/core/auth/token_storage.dart';
import 'package:mobile_shared/core/interceptors/error_interceptor.dart';
import 'package:mobile_shared/core/websocket/websocket_service.dart';
import 'package:mobile_shared/core/websocket/ws_feature_service.dart';
import 'package:mobile_shared/features/auth/services/auth_service.dart';
import 'package:mobile_shared/util/device_info_util.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// Lắng nghe việc phiên đăng nhập bị thu hồi từ thiết bị khác
/// ("Đăng xuất thiết bị" / "Đăng xuất tất cả thiết bị khác").
///
/// Backend gửi `{type: SESSION_REVOKED, deviceIds: [...]}` tới mọi thiết bị của user;
/// thiết bị nào có deviceId nằm trong danh sách thì tự đăng xuất ngay và phát lý do
/// [revokedReason] qua [ErrorInterceptor.unauthenticatedStream] để app điều hướng về
/// màn đăng nhập + hiển thị thông báo.
class SessionWsService implements WsFeatureService {
  static const String destination = '/user/queue/session';
  static const String revokedReason = 'session_revoked';
  static const String _typeSessionRevoked = 'SESSION_REVOKED';

  StompUnsubscribe? _subscription;
  bool _handlingRevoke = false;

  @override
  void setup() {
    if (_subscription != null) return;
    try {
      _subscription = webSocketService.subscribe(
        destination: destination,
        callback: (frame) => _onFrame(frame.body),
      );
    } catch (e) {
      debugPrint('[WS-Session] subscribe() threw: $e');
    }
  }

  Future<void> _onFrame(String? body) async {
    if (body == null || _handlingRevoke) return;

    final List<String> revokedIds;
    try {
      final data = dart_convert.jsonDecode(body);
      if (data is! Map<String, dynamic> || data['type'] != _typeSessionRevoked) return;
      revokedIds = [
        for (final id in (data['deviceIds'] as List? ?? const []))
          if (id is String) id,
      ];
    } catch (e) {
      debugPrint('[WS-Session] Parse error: $e');
      return;
    }

    final myDeviceId = await DeviceInfoUtil.getDeviceId();
    if (!revokedIds.contains(myDeviceId)) return;

    // Có thể đã bị đăng xuất bởi luồng 401 của ErrorInterceptor chạy song song
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return;

    _handlingRevoke = true;
    try {
      debugPrint('[WS-Session] This device was signed out remotely — logging out.');
      await authService.logout();
      ErrorInterceptor.unauthenticatedStream.add(revokedReason);
    } finally {
      _handlingRevoke = false;
    }
  }

  @override
  void reset() {
    _subscription?.call();
    _subscription = null;
  }

  @override
  void dispose() {
    reset();
  }
}
