import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_notification.dart';

class NotificationRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'Notification';

  // 1. Gửi thông báo mới (Chuyển từ FriendRequestManager sang đây)
  Future<void> sendNotification({
    required String fromUserId,
    required String toUserId,
    required String type,
    required String title,
    required String content,
    required String targetId,
    required String targetType,
    required String fromUserName,
    required String fromUserAvatar,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();

      final notification = NotificationModel(
        id: docRef.id,
        fromUserId: fromUserId,
        userId: toUserId,
        type: type,
        targetId: targetId,
        targetType: targetType,
        isRead: false,
        createdAt: DateTime.now(),
        title: title,
        content: content,
        fromUserName: fromUserName,
        fromUserAvatar: fromUserAvatar,
      );

      await docRef.set(notification.toJson());
      print("✅ [NotificationRequest] Đã gửi thông báo: $title");
    } catch (e) {
      print('❌ [NotificationRequest] Lỗi khi gửi thông báo: $e');
      rethrow;
    }
  }

  // 2. Stream lấy danh sách thông báo theo userId (DocId)
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromDoc(doc))
            .toList());
  }

  // 3. Đánh dấu đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print("❌ Lỗi markAsRead: $e");
      rethrow;
    }
  }

  // 4. Xóa 1 thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print("❌ Lỗi deleteNotification: $e");
      rethrow;
    }
  }

  // 5. Xóa tất cả thông báo của User (Dùng Batch)
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return;

      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;

        if (count >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }
    } catch (e) {
      print("❌ Lỗi deleteAllNotifications: $e");
      rethrow;
    }
  }
}