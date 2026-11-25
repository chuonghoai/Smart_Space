import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:mobile_shared/core/auth/jwt_utils.dart';
import 'package:mobile_shared/core/auth/token_storage.dart';
import 'package:mobile_shared/core/config/env_config.dart';
import 'package:mobile_shared/core/websocket/ws_feature_service.dart';
import 'package:mobile_shared/features/auth/services/auth_service.dart';

enum WebSocketStatus { disconnected, connecting, connected, error }

class WebSocketService extends ChangeNotifier {
  WebSocketService();

  StompClient? _client;
  Timer? _callPingTimer;

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

    // Deactivate any leftover STOMP client so stale callbacks cannot corrupt _status.
    _callPingTimer?.cancel();
    _callPingTimer = null;
    final previousClient = _client;
    _client = null;
    previousClient?.deactivate();

    _setStatus(WebSocketStatus.connecting);
    final completer = Completer<bool>();
    _connectionCompleter = completer;

    final wsBase = EnvConfig.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final wsUrl = '$wsBase/ws';

    final stompHeaders = <String, String>{'Authorization': 'Bearer $token'};
    final wsHeaders = <String, dynamic>{'Authorization': 'Bearer $token'};

    late final StompClient client;
    client = StompClient(
      config: StompConfig(
        url: wsUrl,
        // Gửi JWT trong STOMP CONNECT frame
        stompConnectHeaders: stompHeaders,
        webSocketConnectHeaders: wsHeaders,
        beforeConnect: () async {
          if (!identical(client, _client)) return;
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
        onConnect: (frame) {
          if (!identical(client, _client)) return;
          _onConnected(frame);
        },
        onDisconnect: (frame) {
          if (!identical(client, _client)) return;
          _onDisconnected(frame);
        },
        onStompError: (frame) {
          if (!identical(client, _client)) return;
          _onError(frame);
        },
        onWebSocketError: (error) {
          if (!identical(client, _client)) return;
          _onWebSocketError(error);
        },
        onWebSocketDone: () {
          if (!identical(client, _client)) return;
          _onWebSocketDone();
        },
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        // Tự động reconnect sau 5 giây nếu mất kết nối
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client = client;

    client.activate();

    // Timeout sau 10 giây nếu không kết nối được
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (identical(client, _client) && !isConnected) {
          _setStatus(WebSocketStatus.error);
        }
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        return false;
      },
    );
  }

  void _onConnected(StompFrame frame) {
    debugPrint('🟢 [WS] Connected!');
    _setStatus(WebSocketStatus.connected);
    _startCallPingTimer();
    if (!(_connectionCompleter?.isCompleted ?? true)) {
      _connectionCompleter?.complete(true);
    }
    // Kích hoạt toàn bộ feature services đã đăng ký lắng nghe STOMP destinations
    WsServicesRegistry.setupAll();
  }

  void _startCallPingTimer() {
    _callPingTimer?.cancel();
    _callPingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (isConnected && _client != null) {
        try {
          _client!.send(destination: '/smartspace/call.ping', body: '{}');
        } catch (_) {}
      }
    });
  }

  void _onDisconnected(StompFrame frame) {
    debugPrint('🔴 [WS] Disconnected!');
    _callPingTimer?.cancel();
    _callPingTimer = null;
    _setStatus(WebSocketStatus.disconnected);
    WsServicesRegistry.resetAll();
  }

  void _onError(StompFrame frame) {
    debugPrint('🔴 [WS] STOMP Error: ${frame.body}');
    _callPingTimer?.cancel();
    _callPingTimer = null;
    _setStatus(WebSocketStatus.error);
    WsServicesRegistry.resetAll();
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
    _callPingTimer?.cancel();
    _callPingTimer = null;
    _setStatus(WebSocketStatus.error);
    WsServicesRegistry.resetAll();
    if (!(_connectionCompleter?.isCompleted ?? true)) {
      _connectionCompleter?.complete(false);
    }
  }

  void _onWebSocketDone() {
    debugPrint('🔴 [WS] WebSocket Done/Closed');
    _callPingTimer?.cancel();
    _callPingTimer = null;
    _setStatus(WebSocketStatus.disconnected);
    WsServicesRegistry.resetAll();
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

  /// Subscribe một destination (độc lập với trạng thái FCM / ConnectionIndicator)
  StompUnsubscribe? subscribe({
    required String destination,
    required void Function(StompFrame) callback,
  }) {
    if (!isConnected || _client == null) return null;
    return _client!.subscribe(destination: destination, callback: callback);
  }

  /// Gửi message qua STOMP (độc lập với trạng thái FCM / ConnectionIndicator)
  void send({required String destination, required String body}) {
    if (!isConnected || _client == null) return;
    _client!.send(destination: destination, body: body);
  }

  /// Ngắt kết nối khi logout
  void disconnect() {
    _callPingTimer?.cancel();
    _callPingTimer = null;
    _client?.deactivate();
    _client = null;
    _setStatus(WebSocketStatus.disconnected);
    WsServicesRegistry.resetAll();
  }
}

/// Singleton toàn app
final webSocketService = WebSocketService();
