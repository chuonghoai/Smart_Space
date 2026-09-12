import 'dart:convert';

class JwtUtils {
  /// Giải mã payload của JWT token mà không cần thư viện ngoài
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      var normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(payloadString) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Lấy thời điểm hết hạn (UTC) của JWT token
  static DateTime? getExpiration(String token) {
    final payload = decodePayload(token);
    if (payload == null || !payload.containsKey('exp')) return null;

    final exp = payload['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    }
    return null;
  }

  /// Kiểm tra token đã hết hạn hoặc sắp hết hạn trong khoảng [threshold] (mặc định 1 phút)
  static bool isExpired(String token, {Duration threshold = const Duration(minutes: 1)}) {
    final exp = getExpiration(token);
    if (exp == null) return true; // Token không hợp lệ -> coi như hết hạn
    return DateTime.now().toUtc().add(threshold).isAfter(exp);
  }
}
