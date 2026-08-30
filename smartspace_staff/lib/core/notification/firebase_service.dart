import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:smartspace_staff/core/api/api_client.dart';
import 'package:smartspace_staff/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

class FirebaseService {
  static final _messaging = FirebaseMessaging.instance;

  // Save token
  static String? _currentFcmToken;
  static String? get currentFcmToken => _currentFcmToken;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

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
      // TODO: Hiển thị SnackBar hoặc in-app notification
    });
  }

  /// User tap vào notification khi app đang background
  static void _listenOnMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Tapped: ${message.data}');
      // TODO: Navigate đến screen phù hợp dựa vào message.data
    });
  }
}
