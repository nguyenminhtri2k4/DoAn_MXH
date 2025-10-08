import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUserModel {
  final String id; // id của document trong subcollection blocks
  final String blockedId;
  final String reason;

  BlockedUserModel({
    required this.id,
    required this.blockedId,
    required this.reason,
  });

  factory BlockedUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BlockedUserModel(
      id: doc.id,
      blockedId: data['blockedId'] ?? '',
      reason: data['reason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blockedId': blockedId,
      'reason': reason,
    };
  }
}
