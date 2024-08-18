// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB9LTumYw73dVv-soVfy7x3z5uUvvbKbuk',
    appId: '1:577453832706:web:0810e5c1c5c3b882d2c51b',
    messagingSenderId: '577453832706',
    projectId: 'omni-ff2a3',
    authDomain: 'omni-ff2a3.firebaseapp.com',
    storageBucket: 'omni-ff2a3.appspot.com',
    measurementId: 'G-CHJYK8D1XM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQg7NxQ6e82dpT24PGlFrp1Sb_j7lCo4w',
    appId: '1:577453832706:android:61ddedba226e73f8d2c51b',
    messagingSenderId: '577453832706',
    projectId: 'omni-ff2a3',
    storageBucket: 'omni-ff2a3.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArRxDfRc4xQIXdwWb0WSe_Yano18aaBDU',
    appId: '1:577453832706:ios:8f1e35574ca259efd2c51b',
    messagingSenderId: '577453832706',
    projectId: 'omni-ff2a3',
    storageBucket: 'omni-ff2a3.appspot.com',
    iosBundleId: 'com.example.omni',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyArRxDfRc4xQIXdwWb0WSe_Yano18aaBDU',
    appId: '1:577453832706:ios:8f1e35574ca259efd2c51b',
    messagingSenderId: '577453832706',
    projectId: 'omni-ff2a3',
    storageBucket: 'omni-ff2a3.appspot.com',
    iosBundleId: 'com.example.omni',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB9LTumYw73dVv-soVfy7x3z5uUvvbKbuk',
    appId: '1:577453832706:web:1aa67b5d53643283d2c51b',
    messagingSenderId: '577453832706',
    projectId: 'omni-ff2a3',
    authDomain: 'omni-ff2a3.firebaseapp.com',
    storageBucket: 'omni-ff2a3.appspot.com',
    measurementId: 'G-GGD6CP2YVW',
  );
}
