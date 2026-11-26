import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mobile_shared/core/auth/token_storage.dart';
import 'package:mobile_shared/core/connection/connection_state_provider.dart';
import 'package:mobile_shared/core/notification/firebase_service.dart';
import 'package:mobile_shared/core/websocket/websocket_service.dart';
import 'package:mobile_shared/features/auth/services/auth_service.dart';

class ConnectionManagerService {
  bool _isRunning = false;
  bool _isUserLoggedIn = false;
  bool _keepAliveForActiveCall = false;

  void setKeepAliveForActiveCall(bool active) {
    _keepAliveForActiveCall = active;
  }
  
  // Variables for Exponential Backoff
  Timer? _fcmRetryTimer;
  int _fcmRetryAttempt = 0;
  final int _maxBackoffSeconds = 30;
  
  bool _isFcmConnected = false;
  bool _isFcmConnecting = false;
  bool get isFcmConnected => _isFcmConnected;
  bool get isWebSocketConnected => webSocketService.isConnected;

  void startConnections() {
    _isUserLoggedIn = true;
    if (_isRunning) return;
    _isRunning = true;
    _fcmRetryAttempt = 0;
    _isFcmConnected = FirebaseService.isBackendRegistered;
    
    connectionStateProvider.setConnecting();
    
    // 0. Start scheduled 28-min token refresh
    authService.startScheduledTokenRefresh();

    // 1. WebSocket connects
    webSocketService.removeListener(_onSocketStateChanged);
    webSocketService.addListener(_onSocketStateChanged);
    webSocketService.connect();
    
    // 2. FCM connects & tracks backend registration independently of other app APIs
    FirebaseService.onBackendRegistrationChanged = _onFcmRegistrationChanged;
    _startFcmRegistration();
  }

  void _onFcmRegistrationChanged(bool registered) {
    if (!_isRunning) return;
    _isFcmConnected = registered;
    if (registered) {
      _isFcmConnecting = false;
      _fcmRetryAttempt = 0;
      _fcmRetryTimer?.cancel();
    }
    _updateGlobalState();
  }

  void _onSocketStateChanged() {
    _updateGlobalState();
  }

  void _updateGlobalState() {
    if (!_isRunning) return;
    final socketStatus = webSocketService.status;
    evaluateGlobalConnectionState(
      wsConnected: socketStatus == WebSocketStatus.connected,
      wsConnecting: socketStatus == WebSocketStatus.connecting,
      fcmConnected: _isFcmConnected,
      fcmConnecting: _isFcmConnecting,
    );
  }

  /// Pure status rule: Green ONLY when BOTH WebSocket and Firebase are connected
  /// to the backend; Red otherwise (Connecting only while an active initial/retry
  /// handshake is in flight and neither side has failed).
  @visibleForTesting
  static void evaluateGlobalConnectionState({
    required bool wsConnected,
    required bool wsConnecting,
    required bool fcmConnected,
    required bool fcmConnecting,
  }) {
    if (wsConnected && fcmConnected) {
      connectionStateProvider.setConnected();
    } else if ((!wsConnected && !wsConnecting) ||
        (!fcmConnected && !fcmConnecting)) {
      connectionStateProvider.setError();
    } else {
      connectionStateProvider.setConnecting();
    }
  }

  Future<void> _startFcmRegistration() async {
    if (!_isRunning || _isFcmConnecting) return;
    _isFcmConnecting = true;
    _updateGlobalState();

    try {
      final token = await FirebaseService.getAndRegisterToken();
      if (!_isRunning) return;
      _isFcmConnecting = false;
      if (token != null) {
        _isFcmConnected = true;
        _fcmRetryAttempt = 0;
        _updateGlobalState();
      } else {
        _scheduleFcmRetry();
      }
    } catch (e) {
      _isFcmConnecting = false;
      if (_isRunning) {
        _scheduleFcmRetry();
      }
    }
  }

  void _scheduleFcmRetry() {
    if (!_isRunning) return;
    
    _isFcmConnected = false;
    _isFcmConnecting = false;
    _updateGlobalState();
    
    _fcmRetryAttempt++;
    // Exponential backoff: 2^attempt, max 30s
    final delaySeconds = min(pow(2, _fcmRetryAttempt).toInt(), _maxBackoffSeconds);
    
    _fcmRetryTimer?.cancel();
    _fcmRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      _startFcmRegistration();
    });
  }

  void onAppBackgrounded() {
    debugPrint('[ConnectionManager] App backgrounded (preserving OS-managed WebSocket)');
  }

  void pauseConnections() {
    if (!_isRunning) return;
    if (_keepAliveForActiveCall) {
      debugPrint('[ConnectionManager] Keeping WebSocket alive for active call');
      return;
    }
    debugPrint('[ConnectionManager] Pausing connections (Detached)');
    _isRunning = false;
    _fcmRetryTimer?.cancel();
    _isFcmConnecting = false;
    FirebaseService.onBackendRegistrationChanged = null;
    webSocketService.removeListener(_onSocketStateChanged);
    webSocketService.disconnect();
    connectionStateProvider.setDisconnected();
  }

  Future<void> resumeConnections() async {
    if (_isRunning) {
      if (!webSocketService.isConnected &&
          webSocketService.status != WebSocketStatus.connecting) {
        debugPrint('[ConnectionManager] Reconnecting dropped WebSocket on Foreground');
        webSocketService.connect();
      }
      if (!_isFcmConnected && !_isFcmConnecting) {
        debugPrint('[ConnectionManager] Retrying Firebase backend registration');
        _startFcmRegistration();
      }
      return;
    }
    if (_isUserLoggedIn) {
      debugPrint('[ConnectionManager] Resuming connections (Foreground)');
      startConnections();
      return;
    }
    // Khi reload trang Web, kiểm tra token trong storage để tự động kết nối lại
    try {
      final token = await TokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('[ConnectionManager] User token found in storage, resuming connections');
        startConnections();
      }
    } catch (e) {
      debugPrint('[ConnectionManager] TokenStorage not ready: $e');
    }
  }

  void stopAllAndCleanUp() {
    debugPrint('[ConnectionManager] Stop all and cleanup (Logout)');
    _isUserLoggedIn = false;
    _isRunning = false;
    _fcmRetryTimer?.cancel();
    _fcmRetryAttempt = 0;
    _isFcmConnected = false;
    _isFcmConnecting = false;
    FirebaseService.onBackendRegistrationChanged = null;
    
    webSocketService.removeListener(_onSocketStateChanged);
    webSocketService.disconnect();
    
    connectionStateProvider.setDisconnected();
  }
}

final connectionManager = ConnectionManagerService();
