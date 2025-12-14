// lib/request/comment_reaction_request.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentReactionRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final String _postCollection = 'Post';
  final String _commentSubcollection = 'comments';
  final String _reactionSubcollection = 'reactions';

  CollectionReference _getCommentsCollection(String postId) {
    return _firestore.collection(_postCollection).doc(postId).collection(_commentSubcollection);
  }

  /// Lấy loại reaction hiện tại của user cho một comment
  Future<String?> getUserReactionType(String postId, String commentId, String userDocId) async {
    try {
      final doc = await _getCommentsCollection(postId)
          .doc(commentId)
          .collection(_reactionSubcollection)
          .doc(userDocId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['type'] as String?;
      }
      return null;
    } catch (e) {
      print("❌ Lỗi khi lấy reaction comment: $e");
      return null;
    }
  }

  /// Đặt hoặc thay đổi reaction cho comment
  Future<void> setReaction(
    String postId,
    String commentId,
    String userDocId,
    String reactionType,
    String? oldReactionType,
  ) async {
    try {
      final commentRef = _getCommentsCollection(postId).doc(commentId);
      final reactionRef = commentRef.collection(_reactionSubcollection).doc(userDocId);
      final batch = _firestore.batch();

      // 1. Thêm/Cập nhật document reaction của user
      batch.set(reactionRef, {
        'type': reactionType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Tăng đếm cho reaction mới
      batch.update(commentRef, {
        'reactionsCount.$reactionType': FieldValue.increment(1),
      });

      // 3. Giảm đếm cho reaction cũ (nếu có và khác reaction mới)
      if (oldReactionType != null && oldReactionType != reactionType) {
        batch.update(commentRef, {
          'reactionsCount.$oldReactionType': FieldValue.increment(-1),
        });
      }

      await batch.commit();
      print('✅ Comment reaction đã được cập nhật: $reactionType');
    } catch (e) {
      print('❌ Lỗi khi set comment reaction: $e');
      rethrow;
    }
  }

  /// Xóa reaction từ comment
  Future<void> removeReaction(
    String postId,
    String commentId,
    String userDocId,
    String oldReactionType,
  ) async {
    try {
      final commentRef = _getCommentsCollection(postId).doc(commentId);
      final reactionRef = commentRef.collection(_reactionSubcollection).doc(userDocId);
      final batch = _firestore.batch();

      // 1. Xóa document reaction
      batch.delete(reactionRef);

      // 2. Giảm đếm reaction cũ
      batch.update(commentRef, {
        'reactionsCount.$oldReactionType': FieldValue.increment(-1),
      });

      await batch.commit();
      print('✅ Comment reaction đã được xóa');
    } catch (e) {
      print('❌ Lỗi khi xóa comment reaction: $e');
      rethrow;
    }
  }

  /// Stream lắng nghe tất cả reactions của một comment
  Stream<QuerySnapshot> getReactionsStream(String postId, String commentId) {
    return _getCommentsCollection(postId)
        .doc(commentId)
        .collection(_reactionSubcollection)
        .snapshots();
  }

  /// Stream lắng nghe reaction của user cụ thể trên comment
  Stream<DocumentSnapshot> getUserReactionStream(
    String postId,
    String commentId,
    String userDocId,
  ) {
    return _getCommentsCollection(postId)
        .doc(commentId)
        .collection(_reactionSubcollection)
        .doc(userDocId)
        .snapshots();
  }
}