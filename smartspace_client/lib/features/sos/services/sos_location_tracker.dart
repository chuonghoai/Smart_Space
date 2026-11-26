import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Gửi vị trí mỗi [interval] trong khi SOS còn mở.
/// Android chạy foreground service (thông báo cố định) để tiếp tục khi app ở nền.
class SosLocationTracker {
  static const Duration interval = Duration(seconds: 15);

  StreamSubscription<Position>? _subscription;
  Timer? _heartbeat;
  Position? _latest;
  DateTime? _lastSentAt;
  bool _sending = false;
  Future<void> Function(Position position)? _onPosition;

  bool get isRunning => _subscription != null;

  /// [notificationTitle]/[notificationText]: nội dung thông báo foreground service (đã L10n).
  void start({
    required Future<void> Function(Position position) onPosition,
    required String notificationTitle,
    required String notificationText,
  }) {
    stop();
    _onPosition = onPosition;

    _subscription = Geolocator.getPositionStream(
      locationSettings: _settings(notificationTitle, notificationText),
    ).listen(
      (position) {
        _latest = position;
        _maybeSend();
      },
      onError: (Object e) => debugPrint('[SOS-Track] Position stream error: $e'),
    );

    // Đứng yên thì stream có thể im lặng: vẫn gửi lại vị trí gần nhất đúng nhịp
    _heartbeat = Timer.periodic(interval, (_) => _maybeSend());
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _latest = null;
    _lastSentAt = null;
    _onPosition = null;
  }

  /// Gửi vị trí mới nhất nếu đã tới nhịp (chừa 1 giây cho sai lệch của timer).
  Future<void> _maybeSend() async {
    final position = _latest;
    final callback = _onPosition;
    if (position == null || callback == null || _sending) return;
    final last = _lastSentAt;
    final due = last == null || DateTime.now().difference(last) >= interval - const Duration(seconds: 1);
    if (!due) return;

    _sending = true;
    _lastSentAt = DateTime.now();
    try {
      await callback(position);
    } catch (e) {
      debugPrint('[SOS-Track] Send failed: $e');
    } finally {
      _sending = false;
    }
  }

  static LocationSettings _settings(String title, String text) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: interval,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: title,
          notificationText: text,
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        activityType: ActivityType.other,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
  }
}

final sosLocationTracker = SosLocationTracker();
