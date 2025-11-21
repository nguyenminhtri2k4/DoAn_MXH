import 'package:cloud_firestore/cloud_firestore.dart';

class DisbandedGroupModel {
  final String id; // Document ID (thường là groupId)
  final String groupId;
  final String name;
  final String type; // 'chat' hoặc 'post'
  final DateTime? disbandedAt;

  DisbandedGroupModel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.type,
    this.disbandedAt,
  });

  factory DisbandedGroupModel.fromMap(String id, Map<String, dynamic> map) {
    return DisbandedGroupModel(
      id: id,
      groupId: map['groupId'] ?? '',
      name: map['name'] ?? 'Nhóm không xác định',
      type: map['type'] ?? 'chat',
      disbandedAt:
          map['disbandedAt'] != null
              ? (map['disbandedAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'name': name,
      'type': type,
      'disbandedAt':
          disbandedAt != null
              ? Timestamp.fromDate(disbandedAt!)
              : FieldValue.serverTimestamp(),
    };
  }
}
