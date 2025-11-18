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
  final String title;
  final String content;
  final String fromUserName;
  final String fromUserAvatar;

  NotificationModel({
    required this.id,
    required this.fromUserId,
    required this.userId,
    required this.type,
    required this.targetId,
    required this.targetType,
    required this.isRead,
    required this.createdAt,
    required this.title,
    required this.content,
    required this.fromUserName,
    required this.fromUserAvatar,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 🔥 Hàm xử lý an toàn cho Avatar: Chấp nhận cả String lẫn List
    String parseAvatar(dynamic value) {
      if (value is String) return value; // Nếu là String thì dùng luôn
      if (value is List && value.isNotEmpty) {
        return value.first.toString(); // Nếu là List thì lấy phần tử đầu
      }
      return ''; // Còn lại trả về rỗng
    }

    return NotificationModel(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      fromUserAvatar: parseAvatar(data['fromUserAvatar']), // 🔥 Dùng hàm parse an toàn
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromUserId': fromUserId,
      'userId': userId,
      'type': type,
      'targetId': targetId,
      'targetType': targetType,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'title': title,
      'content': content,
      'fromUserName': fromUserName,
      'fromUserAvatar': fromUserAvatar,
    };
  }
}