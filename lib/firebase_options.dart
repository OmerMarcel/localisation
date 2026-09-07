// File generated manually based on android/app/google-services.json for cross-platform Firebase support
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return ios;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        return web;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDPAKyaXFXOQUDrCADfMAOS3yPSRDvuHGI',
    appId: '1:191342105680:web:b0b1c69a2ba11b5819ed55',
    messagingSenderId: '191342105680',
    projectId: 'geoloc-cotonou',
    storageBucket: 'geoloc-cotonou.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPAKyaXFXOQUDrCADfMAOS3yPSRDvuHGI',
    appId: '1:191342105680:android:b0b1c69a2ba11b5819ed55',
    messagingSenderId: '191342105680',
    projectId: 'geoloc-cotonou',
    storageBucket: 'geoloc-cotonou.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDPAKyaXFXOQUDrCADfMAOS3yPSRDvuHGI',
    appId: '1:191342105680:ios:b0b1c69a2ba11b5819ed55',
    messagingSenderId: '191342105680',
    projectId: 'geoloc-cotonou',
    storageBucket: 'geoloc-cotonou.firebasestorage.app',
    iosBundleId: 'com.example.localisation',
  );
}
