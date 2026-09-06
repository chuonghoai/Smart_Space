import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_shared/core/api/api_client.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  // Save token
  static String? _currentFcmToken;
  static String? get currentFcmToken => _currentFcmToken;

  /// Stream emitted when user taps a notification (foreground, background, or terminated).
  /// Payload: FCM data map (e.g. { "reportId": "...", "type": "REPORT_CREATED" })
  static final StreamController<Map<String, dynamic>> _tapController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get onNotificationTapped =>
      _tapController.stream;

  static Future<void> initialize(FirebaseOptions options) async {
    await Firebase.initializeApp(options: options);

    await _initLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    await _requestPermission();

    _listenForeground();

    _listenOnMessageOpenedApp();

    // Listen for token refresh once during initialization
    _messaging.onTokenRefresh.listen((newToken) {
      _currentFcmToken = newToken;
      _sendTokenToServer(newToken);
    });

    debugPrint('[FCM] Firebase initialized');
  }

  /// Call this after the router/navigator is ready to handle the case
  /// where the app was launched from a terminated state by tapping a notification.
  static Future<void> checkInitialMessage() async {
    final RemoteMessage? initial = await _messaging.getInitialMessage();
    if (initial != null && initial.data.isNotEmpty) {
      debugPrint('[FCM] Initial message (terminated tap): ${initial.data}');
      // Small delay to ensure navigator is ready
      await Future.delayed(const Duration(milliseconds: 500));
      _tapController.add(initial.data);
    }
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        // Handle tap on a local notification (foreground FCM or upload progress).
        // FCM payload is a JSON string: {"reportId":"...","type":"..."}.
        // Upload-progress payload is a plain UUID string.
        if (response.payload == null || response.payload!.isEmpty) return;
        try {
          // FCM-style JSON payload
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          debugPrint('[FCM] Local notification tapped (JSON payload): $data');
          _tapController.add(data);
        } catch (_) {
          // Plain UUID from upload-progress notification
          debugPrint('[FCM] Local notification tapped (plain UUID): ${response.payload}');
          _tapController.add({'reportId': response.payload});
        }
      },
    );
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
  }

  /// Lấy FCM token và đăng ký với backend
  static Future<String?> getAndRegisterToken() async {
    try {
      if (kIsWeb) {
        // Web cần VAPID key từ Firebase Console -> Cloud Messaging -> Web Push certificates
        _currentFcmToken = await _messaging.getToken(
          vapidKey:
              'BBLFiE3Jmbsbm9mxtGID5umVMiyJ8yo2PuVBKuJWr9pJvs8zcWbs9KQf7c53Hkn1uFBadTBpXbperl8NHjFlcOM',
        );
      } else {
        _currentFcmToken = await _messaging.getToken();
      }
      if (_currentFcmToken != null) {
        await _sendTokenToServer(_currentFcmToken!);
        debugPrint('[FCM] Token: ${_currentFcmToken!.substring(0, 20)}...');
      }
      return _currentFcmToken;
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      return null;
    }
  }

  /// Gửi FCM token lên backend để lưu vào DB
  static Future<void> _sendTokenToServer(String token) async {
    try {
      final platform = kIsWeb ? 'web' : 'android';
      await apiClient.post(
        '/devices/fcm-token',
        data: {
          'fcmToken': token,
          'platform': platform,
          'deviceName': kIsWeb ? 'Web Browser' : null,
        },
      );
      debugPrint('[FCM] Token registered on server');
    } catch (e) {
      debugPrint('[FCM] Token register failed: $e');
    }
  }

  static Future<void> clearTokenOnServer() async {
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
        // Encode FCM data as payload so we can navigate on tap
        final payload = message.data.isNotEmpty
            ? jsonEncode(message.data)
            : null;

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

  /// User tap vào notification khi app đang background
  static void _listenOnMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Tapped (background): ${message.data}');
      if (message.data.isNotEmpty) {
        _tapController.add(message.data);
      }
    });
  }
}
