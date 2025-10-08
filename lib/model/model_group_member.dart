import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMemberModel {
  final String id;
  final String role; // admin | member | moderator
  final DateTime? joinedAt;

  GroupMemberModel({
    required this.id,
    required this.role,
    this.joinedAt,
  });

  /// Firestore → Dart
  factory GroupMemberModel.fromMap(String id, Map<String, dynamic> map) {
    return GroupMemberModel(
      id: id,
      role: map['role'] ?? 'member',
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Dart → Firestore
  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'joinedAt': joinedAt ?? FieldValue.serverTimestamp(),
    };
  }
}
