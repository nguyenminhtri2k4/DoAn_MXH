
// Mẫu: lib/notification/push_notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import '../main.dart'; // Import file main.dart để sử dụng navigatorKey

// Hàm xử lý khi nhận thông báo lúc app đang tắt (Background)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 [BG] Nhận tin nhắn: ${message.notification?.title}");
}

class PushNotificationService {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Xin quyền
    await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    // 2. Khởi tạo Local Notification
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );
    
    // SỬ DỤNG API MỚI NHẤT: onDidReceiveNotificationResponse được truyền vào initialize
    // và sử dụng kiểu NotificationResponse mới
    await _localNotificationsPlugin.initialize(
        initSettings,
        // Dùng tham số mới với signature mới
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
            if (response.payload != null) {
                // Giải mã payload (là JSON string) và xử lý
                final Map<String, dynamic> data = jsonDecode(response.payload!);
                _handleNotificationData(data);
            }
        });

    // 3. Lắng nghe sự kiện
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // App đang mở (Foreground)
    FirebaseMessaging.onMessage.listen(_showLocalNotification); 
    
    // Thao tác khi người dùng nhấn vào thông báo khi app đang ở trạng thái Terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }

    // Thao tác khi người dùng nhấn vào thông báo khi app đang ở trạng thái Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationData(message.data);
    });
  }

  // Hàm xử lý logic điều hướng chung
  void _handleNotificationData(Map<String, dynamic> data) {
    // Kiểm tra xem có action dành riêng cho chat không (được gửi từ Cloud Function)
    if (data['click_action'] == 'FLUTTER_NOTIFICATION_CLICK_CHAT' && data.containsKey('chatId')) {
      final String chatId = data['chatId'];
      final String chatName = data['chatName'] ?? '';
      
      // Điều hướng đến màn hình Chat (sử dụng navigatorKey từ main.dart)
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed(
          '/chat',
          arguments: {
            'chatId': chatId,
            'chatName': chatName,
          },
        );
        print('✅ [Click] Điều hướng đến ChatID: $chatId');
      } else {
        print('❌ [Click] Lỗi navigatorKey.currentState null.');
      }
    } else if (data['click_action'] == 'FLUTTER_NOTIFICATION_CLICK') {
        // Xử lý logic cho các loại thông báo khác (thông báo chung)
        if (navigatorKey.currentState != null && data.containsKey('targetId')) {
           // Thêm logic điều hướng thông báo chung tại đây
           print('✅ [Click] Điều hướng đến thông báo chung: ${data['targetId']}');
        }
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    print("🔔 [FCM] Đã nhận thông báo trong Foreground!");
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