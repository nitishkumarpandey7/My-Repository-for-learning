import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'replace-with-firebase-api-key',
    appId: '1:000000000000:android:lifeosx',
    messagingSenderId: '000000000000',
    projectId: 'lifeos-x-dev',
    storageBucket: 'lifeos-x-dev.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'replace-with-firebase-api-key',
    appId: '1:000000000000:ios:lifeosx',
    messagingSenderId: '000000000000',
    projectId: 'lifeos-x-dev',
    storageBucket: 'lifeos-x-dev.appspot.com',
    iosBundleId: 'com.lifeosx.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'replace-with-firebase-api-key',
    appId: '1:000000000000:web:lifeosx',
    messagingSenderId: '000000000000',
    projectId: 'lifeos-x-dev',
    authDomain: 'lifeos-x-dev.firebaseapp.com',
    storageBucket: 'lifeos-x-dev.appspot.com',
  );
}

