
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import '../main.dart'; // navigatorKey

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 [BG] Nhận tin nhắn: ${message.notification?.title}");
}

class PushNotificationService {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Xin quyền
    await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    // Khởi tạo Local Notification
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );
    
    await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
            if (response.payload != null) {
                final Map<String, dynamic> data = jsonDecode(response.payload!);
                _handleNotificationData(data);
            }
        });

    // Xử lý nền
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Foreground
    FirebaseMessaging.onMessage.listen(_showLocalNotification); 
    
    // Terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }

    // Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationData(message.data);
    });
  }

  // ✅ PHẦN XỬ LÝ CHÍNH (ĐÃ SỬA)
  void _handleNotificationData(Map<String, dynamic> data) {
    print("🔔 [Handle] Data: $data");

    if (navigatorKey.currentState == null) {
      print('❌ navigatorKey.currentState null');
      return;
    }

    final clickAction = data['click_action'];
    
    // === Case 1: Chat Message ===
    if (clickAction == 'FLUTTER_NOTIFICATION_CLICK_CHAT' && 
        data.containsKey('chatId')) {
      final String chatId = data['chatId'];
      final String chatName = data['chatName'] ?? '';
      
      navigatorKey.currentState!.pushNamed(
        '/chat',
        arguments: {
          'chatId': chatId,
          'chatName': chatName,
        },
      );
      print('✅ [Click] Điều hướng đến Chat: $chatId');
    }
    // === Case 2: Post Activity (Like/Comment) ===
    else if (clickAction == 'FLUTTER_NOTIFICATION_CLICK' && 
             data.containsKey('targetId') &&
             data['targetType'] == 'post') {
      final String postId = data['targetId'];
      
      navigatorKey.currentState!.pushNamed(
        '/post_detail',
        arguments: postId,
      );
      print('✅ [Click] Điều hướng đến Post: $postId');
    }
    // === Case 3: Thông báo chung khác ===
    else if (clickAction == 'FLUTTER_NOTIFICATION_CLICK') {
      if (data.containsKey('targetId')) {
        print('✅ [Click] Thông báo chung: ${data['targetId']}');
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
            'high_importance_channel',
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