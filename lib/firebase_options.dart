// lib/firebase_options.dart
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web configuration (already in your index.html)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBKpBi8e5Gu6KxItFOP88sNDHG5S4Cg4_U',
    authDomain: 'addisrent-d27f4.firebaseapp.com',
    projectId: 'addisrent-d27f4',
    storageBucket: 'addisrent-d27f4.firebasestorage.app',
    messagingSenderId: '780568866636',
    appId: '1:780568866636:web:672403ca486b2ae91d69e9',
    measurementId: 'G-R733V4MSTC',
  );

  // Android configuration (from your google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB4NlWrAnFIFV0tUwefJhR7ux0wanbZXQo', // From google-services.json
    appId: '1:780568866636:android:49c684d4ffdb877a1d69e9', // From google-services.json
    messagingSenderId: '780568866636', // From google-services.json
    projectId: 'addisrent-d27f4', // From google-services.json
    storageBucket: 'addisrent-d27f4.firebasestorage.app', // From google-services.json
  );

  // iOS configuration (from your GoogleService-Info.plist)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjSGtpoB2nRcWwuSVrVWyJGLmjA1e4qD4', // From GoogleService-Info.plist
    appId: '1:780568866636:ios:c4ed2eac268953c81d69e9', // From GoogleService-Info.plist
    messagingSenderId: '780568866636', // From GoogleService-Info.plist
    projectId: 'addisrent-d27f4', // From GoogleService-Info.plist
    storageBucket: 'addisrent-d27f4.firebasestorage.app', // From GoogleService-Info.plist
    iosBundleId: 'com.example.addisRent', // From GoogleService-Info.plist
    iosClientId: '780568866636-qaml1k1gp17090ek782h90c3qj3cnes4.apps.googleusercontent.com', // For Google Sign-In
  );
}