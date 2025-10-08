import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String fromUserId;
  final String userId;
  final String type;
  final String targetId;
  final String targetType;
  final bool isRead;
  final DateTime createdAt;

  // (Tùy chọn — giúp hiển thị nhanh mà không cần fetch user)
  final String? fromUserName;
  final String? fromUserAvatar;

  NotificationModel({
    required this.id,
    required this.fromUserId,
    required this.userId,
    required this.type,
    required this.targetId,
    required this.targetType,
    required this.isRead,
    required this.createdAt,
    this.fromUserName,
    this.fromUserAvatar,
  });

  /// Parse từ Firestore DocumentSnapshot
  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      fromUserName: data['fromUserName'],
      fromUserAvatar: data['fromUserAvatar'],
    );
  }

  /// Convert sang JSON để lưu Firestore
  Map<String, dynamic> toJson() {
    return {
      'fromUserId': fromUserId,
      'userId': userId,
      'type': type,
      'targetId': targetId,
      'targetType': targetType,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      if (fromUserName != null) 'fromUserName': fromUserName,
      if (fromUserAvatar != null) 'fromUserAvatar': fromUserAvatar,
    };
  }
}
