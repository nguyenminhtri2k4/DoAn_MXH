
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String content;
  final DateTime createdAt;
  final List<String> mediaIds;
  final String senderId;
  final String status;
  final String type; // 'text' hoặc 'share_post'
  final String? sharedPostId; // ID của bài viết được chia sẻ

  MessageModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.mediaIds,
    required this.senderId,
    required this.status,
    this.type = 'text', // Mặc định là tin nhắn văn bản
    this.sharedPostId,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      mediaIds: List<String>.from(map['mediaIds'] ?? []),
      senderId: map['senderId'] ?? '',
      status: map['status'] ?? 'sent',
      type: map['type'] ?? 'text',
      sharedPostId: map['sharedPostId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'mediaIds': mediaIds,
      'senderId': senderId,
      'status': status,
      'type': type,
      if (sharedPostId != null) 'sharedPostId': sharedPostId,
    };
  }
}