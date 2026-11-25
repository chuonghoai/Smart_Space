import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_shared/core/api/api_client.dart';

const String _wsCallNoticeChannelId = 'smartspace_ws_call_notice';
const String _wsCallNoticeChannelName = 'Active Call Alerts';

int _wsCallNotificationId(String callId) => callId.hashCode & 0x7fffffff;

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

class FirebaseService {
  static final _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Exposed so other services (e.g. ReportBackgroundUploadService) can
  /// reuse the SAME instance and avoid overwriting the initialization callback.
  static FlutterLocalNotificationsPlugin get localNotificationsPlugin =>
      _localNotifications;

  static String? _currentFcmToken;
  static String? get currentFcmToken => _currentFcmToken;

  static bool _isBackendRegistered = false;
  static bool get isBackendRegistered => _isBackendRegistered;
  static void Function(bool registered)? onBackendRegistrationChanged;

  /// Stream emitted when user taps a notification (foreground, background, or launched).
  /// Payload: data map (e.g. { "reportId": "...", "type": "REPORT_CREATED" })
  static final StreamController<Map<String, dynamic>> _tapController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get onNotificationTapped =>
      _tapController.stream;

  static Future<void> initialize(FirebaseOptions options) async {
    await Firebase.initializeApp(options: options);

    await _initLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    _listenForeground();
    _listenOnMessageOpenedApp();

    _messaging.onTokenRefresh.listen((newToken) async {
      _currentFcmToken = newToken;
      final registered = await _sendTokenToServer(newToken);
      _isBackendRegistered = registered;
      onBackendRegistrationChanged?.call(registered);
    });

    debugPrint('[FCM] Firebase initialized');
  }

  /// Call this after the router/navigator is ready to handle the case
  /// where the app was launched from a terminated state by tapping a notification.
  static Future<void> checkInitialMessage() async {
    final RemoteMessage? initial = await _messaging.getInitialMessage();
    if (initial != null && initial.data.isNotEmpty) {
      debugPrint('[FCM] Initial message: ${initial.data}');
      await Future.delayed(const Duration(milliseconds: 500));
      _tapController.add(initial.data);
    }

    if (!kIsWeb) {
      try {
        final details =
            await _localNotifications.getNotificationAppLaunchDetails();
        if (details != null &&
            details.didNotificationLaunchApp &&
            details.notificationResponse?.payload != null) {
          final data = jsonDecode(details.notificationResponse!.payload!)
              as Map<String, dynamic>;
          await Future.delayed(const Duration(milliseconds: 400));
          _tapController.add(data);
        }
      } catch (_) {}
    }
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null || response.payload!.isEmpty) return;
        try {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          debugPrint('[FCM] Local notification tapped: $data');
          _tapController.add(data);
        } catch (_) {
          _tapController.add({'reportId': response.payload});
        }
      },
    );

    if (!kIsWeb) {
      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _wsCallNoticeChannelId,
          _wsCallNoticeChannelName,
          description: 'Incoming call notices while app is running in background',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  /// Standard OS notification shown ONLY when the live app process receives
  /// a CALL_INCOMING event over an active WebSocket while in background.
  /// Does not use full-screen intent, call category, or FCM wake-up.
  static Future<bool> showActiveWsCallNotice({
    required String callId,
    required String title,
    required String body,
  }) async {
    if (kIsWeb || callId.isEmpty) return false;
    try {
      await _localNotifications.show(
        id: _wsCallNotificationId(callId),
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _wsCallNoticeChannelId,
            _wsCallNoticeChannelName,
            importance: Importance.high,
            priority: Priority.high,
            fullScreenIntent: false,
            autoCancel: true,
          ),
          iOS: DarwinNotificationDetails(presentSound: true),
        ),
        payload: jsonEncode({
          'type': 'WS_CALL_INCOMING',
          'callId': callId,
        }),
      );
      return true;
    } catch (e) {
      debugPrint('[WS-CALL-NOTICE] showActiveWsCallNotice failed: $e');
      return false;
    }
  }

  static Future<void> dismissActiveWsCallNotice(String callId) async {
    if (kIsWeb || callId.isEmpty) return;
    try {
      await _localNotifications.cancel(id: _wsCallNotificationId(callId));
    } catch (_) {}
  }

  static Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
  }

  static Future<String?> getAndRegisterToken() async {
    try {
      if (kIsWeb) {
        await requestPermission();
        _currentFcmToken = await _messaging.getToken(
          vapidKey:
              'BBLFiE3Jmbsbm9mxtGID5umVMiyJ8yo2PuVBKuJWr9pJvs8zcWbs9KQf7c53Hkn1uFBadTBpXbperl8NHjFlcOM',
        );
      } else {
        _currentFcmToken = await _messaging.getToken();
      }
      if (_currentFcmToken != null && _currentFcmToken!.isNotEmpty) {
        final registered = await _sendTokenToServer(_currentFcmToken!);
        _isBackendRegistered = registered;
        onBackendRegistrationChanged?.call(registered);
        if (registered) {
          debugPrint('[FCM] Token: ${_currentFcmToken!.substring(0, 20)}...');
          return _currentFcmToken;
        }
        return null;
      }
      _isBackendRegistered = false;
      onBackendRegistrationChanged?.call(false);
      return null;
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      _isBackendRegistered = false;
      onBackendRegistrationChanged?.call(false);
      return null;
    }
  }

  static Future<bool> _sendTokenToServer(String token) async {
    try {
      final platform = kIsWeb ? 'web' : 'android';
      final response = await apiClient.post(
        '/devices/fcm-token',
        data: {
          'fcmToken': token,
          'platform': platform,
          'deviceName': kIsWeb ? 'Web Browser' : null,
        },
      );
      if (response.success) {
        debugPrint('[FCM] Token registered on server');
        return true;
      }
      debugPrint('[FCM] Token register rejected: ${response.message}');
      return false;
    } catch (e) {
      debugPrint('[FCM] Token register failed: $e');
      return false;
    }
  }

  static Future<void> clearTokenOnServer() async {
    _isBackendRegistered = false;
    onBackendRegistrationChanged?.call(false);
    if (_currentFcmToken == null) return;
    try {
      await apiClient.delete('/devices/fcm-token?fcmToken=$_currentFcmToken');
      debugPrint('[FCM] Token cleared on server');
    } catch (e) {
      debugPrint('[FCM] Token clear failed: $e');
    }
  }

  static void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        final payload =
            message.data.isNotEmpty ? jsonEncode(message.data) : null;

        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_channel_id',
              'FCM Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: payload,
        );
      }
    });
  }

  static void _listenOnMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Tapped (background): ${message.data}');
      if (message.data.isNotEmpty) {
        _tapController.add(message.data);
      }
    });
  }
}
