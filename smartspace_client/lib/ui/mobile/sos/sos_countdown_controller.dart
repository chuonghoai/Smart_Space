import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartspace_client/features/sos/providers/sos_provider.dart';

enum SosCountdownPhase { counting, locating, sending, sent, failed }

enum SosCountdownFailure { permissionDenied, locationUnavailable, sendFailed }

class SosCountdownState {
  final SosCountdownPhase phase;
  final int secondsLeft;
  final SosCountdownFailure? failure;
  final String? serverMessage;

  const SosCountdownState({
    this.phase = SosCountdownPhase.counting,
    this.secondsLeft = SosCountdownController.seconds,
    this.failure,
    this.serverMessage,
  });
}

/// Đếm ngược 5 giây (huỷ được) rồi gửi SOS; vị trí được lấy song song trong lúc đếm.
class SosCountdownController extends StateNotifier<SosCountdownState> {
  static const int seconds = 5;
  static const Duration _locationTimeout = Duration(seconds: 10);

  final Ref _ref;
  Timer? _timer;
  Future<Position?>? _position;
  bool _permissionDenied = false;

  SosCountdownController(this._ref) : super(const SosCountdownState()) {
    _position = _acquirePosition();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.secondsLeft - 1;
      if (next > 0) {
        state = SosCountdownState(secondsLeft: next);
      } else {
        timer.cancel();
        _send();
      }
    });
  }

  /// Thử lại ngay, không đếm ngược nữa.
  Future<void> retry() async {
    if (state.failure != SosCountdownFailure.sendFailed) {
      _permissionDenied = false;
      _position = _acquirePosition();
    }
    await _send();
  }

  Future<void> openSettings() => Geolocator.openAppSettings();

  Future<void> _send() async {
    state = const SosCountdownState(phase: SosCountdownPhase.locating, secondsLeft: 0);
    final position = await _position;
    if (!mounted) return;
    if (position == null) {
      state = SosCountdownState(
        phase: SosCountdownPhase.failed,
        secondsLeft: 0,
        failure: _permissionDenied
            ? SosCountdownFailure.permissionDenied
            : SosCountdownFailure.locationUnavailable,
      );
      return;
    }

    state = const SosCountdownState(phase: SosCountdownPhase.sending, secondsLeft: 0);
    final res = await _ref.read(sosProvider.notifier).start(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        );
    if (!mounted) return;
    state = res.success
        ? const SosCountdownState(phase: SosCountdownPhase.sent, secondsLeft: 0)
        : SosCountdownState(
            phase: SosCountdownPhase.failed,
            secondsLeft: 0,
            failure: SosCountdownFailure.sendFailed,
            serverMessage: res.message,
          );
  }

  Future<Position?> _acquirePosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _permissionDenied = true;
        return null;
      }
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: _locationTimeout,
          ),
        );
      } catch (e) {
        // Hết thời gian chờ GPS: dùng vị trí gần nhất thiết bị còn nhớ
        debugPrint('[SOS] Current position failed, falling back to last known: $e');
        return await Geolocator.getLastKnownPosition();
      }
    } catch (e) {
      debugPrint('[SOS] Location error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sosCountdownControllerProvider =
    StateNotifierProvider.autoDispose<SosCountdownController, SosCountdownState>(
  (ref) => SosCountdownController(ref),
);
