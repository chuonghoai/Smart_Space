import 'package:jwt_decoder/jwt_decoder.dart';

class JwtService {
  Map<String, dynamic> decode(String token) {
    return JwtDecoder.decode(token);
  }

  bool isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  String? getRole(String token) {
    try {
      final decoded = decode(token);
      return decoded['role'] as String?;
    } catch (_) {
      return null;
    }
  }
}

final jwtService = JwtService();
