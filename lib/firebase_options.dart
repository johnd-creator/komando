// File generated from google-services.json
// DO NOT edit manually — re-generate when google-services.json changes.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyARCdm_-2bJ0GHZcjYAFQbRg65uYZ6zNxk',
    appId: '1:479016220889:android:ab503658fc7f9f64eea6c8',
    messagingSenderId: '479016220889',
    projectId: 'komando-5c534',
    storageBucket: 'komando-5c534.firebasestorage.app',
  );
}
