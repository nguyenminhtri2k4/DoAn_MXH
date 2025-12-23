
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_notification.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/notification_request.dart';
import 'package:mangxahoi/view/profile/profile_view.dart';
import 'package:mangxahoi/view/post/post_detail_view.dart'; // 🔥 Import PostDetailView

class NotificationViewModel extends ChangeNotifier {
  final UserRequest _userRequest = UserRequest();
  final NotificationRequest _notificationRequest = NotificationRequest();

  String? _realUserDocId;

  Stream<List<NotificationModel>> get notificationsStream async* {
    final String authUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (authUid.isEmpty) {
      yield [];
      return;
    }

    if (_realUserDocId == null) {
      final userModel = await _userRequest.getUserByUid(authUid);
      if (userModel == null) {
        print('❌ [VM] Không tìm thấy User với UID: $authUid');
        yield [];
        return;
      }
      _realUserDocId = userModel.id;
      print('✅ [VM] Đã xác định User DocID: $_realUserDocId');
    }

    yield* _notificationRequest.getNotificationsStream(_realUserDocId!);
  }

  // --- CÁC HÀM XỬ LÝ ---

  Future<void> markAsRead(String notificationId) async {
    await _notificationRequest.markAsRead(notificationId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationRequest.deleteNotification(notificationId);
  }

  Future<void> deleteAllNotifications() async {
    if (_realUserDocId != null) {
      await _notificationRequest.deleteAllNotifications(_realUserDocId!);
      debugPrint("🗑️ Đã xóa sạch thông báo");
    }
  }

  Future<void> markAllAsRead() async {
    if (_realUserDocId != null) {
      await _notificationRequest.markAllAsRead(_realUserDocId!);
      debugPrint("✅ Đã đánh dấu tất cả thông báo là đã đọc");
    }
  }

  // 🔥 XỬ LÝ KHI NHẤN VÀO NỘI DUNG THÔNG BÁO
  void handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) {
    // Đánh dấu đã đọc
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    print(
      "👉 Tap nội dung thông báo - Type: ${notification.type}, TargetType: ${notification.targetType}",
    );

    // Điều hướng dựa trên targetType
    if (notification.targetType == 'post') {
      // 🔥 Điều hướng đến PostDetailView
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailView(postId: notification.targetId),
        ),
      );
      print('✅ [Handle] Mở Post: ${notification.targetId}');
    } else if (notification.targetType == 'request') {
      // Điều hướng đến danh sách friend request (bỏ comment nếu chưa có)
      // Navigator.pushNamed(context, '/friend_requests');
      print('✅ [Handle] Mở Friend Requests');
    } else if (notification.targetType == 'user') {
      // Mở profile người gửi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileView(userId: notification.fromUserId),
        ),
      );
      print('✅ [Handle] Mở Profile: ${notification.fromUserId}');
    }
  }

  // 🔥 XỬ LÝ KHI NHẤN VÀO AVATAR -> Luôn mở Profile người gửi
  void handleAvatarTap(BuildContext context, String fromUserId) {
    if (fromUserId.isEmpty) return;
    print("👉 Tap Avatar -> Mở Profile User: $fromUserId");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileView(userId: fromUserId)),
    );
  }

  String formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()} tháng trước";
    return "${diff.inDays} ngày trước";
  }
}
