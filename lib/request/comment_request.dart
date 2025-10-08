// // lib/request/comment_request.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mangxahoi/model/model_comment.dart';

// class CommentRequest {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String _postCollection = 'Post';

//   // Lấy subcollection comments của một bài viết
//   CollectionReference _getCommentsCollection(String postId) {
//     return _firestore.collection(_postCollection).doc(postId).collection('comments');
//   }

//   // Thêm một bình luận
//   Future<void> addComment(String postId, CommentModel comment) async {
//     await _getCommentsCollection(postId).add(comment.toMap());
//     // Tăng số lượng bình luận trong bài viết
//     await _firestore.collection(_postCollection).doc(postId).update({
//       'commentsCount': FieldValue.increment(1),
//     });
//   }

//   // Lấy danh sách bình luận (dạng stream để tự động cập nhật)
//   Stream<List<CommentModel>> getComments(String postId) {
//     return _getCommentsCollection(postId)
//         .orderBy('createdAt', descending: false)
//         .snapshots()
//         .map((snapshot) {
//       return snapshot.docs
//           .map((doc) => CommentModel.fromDoc(postId, doc))
//           .toList();
//     });
//   }
// }
// lib/request/comment_request.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_comment.dart';

class CommentRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _postCollection = 'Post';

  CollectionReference _getCommentsCollection(String postId) {
    return _firestore.collection(_postCollection).doc(postId).collection('comments');
  }

  Future<void> addComment(String postId, CommentModel comment) async {
    // Dùng toMap() để đảm bảo lưu đúng cấu trúc
    await _getCommentsCollection(postId).add(comment.toMap());
    
    // Tăng số lượng bình luận trên bài viết
    await _firestore.collection(_postCollection).doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });

    // Nếu đây là reply, tăng số reply trên comment cha
    if (comment.parentCommentId != null && comment.parentCommentId!.isNotEmpty) {
      await _getCommentsCollection(postId).doc(comment.parentCommentId).update({
        'commentsCount': FieldValue.increment(1),
      });
    }
  }

  Stream<List<CommentModel>> getComments(String postId) {
    return _getCommentsCollection(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CommentModel.fromDoc(postId, doc)).toList());
  }
}