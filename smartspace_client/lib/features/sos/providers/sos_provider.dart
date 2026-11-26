import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/sos/models/sos_alert_model.dart';
import 'package:mobile_shared/features/sos/services/sos_ws_service.dart';
import 'package:smartspace_client/features/sos/services/sos_location_tracker.dart';
import 'package:smartspace_client/features/sos/services/sos_service.dart';

class SosState {
  /// SOS của chính người dùng; giữ lại bản đã kết thúc để màn hình hiện trạng thái cuối.
  final SosAlertModel? sos;
  final bool isLoaded;
  final bool isStarting;
  final bool isEnding;
  final DateTime? lastSentAt;

  const SosState({
    this.sos,
    this.isLoaded = false,
    this.isStarting = false,
    this.isEnding = false,
    this.lastSentAt,
  });

  bool get hasOpen => sos?.isOpen ?? false;

  SosState copyWith({
    SosAlertModel? sos,
    bool clearSos = false,
    bool? isLoaded,
    bool? isStarting,
    bool? isEnding,
    DateTime? lastSentAt,
  }) {
    return SosState(
      sos: clearSos ? null : (sos ?? this.sos),
      isLoaded: isLoaded ?? this.isLoaded,
      isStarting: isStarting ?? this.isStarting,
      isEnding: isEnding ?? this.isEnding,
      lastSentAt: lastSentAt ?? this.lastSentAt,
    );
  }
}

/// SOS của người dùng hiện tại: gửi tín hiệu, theo dõi vị trí 15 giây, kết thúc khi an toàn.
class SosNotifier extends StateNotifier<SosState> {
  final SosService _service;
  final SosLocationTracker _tracker;
  late final StreamSubscription<SosRealtimeEvent> _events;

  SosNotifier(this._service, this._tracker, SosWsService ws) : super(const SosState()) {
    _events = ws.events.listen(_onRealtime);
  }

  /// Khôi phục SOS đang mở khi mở lại app.
  Future<void> loadActive() async {
    final res = await _service.getActive();
    if (!mounted) return;
    if (!res.success) {
      state = state.copyWith(isLoaded: true);
      return;
    }
    final active = res.data;
    if (active != null) {
      state = state.copyWith(sos: active, isLoaded: true);
    } else {
      if (state.hasOpen) _tracker.stop();
      state = state.copyWith(clearSos: state.hasOpen, isLoaded: true);
    }
  }

  Future<ApiResponse<SosAlertModel>> start({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    state = state.copyWith(isStarting: true);
    final res = await _service.start(latitude: latitude, longitude: longitude, accuracy: accuracy);
    if (!mounted) return res;
    state = res.success && res.data != null
        ? state.copyWith(sos: res.data, isStarting: false, isLoaded: true, lastSentAt: DateTime.now())
        : state.copyWith(isStarting: false);
    return res;
  }

  /// Bật theo dõi vị trí nếu đang có SOS mở (gọi lại nhiều lần vẫn an toàn).
  void ensureTracking({required String notificationTitle, required String notificationText}) {
    if (!state.hasOpen || _tracker.isRunning) return;
    _tracker.start(
      onPosition: _sendLocation,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
    );
  }

  Future<ApiResponse<SosAlertModel>> markSafe() async {
    final current = state.sos;
    if (current == null) {
      return ApiResponse(success: false, message: '');
    }
    state = state.copyWith(isEnding: true);
    final res = await _service.markSafe(current.id);
    if (!mounted) return res;
    if (res.success && res.data != null) {
      _tracker.stop();
      state = state.copyWith(sos: res.data, isEnding: false);
    } else {
      state = state.copyWith(isEnding: false);
    }
    return res;
  }

  /// Bỏ SOS đã kết thúc khỏi state sau khi người dùng rời màn hình.
  void clearClosed() {
    if (state.sos != null && !state.hasOpen) {
      state = state.copyWith(clearSos: true);
    }
  }

  /// Đồng bộ SOS của chính mình khi mở từ deep-link / thông báo lúc cold start.
  void syncOwn(SosAlertModel sos) {
    final current = state.sos;
    state = state.copyWith(
      sos: current != null && current.id == sos.id ? current.mergeRealtime(sos) : sos,
      isLoaded: true,
    );
    if (!sos.isOpen) _tracker.stop();
  }

  /// Dừng theo dõi vị trí và xoá state khi đăng xuất để không rò sang phiên mới.
  void resetOnLogout() {
    _tracker.stop();
    state = const SosState();
  }

  Future<void> _sendLocation(Position position) async {
    final current = state.sos;
    if (current == null || !current.isOpen) {
      _tracker.stop();
      return;
    }
    final res = await _service.updateLocation(
      current.id,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
    if (!mounted) return;
    if (res.success && res.data != null) {
      _apply(res.data!);
      state = state.copyWith(lastSentAt: DateTime.now());
    } else {
      // Có thể admin đã kết thúc SOS: đồng bộ lại trạng thái
      await loadActive();
    }
  }

  void _onRealtime(SosRealtimeEvent event) {
    if (event.sos.id == state.sos?.id) _apply(event.sos);
  }

  void _apply(SosAlertModel update) {
    final current = state.sos;
    state = state.copyWith(sos: current != null ? current.mergeRealtime(update) : update);
    if (!update.isOpen) _tracker.stop();
  }

  @override
  void dispose() {
    _events.cancel();
    _tracker.stop();
    super.dispose();
  }
}

final sosProvider = StateNotifierProvider<SosNotifier, SosState>(
  (ref) => SosNotifier(sosService, sosLocationTracker, sosWsService),
);

// SOS của người mình bảo hộ

class WatchedSosState {
  final SosAlertModel? sos;
  final bool isLoading;
  final String? error;

  const WatchedSosState({this.sos, this.isLoading = false, this.error});
}

/// Theo dõi SOS của người khác: tải một lần, cập nhật qua realtime, làm mới định kỳ phòng mất kết nối.
class WatchedSosNotifier extends StateNotifier<WatchedSosState> {
  static const _refreshEvery = Duration(seconds: 30);

  final SosService _service;
  final String sosId;
  late final StreamSubscription<SosRealtimeEvent> _events;
  Timer? _refresh;

  WatchedSosNotifier(this._service, this.sosId, SosWsService ws)
      : super(const WatchedSosState(isLoading: true)) {
    _events = ws.events.listen((event) {
      if (event.sos.id != sosId) return;
      final current = state.sos;
      state = WatchedSosState(sos: current != null ? current.mergeRealtime(event.sos) : event.sos);
      if (!event.sos.isOpen) _refresh?.cancel();
    });
    load();
    _refresh = Timer.periodic(_refreshEvery, (_) {
      if (state.sos?.isOpen ?? true) load(silent: true);
    });
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) state = WatchedSosState(sos: state.sos, isLoading: true);
    final res = await _service.getById(sosId);
    if (!mounted) return;
    if (res.success && res.data != null) {
      state = WatchedSosState(sos: res.data);
      if (!res.data!.isOpen) _refresh?.cancel();
    } else if (!silent || state.sos == null) {
      state = WatchedSosState(sos: state.sos, error: res.message);
    }
  }

  @override
  void dispose() {
    _events.cancel();
    _refresh?.cancel();
    super.dispose();
  }
}

final watchedSosProvider =
    StateNotifierProvider.autoDispose.family<WatchedSosNotifier, WatchedSosState, String>(
  (ref, sosId) => WatchedSosNotifier(sosService, sosId, sosWsService),
);
