import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:smartspace_client/core/connection/connection_state_provider.dart';
import 'package:smartspace_client/core/notification/firebase_service.dart';
import 'package:smartspace_client/core/websocket/websocket_service.dart';

class ConnectionManagerService {
  bool _isRunning = false;
  bool _isUserLoggedIn = false;
  
  // Variables for Exponential Backoff
  Timer? _fcmRetryTimer;
  int _fcmRetryAttempt = 0;
  final int _maxBackoffSeconds = 30;
  
  bool _isFcmConnected = false;

  void startConnections() {
    _isUserLoggedIn = true;
    if (_isRunning) return;
    _isRunning = true;
    _fcmRetryAttempt = 0;
    
    connectionStateProvider.setConnecting();
    
    // 1. WebSocket connects
    webSocketService.removeListener(_onSocketStateChanged);
    webSocketService.addListener(_onSocketStateChanged);
    webSocketService.connect();
    
    // 2. FCM connects
    _startFcmRegistration();
  }

  void _onSocketStateChanged() {
    _updateGlobalState();
  }

  void _updateGlobalState() {
    if (!_isRunning) return;
    
    final socketStatus = webSocketService.status;
    
    if (socketStatus == WebSocketStatus.connected && _isFcmConnected) {
      connectionStateProvider.setConnected();
    } else if (socketStatus == WebSocketStatus.error || socketStatus == WebSocketStatus.disconnected) {
      connectionStateProvider.setError();
    } else {
      connectionStateProvider.setConnecting();
    }
  }

  Future<void> _startFcmRegistration() async {
    if (!_isRunning) return;
    
    try {
      final token = await FirebaseService.getAndRegisterToken();
      if (token != null) {
        _isFcmConnected = true;
        _fcmRetryAttempt = 0;
        _updateGlobalState();
      } else {
        _scheduleFcmRetry();
      }
    } catch (e) {
      _scheduleFcmRetry();
    }
  }

  void _scheduleFcmRetry() {
    if (!_isRunning) return;
    
    _isFcmConnected = false;
    _updateGlobalState();
    
    _fcmRetryAttempt++;
    // Exponential backoff: 2^attempt, max 30s
    final delaySeconds = min(pow(2, _fcmRetryAttempt).toInt(), _maxBackoffSeconds);
    
    _fcmRetryTimer?.cancel();
    _fcmRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      _startFcmRegistration();
    });
  }

  void pauseConnections() {
    if (!_isRunning) return;
    debugPrint('[ConnectionManager] Pausing connections (Background)');
    _isRunning = false;
    _fcmRetryTimer?.cancel();
    webSocketService.removeListener(_onSocketStateChanged);
    webSocketService.disconnect();
    connectionStateProvider.setDisconnected();
  }

  void resumeConnections() {
    if (_isUserLoggedIn && !_isRunning) {
      debugPrint('[ConnectionManager] Resuming connections (Foreground)');
      startConnections();
    }
  }

  void stopAllAndCleanUp() {
    debugPrint('[ConnectionManager] Stop all and cleanup (Logout)');
    _isUserLoggedIn = false;
    _isRunning = false;
    _fcmRetryTimer?.cancel();
    _fcmRetryAttempt = 0;
    _isFcmConnected = false;
    
    webSocketService.removeListener(_onSocketStateChanged);
    webSocketService.disconnect();
    
    connectionStateProvider.setDisconnected();
  }
}

final connectionManager = ConnectionManagerService();
