
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

  // Web configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyC9gOmEocUr4vJlqhmfU0sjF26o74ck6nU",
    appId: "1:55399679019:web:963c4da83e821e7debd66e",
    messagingSenderId: "55399679019",
    projectId: "doanmxh-1015e",
    authDomain: "doanmxh-1015e.firebaseapp.com",
    databaseURL: "https://doanmxh-1015e-default-rtdb.asia-southeast1.firebasedatabase.app",
    storageBucket: "doanmxh-1015e.firebasestorage.app",
    measurementId: "G-GPMN1MDDFC"
  );

  // Android configuration (từ file google-services.json của bạn)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAyX-4sSM3WybAG1C1LNnPRcjqiYb1KjK8",
    appId: "1:55399679019:android:d60be671725672b6ebd66e",
    messagingSenderId: "55399679019",
    projectId: "doanmxh-1015e",
    databaseURL: "https://doanmxh-1015e-default-rtdb.asia-southeast1.firebasedatabase.app",
    storageBucket: "doanmxh-1015e.firebasestorage.app",
  );

  // iOS configuration (thêm khi bạn có iOS app)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "YOUR_IOS_API_KEY", // Sẽ cần thêm khi làm iOS
    appId: "YOUR_IOS_APP_ID",
    messagingSenderId: "55399679019",
    projectId: "doanmxh-1015e",
    databaseURL: "https://doanmxh-1015e-default-rtdb.asia-southeast1.firebasedatabase.app",
    storageBucket: "doanmxh-1015e.firebasestorage.app",
    iosBundleId: "com.example.mangxahoi",
  );
}