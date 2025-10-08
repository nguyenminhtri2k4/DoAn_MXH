
// // lib/model/model_reaction.dart
// import 'package:cloud_firestore/cloud_firestore.dart';

// class ReactionModel {
//   final String id;
//   final String postId;
//   final String userId; // Sẽ dùng trường này nhất quán
//   final String type; // like | love | haha | ...
//   final DateTime time;

//   ReactionModel({
//     required this.id,
//     required this.postId,
//     required this.userId,
//     required this.type,
//     required this.time,
//   });

//   factory ReactionModel.fromDoc(String postId, DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
    
//     // Xử lý linh hoạt để đọc được cả dữ liệu cũ
//     String uid = data['userId'] ?? data['reacuser1'] ?? data['reacUser'] ?? '';

//     return ReactionModel(
//       id: doc.id,
//       postId: postId,
//       userId: uid,
//       type: data['type'] ?? 'like',
//       time: (data['time'] as Timestamp).toDate(),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId, // Luôn ghi ra trường 'userId'
//       'type': type,
//       'time': Timestamp.fromDate(time),
//     };
//   }
// }
// lib/model/model_reaction.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReactionModel {
  final String id;
  final String authorId; // <<< Thống nhất dùng authorId
  final String type;
  final DateTime time;

  ReactionModel({
    required this.id,
    required this.authorId,
    required this.type,
    required this.time,
  });

  factory ReactionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String uid = data['authorId'] ?? data['userId'] ?? data['reacuser1'] ?? '';

    return ReactionModel(
      id: doc.id,
      authorId: uid,
      type: data['type'] ?? 'like',
      time: (data['time'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId, // <<< Luôn ghi ra authorId
      'type': type,
      'time': Timestamp.fromDate(time),
    };
  }
}