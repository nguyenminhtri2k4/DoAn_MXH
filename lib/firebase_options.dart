// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Dữ liệu từ firebaseConfig của bạn
      return const FirebaseOptions(
        apiKey: "AIzaSyC9gOmEocUr4vJlqhmfU0sjF26o74ck6nU",
        appId: "1:55399679019:web:963c4da83e821e7debd66e",
        messagingSenderId: "55399679019",
        projectId: "doanmxh-1015e",
        authDomain: "doanmxh-1015e.firebaseapp.com",
        databaseURL: "https://doanmxh-1015e-default-rtdb.asia-southeast1.firebasedatabase.app",
        storageBucket: "doanmxh-1015e.firebasestorage.app", // Sử dụng giá trị bạn cung cấp
        measurementId: "G-GPMN1MDDFC"
      );
    }

    // Các nền tảng khác (Android/iOS) sẽ tự động dùng file JSON/PList
    // Bạn không cần sửa phần dưới này
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'Android sẽ tự động dùng file google-services.json.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'iOS sẽ tự động dùng file GoogleService-Info.plist.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}