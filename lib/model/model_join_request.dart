import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequestModel {
  final String id;
  final String groupId;
  final String userId;
  final DateTime createdAt;
  final String status; // 'pending', 'approved', 'rejected'

  JoinRequestModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.createdAt,
    this.status = 'pending',
  });

  factory JoinRequestModel.fromMap(String id, Map<String, dynamic> map) {
    return JoinRequestModel(
      id: id,
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'userId': userId,
      'createdAt': createdAt,
      'status': status,
    };
  }
}