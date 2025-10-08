import 'package:cloud_firestore/cloud_firestore.dart';

class FriendModel {
  final String id;
  final String user1;
  final String user2;
  final String status;
  final DateTime? createdAt;

  FriendModel({
    required this.id,
    required this.user1,
    required this.user2,
    required this.status,
    this.createdAt,
  });

  /// 🔹 Convert Firestore → Dart object
  factory FriendModel.fromMap(String id, Map<String, dynamic> map) {
    return FriendModel(
      id: id,
      user1: map['user1'] ?? '',
      user2: map['user2'] ?? '',
      status: map['status'] ?? 'accepted',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// 🔹 Convert Dart object → Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'user1': user1,
      'user2': user2,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
