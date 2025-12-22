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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDRHFTnBo3H17LPrHJveMU46TBHUDxAyvo',
    appId: '1:931957871165:web:48d8117474cc69e3709054',
    messagingSenderId: '931957871165',
    projectId: 'musafirah-app',
    authDomain: 'musafirah-app.firebaseapp.com',
    storageBucket: 'musafirah-app.firebasestorage.app',
    measurementId: 'G-R4W5JJRH1D',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDRHFTnBo3H17LPrHJveMU46TBHUDxAyvo',
    appId: '1:931957871165:android:48d8117474cc69e3709054',
    messagingSenderId: '931957871165',
    projectId: 'musafirah-app',
    storageBucket: 'musafirah-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDRHFTnBo3H17LPrHJveMU46TBHUDxAyvo',
    appId: '1:931957871165:ios:48d8117474cc69e3709054',
    messagingSenderId: '931957871165',
    projectId: 'musafirah-app',
    storageBucket: 'musafirah-app.firebasestorage.app',
    iosBundleId: 'com.musafirah.app',
  );
}
