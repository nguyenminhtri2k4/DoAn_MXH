// lib/model/model_chat.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String lastMessage;
  final List<String> members;
  final String type; // 'private' or 'group'
  final DateTime updatedAt;
  final String status; // Thêm trường status

  ChatModel({
    required this.id,
    required this.lastMessage,
    required this.members,
    required this.type,
    required this.updatedAt,
    this.status = 'active', // Gán giá trị mặc định
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      lastMessage: map['lastMessage'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      type: map['type'] ?? 'private',
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'active', // Đọc giá trị status
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lastMessage': lastMessage,
      'members': members,
      'type': type,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status, // Ghi giá trị status
    };
  }
}