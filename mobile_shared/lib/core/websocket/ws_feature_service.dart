import 'package:flutter/foundation.dart';

/// Base class cho tất cả các service muốn đăng ký nhận event từ WebSocket.
/// Bất kỳ feature nào cần lắng nghe STOMP destination đều nên kế thừa class này.
abstract class WsFeatureService {
  /// Khởi tạo subscription vào STOMP destination tương ứng.
  /// Gọi khi global connection đã `connected`.
  void setup();

  /// Hủy subscription khi app bị ẩn hoặc mất kết nối.
  void reset();

  /// Dọn dẹp tài nguyên (khi logout, dispose app).
  void dispose();
}

/// Nơi tập trung quản lý tất cả các WebSocket feature của ứng dụng.
class WsServicesRegistry {
  static final List<WsFeatureService> _services = [];

  /// Đăng ký một service vào hệ thống.
  static void register(WsFeatureService service) {
    if (!_services.contains(service)) {
      _services.add(service);
    }
  }

  /// Khởi chạy setup cho toàn bộ service (gọi khi WS connected).
  static void setupAll() {
    debugPrint('[WsServicesRegistry] Setting up ${_services.length} services...');
    for (final service in _services) {
      service.setup();
    }
  }

  /// Reset toàn bộ service (gọi khi WS mất kết nối).
  static void resetAll() {
    debugPrint('[WsServicesRegistry] Resetting all services...');
    for (final service in _services) {
      service.reset();
    }
  }

  /// Dọn dẹp toàn bộ (gọi khi logout hoặc shutdown).
  static void disposeAll() {
    debugPrint('[WsServicesRegistry] Disposing all services...');
    for (final service in _services) {
      service.dispose();
    }
    _services.clear();
  }
}
