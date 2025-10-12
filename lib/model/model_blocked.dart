import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUserModel {
  final String id;
  final String blockedId;
  final String reason;
  final String status; // 'active' hoặc 'inactive'

  BlockedUserModel({
    required this.id,
    required this.blockedId,
    required this.reason,
    this.status = 'active',
  });

  factory BlockedUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BlockedUserModel(
      id: doc.id,
      blockedId: data['blockedId'] ?? '',
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blockedId': blockedId,
      'reason': reason,
      'status': status,
    };
  }
}