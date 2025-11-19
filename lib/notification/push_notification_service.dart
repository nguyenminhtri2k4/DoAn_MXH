// Mẫu: lib/notification/push_notification_service.dart
// (Đây là file quản lý việc lắng nghe và hiển thị thông báo)

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

// Hàm xử lý khi nhận thông báo lúc app đang tắt (Background)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 [BG] Nhận tin nhắn: ${message.notification?.title}");
}

class PushNotificationService {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Xin quyền
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    // 2. Khởi tạo Local Notification
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInitSettings);
    await _localNotificationsPlugin.initialize(initSettings);

    // 3. Lắng nghe sự kiện
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_showLocalNotification); // App đang mở
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // Phải khớp với Channel ID trong code Node.js
            'Thông báo MXH',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}