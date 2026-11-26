// Test-only Firebase mock helper. NEVER import this file into production lib/ code.
// ignore_for_file: depend_on_referenced_packages

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _fcmChannel = MethodChannel('plugins.flutter.io/firebase_messaging');
const MethodChannel _fcmBgChannel = MethodChannel('plugins.flutter.io/firebase_messaging_background');

Future<void> setupFirebaseTestMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(_fcmChannel, (MethodCall call) async {
    switch (call.method) {
      case 'Messaging#getInitialMessage':
        return null;
      case 'Messaging#requestPermission':
      case 'Messaging#getNotificationSettings':
        return <String, int>{
          'authorizationStatus': 1,
          'alert': 1,
          'announcement': 0,
          'badge': 1,
          'carPlay': 0,
          'criticalAlert': 0,
          'lockScreen': 1,
          'notificationCenter': 1,
          'showPreviews': 1,
          'sound': 1,
          'timeSensitive': 0,
          'providesAppNotificationSettings': 0,
        };
      case 'Messaging#getToken':
        return <String, String>{'token': 'mock-test-fcm-token'};
      case 'Messaging#getAPNSToken':
        return <String, String?>{'token': null};
      case 'Messaging#setAutoInitEnabled':
        return <String, bool>{'isAutoInitEnabled': true};
      default:
        return <String, dynamic>{};
    }
  });

  messenger.setMockMethodCallHandler(_fcmBgChannel, (MethodCall call) async => null);

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

void tearDownFirebaseTestMocks() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_fcmChannel, null);
  messenger.setMockMethodCallHandler(_fcmBgChannel, null);
}
