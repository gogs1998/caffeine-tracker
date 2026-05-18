// File generated manually from Firebase Console
// Project: CaffeineIQ (caffeineiq-27222)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return web; // fallback
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAtUcYJx91REn88q-2uy-dg3gIOh0JE5mo',
    authDomain: 'caffeineiq-27222.firebaseapp.com',
    projectId: 'caffeineiq-27222',
    storageBucket: 'caffeineiq-27222.firebasestorage.app',
    messagingSenderId: '611860451395',
    appId: '1:611860451395:web:51f72df301b4d894e544f6',
    measurementId: 'G-LD77LN9BRR',
  );

  // Android/iOS — same project, platform-specific app IDs needed later
  // For now using web config as placeholder until google-services.json is added
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAtUcYJx91REn88q-2uy-dg3gIOh0JE5mo',
    authDomain: 'caffeineiq-27222.firebaseapp.com',
    projectId: 'caffeineiq-27222',
    storageBucket: 'caffeineiq-27222.firebasestorage.app',
    messagingSenderId: '611860451395',
    appId: '1:611860451395:web:51f72df301b4d894e544f6',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAtUcYJx91REn88q-2uy-dg3gIOh0JE5mo',
    authDomain: 'caffeineiq-27222.firebaseapp.com',
    projectId: 'caffeineiq-27222',
    storageBucket: 'caffeineiq-27222.firebasestorage.app',
    messagingSenderId: '611860451395',
    appId: '1:611860451395:web:51f72df301b4d894e544f6',
  );
}
