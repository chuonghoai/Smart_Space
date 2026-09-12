import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:mobile_shared/core/auth/jwt_utils.dart';
import 'package:mobile_shared/core/auth/token_storage.dart';
import 'package:mobile_shared/core/config/env_config.dart';
import 'package:mobile_shared/core/connection/connection_state_provider.dart';
import 'package:mobile_shared/core/exceptions/connection_exception.dart';
import 'package:mobile_shared/features/auth/services/auth_service.dart';

enum WebSocketStatus { disconnected, connecting, connected, error }

class WebSocketService extends ChangeNotifier {
  WebSocketService();

  StompClient? _client;

  WebSocketStatus _status = WebSocketStatus.disconnected;
  WebSocketStatus get status => _status;

  bool get isConnected => _status == WebSocketStatus.connected;

  // Completer để login flow có thể await kết quả kết nối
  Completer<bool>? _connectionCompleter;

  /// Khởi tạo kết nối STOMP. Trả về true nếu kết nối thành công.
  Future<bool> connect() async {
    if (_status == WebSocketStatus.connected) return true;
    if (_status == WebSocketStatus.connecting) {
      return _connectionCompleter?.future ?? Future.value(false);
    }

    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return false;

    _setStatus(WebSocketStatus.connecting);
    _connectionCompleter = Completer<bool>();

    final wsBase = EnvConfig.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final wsUrl = '$wsBase/ws';

    final stompHeaders = <String, String>{'Authorization': 'Bearer $token'};
    final wsHeaders = <String, dynamic>{'Authorization': 'Bearer $token'};

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        // Gửi JWT trong STOMP CONNECT frame
        stompConnectHeaders: stompHeaders,
        webSocketConnectHeaders: wsHeaders,
        beforeConnect: () async {
          String? currentToken = await TokenStorage.getAccessToken();
          if (currentToken == null ||
              currentToken.isEmpty ||
              JwtUtils.isExpired(currentToken, threshold: const Duration(minutes: 1))) {
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              debugPrint('🔄 [WS] Access token expired or near expiry, refreshing before connect...');
              final success = await authService.refreshToken(refreshToken);
              if (success) {
                currentToken = await TokenStorage.getAccessToken();
                debugPrint('🟢 [WS] Access token refreshed successfully before connect');
              } else {
                debugPrint('🔴 [WS] Refresh token failed in beforeConnect');
              }
            }
          }
          if (currentToken != null && currentToken.isNotEmpty) {
            stompHeaders['Authorization'] = 'Bearer $currentToken';
            wsHeaders['Authorization'] = 'Bearer $currentToken';
          }
        },
        onConnect: _onConnected,
        onDisconnect: _onDisconnected,
        onStompError: _onError,
        onWebSocketError: _onWebSocketError,
        // Tự động reconnect sau 5 giây nếu mất kết nối
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client!.activate();

    // Timeout sau 10 giây nếu không kết nối được
    return _connectionCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _setStatus(WebSocketStatus.error);
        if (!(_connectionCompleter?.isCompleted ?? true)) {
          _connectionCompleter?.complete(false);
        }
        return false;
      },
    );
  }

  void _onConnected(StompFrame frame) {
    debugPrint('🟢 [WS] Connected!');
    _setStatus(WebSocketStatus.connected);
    if (!(_connectionCompleter?.isCompleted ?? true)) {
      _connectionCompleter?.complete(true);
    }
  }

  void _onDisconnected(StompFrame frame) {
    debugPrint('🔴 [WS] Dis connect!');
    _setStatus(WebSocketStatus.disconnected);
  }

  void _onError(StompFrame frame) {
    debugPrint('🔴 [WS] STOMP Error: ${frame.body}');
    _setStatus(WebSocketStatus.error);
    if (!(_connectionCompleter?.isCompleted ?? true)) {
      _connectionCompleter?.complete(false);
    }
    // Khi gặp lỗi token, chủ động làm mới token để lần reconnect kế tiếp thành công
    if (frame.body?.contains('auth.token') == true) {
      TokenStorage.getRefreshToken().then((rt) {
        if (rt != null && rt.isNotEmpty) {
          debugPrint('🔄 [WS] Proactively refreshing token after auth error...');
          authService.refreshToken(rt);
        }
      });
    }
  }

  void _onWebSocketError(dynamic error) {
    debugPrint('🔴 [WS] WebSocket Error: $error');
    _setStatus(WebSocketStatus.error);
    if (!(_connectionCompleter?.isCompleted ?? true)) {
      _connectionCompleter?.complete(false);
    }
  }

  void _setStatus(WebSocketStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  @visibleForTesting
  void setStatusForTest(WebSocketStatus newStatus) => _setStatus(newStatus);

  /// Subscribe một destination
  StompUnsubscribe? subscribe({
    required String destination,
    required void Function(StompFrame) callback,
  }) {
    if (!connectionStateProvider.isReady()) {
      throw ConnectionNotReadyException('connectionUnstable');
    }
    if (!isConnected || _client == null) return null;
    return _client!.subscribe(destination: destination, callback: callback);
  }

  /// Gửi message qua STOMP
  void send({required String destination, required String body}) {
    if (!connectionStateProvider.isReady()) {
      throw ConnectionNotReadyException('connectionUnstable');
    }
    if (!isConnected || _client == null) return;
    _client!.send(destination: destination, body: body);
  }

  /// Ngắt kết nối khi logout
  void disconnect() {
    _client?.deactivate();
    _client = null;
    _setStatus(WebSocketStatus.disconnected);
  }
}

/// Singleton toàn app
final webSocketService = WebSocketService();
