import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBnfQ1Eo6hfJ1rEnO3i4JOObGT_O8Iw1ak',
    appId: '1:481022634874:web:1d27ccf373ebbfde0ac4c3',
    messagingSenderId: '481022634874',
    projectId: 'smart-space-36687',
    authDomain: 'smart-space-36687.firebaseapp.com',
    storageBucket: 'smart-space-36687.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZD_bgV0YFHNe1hMGXZFun-sUhrHqKr3I',
    appId: '1:481022634874:android:814aba3152594b3a0ac4c3',
    messagingSenderId: '481022634874',
    projectId: 'smart-space-36687',
    storageBucket: 'smart-space-36687.firebasestorage.app',
  );
}
