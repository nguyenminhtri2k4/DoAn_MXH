import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_notification.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/notification_request.dart';
import 'package:mangxahoi/view/profile/profile_view.dart'; // 🔥 Import ProfileView
// import 'package:mangxahoi/view/friend_request_view.dart';
// import 'package:mangxahoi/view/post/post_detail_view.dart';

class NotificationViewModel extends ChangeNotifier {
  final UserRequest _userRequest = UserRequest();
  final NotificationRequest _notificationRequest = NotificationRequest();

  // Cache ID người dùng thực để dùng cho các hàm xóa/đọc
  String? _realUserDocId;

  // 1. Stream lấy danh sách thông báo
  Stream<List<NotificationModel>> get notificationsStream async* {
    final String authUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (authUid.isEmpty) {
      yield [];
      return;
    }

    // Nếu chưa có ID thực, đi lấy từ UserRequest
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

    // Gọi Stream từ NotificationRequest
    yield* _notificationRequest.getNotificationsStream(_realUserDocId!);
  }

  // --- CÁC HÀM XỬ LÝ ---

  Future<void> markAsRead(String notificationId) async {
    await _notificationRequest.markAsRead(notificationId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationRequest.deleteNotification(notificationId);
  }

  // Xóa tất cả
  Future<void> deleteAllNotifications() async {
    if (_realUserDocId != null) {
      await _notificationRequest.deleteAllNotifications(_realUserDocId!);
      debugPrint("🗑️ Đã xóa sạch thông báo");
    }
  }

  // 2. Xử lý khi nhấn vào nội dung thông báo
  void handleNotificationTap(BuildContext context, NotificationModel notification) {
    if (!notification.isRead) {
      markAsRead(notification.id);
    }
    print("👉 Tap nội dung thông báo loại: ${notification.targetType}");
    
    // Logic điều hướng (Bỏ comment và import file tương ứng)
    if (notification.targetType == 'request') {
      // Navigator.pushNamed(context, '/friend_requests');
      // Hoặc: Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendRequestView()));
    } else if (notification.targetType == 'user' || notification.type == 'accept_friend') {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileView(userId: notification.targetId)));
    } else if (notification.targetType == 'post') {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailView(postId: notification.targetId)));
    }
  }

  // 3. 🔥 Xử lý khi nhấn vào AVATAR -> Luôn mở Profile người gửi
  void handleAvatarTap(BuildContext context, String fromUserId) {
    if (fromUserId.isEmpty) return;
    print("👉 Tap Avatar -> Mở Profile User: $fromUserId");
    
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => ProfileView(userId: fromUserId))
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