// 📄 lib/services/notification_badge_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/notification_request.dart';

class NotificationBadgeService extends ChangeNotifier {
  final UserRequest _userRequest = UserRequest();
  final NotificationRequest _notificationRequest = NotificationRequest();
  
  int _unreadCount = 0;
  String? _realUserDocId;
  
  int get unreadCount => _unreadCount;
  
  NotificationBadgeService() {
    _initUnreadCountStream();
  }
  
  void _initUnreadCountStream() async {
    final String authUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    if (authUid.isEmpty) return;
    
    // Lấy User DocID từ UID
    if (_realUserDocId == null) {
      try {
        final userModel = await _userRequest.getUserByUid(authUid);
        if (userModel != null) {
          _realUserDocId = userModel.id;
          print('✅ [NotificationBadgeService] User DocID: $_realUserDocId');
        }
      } catch (e) {
        print('❌ [NotificationBadgeService] Lỗi lấy User: $e');
      }
    }
  }
  
  // 🔥 Stream đếm thông báo chưa đọc - thay đổi real-time
  Stream<int> getUnreadCountStream() async* {
    final String authUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    if (authUid.isEmpty) {
      yield 0;
      return;
    }
    
    // Nếu chưa có User DocID, lấy nó
    if (_realUserDocId == null) {
      try {
        final userModel = await _userRequest.getUserByUid(authUid);
        if (userModel == null) {
          print('❌ [NotificationBadgeService] Không tìm thấy User');
          yield 0;
          return;
        }
        _realUserDocId = userModel.id;
        print('✅ [NotificationBadgeService] Đã xác định User DocID: $_realUserDocId');
      } catch (e) {
        print('❌ [NotificationBadgeService] Lỗi khi lấy User: $e');
        yield 0;
        return;
      }
    }
    
    // 🔥 Lắng nghe stream thông báo và đếm những thông báo chưa đọc
    yield* _notificationRequest.getNotificationsStream(_realUserDocId!).map((notifications) {
      final unread = notifications.where((n) => !n.isRead).length;
      _unreadCount = unread;
      
      print('🔔 [NotificationBadgeService] Số thông báo chưa đọc: $unread');
      
      notifyListeners(); // Thông báo cho UI cập nhật
      return unread;
    });
  }
  
  // Hàm tiện ích: Cập nhật count khi đánh dấu đã đọc
  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }
  
  // Hàm tiện ích: Reset count
  void resetUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }
}