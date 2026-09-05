import 'package:flutter/foundation.dart';

enum GlobalConnectionState {
  disconnected,
  connecting,
  connected,
  error
}

class ConnectionStateProvider extends ChangeNotifier {
  GlobalConnectionState _state = GlobalConnectionState.disconnected;

  GlobalConnectionState get state => _state;

  bool isReady() {
    return _state == GlobalConnectionState.connected;
  }

  void setConnecting() {
    if (_state != GlobalConnectionState.connecting) {
      _state = GlobalConnectionState.connecting;
      notifyListeners();
    }
  }

  void setConnected() {
    if (_state != GlobalConnectionState.connected) {
      _state = GlobalConnectionState.connected;
      notifyListeners();
    }
  }

  void setError() {
    if (_state != GlobalConnectionState.error) {
      _state = GlobalConnectionState.error;
      notifyListeners();
    }
  }

  void setDisconnected() {
    if (_state != GlobalConnectionState.disconnected) {
      _state = GlobalConnectionState.disconnected;
      notifyListeners();
    }
  }
}

final connectionStateProvider = ConnectionStateProvider();
