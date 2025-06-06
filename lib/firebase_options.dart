// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBIpvHofJm9AuvcTU8GOB2UmK_iRztsOEc',
    appId: '1:59259575711:web:879b5f6952b2380dcaf1aa',
    messagingSenderId: '59259575711',
    projectId: 'ecocircuit-a0628',
    authDomain: 'ecocircuit-a0628.firebaseapp.com',
    storageBucket: 'ecocircuit-a0628.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyByadLOfGUI987-URnT5Aiv-mVOODLVgmY',
    appId: '1:59259575711:android:dae3b3063dfbef4bcaf1aa',
    messagingSenderId: '59259575711',
    projectId: 'ecocircuit-a0628',
    storageBucket: 'ecocircuit-a0628.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBIpvHofJm9AuvcTU8GOB2UmK_iRztsOEc',
    appId: '1:59259575711:web:dd44cbfd8b6ff4efcaf1aa',
    messagingSenderId: '59259575711',
    projectId: 'ecocircuit-a0628',
    authDomain: 'ecocircuit-a0628.firebaseapp.com',
    storageBucket: 'ecocircuit-a0628.firebasestorage.app',
  );
}
