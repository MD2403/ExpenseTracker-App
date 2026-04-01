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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCZtzuWE3WMcudabC1udglWutIcDb-RwQI',
    appId: '1:450741866783:web:a86069dbf29860a649602a',
    messagingSenderId: '450741866783',
    projectId: 'expensetracker-dfab6',
    authDomain: 'expensetracker-dfab6.firebaseapp.com',
    storageBucket: 'expensetracker-dfab6.firebasestorage.app',
    measurementId: 'G-LD9YPMT7VZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZtzuWE3WMcudabC1udglWutIcDb-RwQI',
    appId: '1:450741866783:android:a86069dbf29860a649602a',
    messagingSenderId: '450741866783',
    projectId: 'expensetracker-dfab6',
    storageBucket: 'expensetracker-dfab6.firebasestorage.app',
  );
}