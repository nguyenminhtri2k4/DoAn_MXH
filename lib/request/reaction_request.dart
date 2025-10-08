
// // lib/request/reaction_request.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mangxahoi/model/model_reaction.dart';

// class ReactionRequest {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String _postCollection = 'Post';

//   CollectionReference _getReactionsCollection(String postId) {
//     return _firestore.collection(_postCollection).doc(postId).collection('reactions');
//   }

//   Future<void> addLike(String postId, String userDocId) async {
//     // 1. Tạo đối tượng ReactionModel đầy đủ
//     final newReaction = ReactionModel(
//       id: userDocId,
//       postId: postId,
//       userId: userDocId, // Sử dụng userDocId
//       type: 'like',
//       time: DateTime.now(),
//     );

//     // 2. Dùng toMap() để lưu đúng cấu trúc với trường 'userId'
//     await _getReactionsCollection(postId).doc(userDocId).set(newReaction.toMap());

//     // 3. Tăng số lượt thích
//     await _firestore.collection(_postCollection).doc(postId).update({
//       'likesCount': FieldValue.increment(1),
//     });
//   }

//   Future<void> removeLike(String postId, String userDocId) async {
//     await _getReactionsCollection(postId).doc(userDocId).delete();
//     await _firestore.collection(_postCollection).doc(postId).update({
//       'likesCount': FieldValue.increment(-1),
//     });
//   }

//   Future<bool> hasUserLikedPost(String postId, String userDocId) async {
//     final doc = await _getReactionsCollection(postId).doc(userDocId).get();
//     return doc.exists;
//   }
// }
// lib/request/reaction_request.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_reaction.dart';

class ReactionRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _postCollection = 'Post';

  CollectionReference _getReactionsCollection(String postId) {
    return _firestore.collection(_postCollection).doc(postId).collection('reactions');
  }

  Future<void> addLike(String postId, String userDocId) async {
    final newReaction = ReactionModel(
      id: userDocId,
      authorId: userDocId,
      type: 'like',
      time: DateTime.now(),
    );
    await _getReactionsCollection(postId).doc(userDocId).set(newReaction.toMap());
    await _firestore.collection(_postCollection).doc(postId).update({
      'likesCount': FieldValue.increment(1),
    });
  }

  Future<void> removeLike(String postId, String userDocId) async {
    await _getReactionsCollection(postId).doc(userDocId).delete();
    await _firestore.collection(_postCollection).doc(postId).update({
      'likesCount': FieldValue.increment(-1),
    });
  }

  Future<bool> hasUserLikedPost(String postId, String userDocId) async {
    if (userDocId.isEmpty) return false;
    final doc = await _getReactionsCollection(postId).doc(userDocId).get();
    return doc.exists;
  }
}