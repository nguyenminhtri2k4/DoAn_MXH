import 'package:cloud_firestore/cloud_firestore.dart';

class FollowModel {
  final String followerId;
  final String followingId;
  final DateTime createdAt;
  final String status; // 'active', 'blocked', ...

  FollowModel({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
    this.status = 'active', // Mặc định là active
  });

  Map<String, dynamic> toMap() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': createdAt,
      'status': status,
    };
  }

  factory FollowModel.fromMap(Map<String, dynamic> map) {
    return FollowModel(
      followerId: map['followerId'] ?? '',
      followingId: map['followingId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'active',
    );
  }
}