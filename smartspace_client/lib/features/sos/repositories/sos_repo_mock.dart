import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:smartspace_client/features/sos/repositories/sos_repo.dart';

/// SOS giả lập trong bộ nhớ.
class SosRepoMock implements SosRepo {
  static const _delay = Duration(milliseconds: 400);
  SosAlertModel? _current;

  ApiResponse<SosAlertModel> _ok(SosAlertModel? data) =>
      ApiResponse(success: true, message: 'Success', data: data);

  SosAlertModel _copy(SosAlertModel s, {ESosStatus? status, double? lat, double? lng, double? acc}) {
    return SosAlertModel(
      id: s.id,
      status: status ?? s.status,
      resolution: status == ESosStatus.resolved ? ESosResolution.safeByUser : s.resolution,
      user: s.user,
      latitude: lat ?? s.latitude,
      longitude: lng ?? s.longitude,
      accuracy: acc ?? s.accuracy,
      lastLocationAt: DateTime.now(),
      notifiedContacts: s.notifiedContacts,
      createdAt: s.createdAt,
      resolvedAt: status == ESosStatus.resolved ? DateTime.now() : null,
    );
  }

  @override
  Future<ApiResponse<SosAlertModel>> start({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await Future.delayed(_delay);
    _current ??= SosAlertModel(
      id: 'sos-mock',
      status: ESosStatus.active,
      user: const SosUserModel(id: 'me', fullName: 'Me', phone: '0912345678'),
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      lastLocationAt: DateTime.now(),
      notifiedContacts: 2,
      createdAt: DateTime.now(),
    );
    return _ok(_current);
  }

  @override
  Future<ApiResponse<SosAlertModel>> getActive() async {
    await Future.delayed(_delay);
    final current = _current;
    return _ok(current != null && current.isOpen ? current : null);
  }

  @override
  Future<ApiResponse<SosAlertModel>> updateLocation(
    String id, {
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await Future.delayed(_delay);
    final current = _current;
    if (current == null) {
      return ApiResponse(success: false, message: 'SOS not found');
    }
    _current = _copy(current, lat: latitude, lng: longitude, acc: accuracy);
    return _ok(_current);
  }

  @override
  Future<ApiResponse<SosAlertModel>> markSafe(String id) async {
    await Future.delayed(_delay);
    final current = _current;
    if (current == null) {
      return ApiResponse(success: false, message: 'SOS not found');
    }
    _current = _copy(current, status: ESosStatus.resolved);
    return _ok(_current);
  }

  @override
  Future<ApiResponse<SosAlertModel>> getById(String id) async {
    await Future.delayed(_delay);
    return _ok(_current);
  }
}
