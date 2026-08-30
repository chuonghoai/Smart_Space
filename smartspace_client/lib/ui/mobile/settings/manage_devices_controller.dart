import 'package:flutter/material.dart';
import 'package:smartspace_client/core/utils/device_info_util.dart';
import 'package:smartspace_client/features/auth/models/DeviceSessionModel.dart';
import 'package:smartspace_client/features/auth/services/auth_service.dart';

class ManageDevicesController extends ChangeNotifier {
  final AuthService _authService;

  ManageDevicesController({AuthService? service})
    : _authService = service ?? authService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<DeviceSessionModel> _sessions = [];
  List<DeviceSessionModel> get sessions => _sessions;

  DeviceSessionModel? get currentDevice =>
      _sessions.where((s) => s.isCurrentDevice).firstOrNull;

  List<DeviceSessionModel> get otherDevices =>
      _sessions.where((s) => !s.isCurrentDevice).toList();

  Future<void> loadSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final response = await _authService.getActiveSessions(deviceId);
      if (response.success && response.data != null) {
        _sessions = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> revokeSession(BuildContext context, String sessionId) async {
    try {
      final response = await _authService.revokeSession(sessionId);
      if (response.success) {
        _sessions.removeWhere((s) => s.sessionId == sessionId);
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đăng xuất thiết bị')),
          );
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> revokeAllOtherSessions(BuildContext context) async {
    try {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final response = await _authService.revokeAllOtherSessions(deviceId);
      if (response.success) {
        _sessions.removeWhere((s) => !s.isCurrentDevice);
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã đăng xuất tất cả thiết bị khác'),
            ),
          );
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
