// lib/models/reaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReactionModel {
  final String id;
  final String postId;
  final String userId;
  final String type; // like | love | haha | ...
  final DateTime time;

  ReactionModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.type,
    required this.time,
  });

  factory ReactionModel.fromDoc(String postId, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // trường tên user có thể khác (reacuser1 hoặc userId) => xử lý linh hoạt
    String uid = '';
    if (data.containsKey('userId')) uid = data['userId'] ?? '';
    else if (data.containsKey('reacuser1')) uid = data['reacuser1'] ?? '';
    else if (data.containsKey('reacUser')) uid = data['reacUser'] ?? '';
    else uid = '';

    return ReactionModel(
      id: doc.id,
      postId: postId,
      userId: uid,
      type: data['type'] ?? 'like',
      time: (data['time'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'time': Timestamp.fromDate(time),
    };
  }
}
