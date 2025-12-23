
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_comment.dart';
import 'package:mangxahoi/request/post_activity_request.dart';

class CommentRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PostActivityRequest _postActivityRequest = PostActivityRequest();

  final String _postCollection = 'Post';
  final String _commentSubcollection = 'comments';

  CollectionReference _getCommentsCollection(String postId) {
    return _firestore
        .collection(_postCollection)
        .doc(postId)
        .collection(_commentSubcollection);
  }

  /// Thêm comment mới
  Future<void> addComment(String postId, CommentModel comment) async {
    try {
      // 1. Thêm comment vào Firestore
      final docRef = await _getCommentsCollection(postId).add(comment.toMap());
      print('✅ Comment đã được thêm: ${docRef.id}');

      // 2. Tăng số lượng bình luận trên bài viết
      await _firestore.collection(_postCollection).doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      // 3. Nếu là reply, tăng số reply trên comment cha
      if (comment.parentCommentId != null &&
          comment.parentCommentId!.isNotEmpty) {
        await _getCommentsCollection(postId)
            .doc(comment.parentCommentId)
            .update({'commentsCount': FieldValue.increment(1)});
      }

      // 🔥 GỬI THÔNG BÁO
      if (comment.parentCommentId == null || comment.parentCommentId!.isEmpty) {
        // Comment trực tiếp trên bài viết
        await _postActivityRequest.onCommentAdded(
          postId: postId,
          userId: comment.authorId,
          commentText: comment.content,
        );
      } else {
        // Reply comment - cần lấy thông tin comment cha
        final parentComment =
            await _getCommentsCollection(
              postId,
            ).doc(comment.parentCommentId).get();

        if (parentComment.exists) {
          // ✅ FIX: Cast sang Map<String, dynamic> trước khi truy cập []
          final parentData = parentComment.data() as Map<String, dynamic>?;
          final parentAuthorId = parentData?['authorId'] as String?;

          if (parentAuthorId != null) {
            await _postActivityRequest.onReplyAdded(
              postId: postId,
              userId: comment.authorId,
              parentCommentAuthorId: parentAuthorId,
              replyText: comment.content,
            );
          }
        }
      }
    } catch (e) {
      print('❌ Lỗi khi thêm comment: $e');
      rethrow;
    }
  }

  /// Stream lấy danh sách comment
  Stream<List<CommentModel>> getComments(String postId) {
    return _getCommentsCollection(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => CommentModel.fromDoc(postId, doc))
                  .where(
                    (comment) => comment.status == 'active',
                  ) // Chỉ lấy comment active
                  .toList(),
        );
  }

  /// Xóa comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      // 1. Lấy thông tin comment để cập nhật counter
      final commentDoc =
          await _getCommentsCollection(postId).doc(commentId).get();

      if (commentDoc.exists) {
        // ✅ FIX: Cast sang Map<String, dynamic> trước khi truy cập []
        final commentData = commentDoc.data() as Map<String, dynamic>?;
        final parentCommentId = commentData?['parentCommentId'] as String?;

        // 2. Xóa comment
        await _getCommentsCollection(postId).doc(commentId).delete();

        // 3. Giảm số lượng bình luận
        await _firestore.collection(_postCollection).doc(postId).update({
          'commentsCount': FieldValue.increment(-1),
        });

        // 4. Nếu là reply, giảm counter comment cha
        if (parentCommentId != null && parentCommentId.isNotEmpty) {
          await _getCommentsCollection(postId).doc(parentCommentId).update({
            'commentsCount': FieldValue.increment(-1),
          });
        }

        // 🔥 GỌI HÀM XÓA (nếu cần)
        await _postActivityRequest.onCommentDeleted(postId: postId);
      }

      print('✅ Comment đã được xóa');
    } catch (e) {
      print('❌ Lỗi khi xóa comment: $e');
      rethrow;
    }
  }

  /// Cập nhật comment
  Future<void> updateComment(
    String postId,
    String commentId,
    String newContent,
  ) async {
    try {
      await _getCommentsCollection(postId).doc(commentId).update({
        'content': newContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Comment đã được cập nhật');
    } catch (e) {
      print('❌ Lỗi khi cập nhật comment: $e');
      rethrow;
    }
  }

  /// Ẩn comment (set status = 'hidden') và giảm commentsCount
  Future<void> hideComment(String postId, String commentId) async {
    try {
      // 1. Lấy thông tin comment để kiểm tra trạng thái hiện tại
      final commentDoc =
          await _getCommentsCollection(postId).doc(commentId).get();

      if (commentDoc.exists) {
        final commentData = commentDoc.data() as Map<String, dynamic>?;
        final currentStatus = commentData?['status'] as String?;
        final parentCommentId = commentData?['parentCommentId'] as String?;

        // Chỉ xử lý nếu comment đang active
        if (currentStatus == 'active') {
          // 2. Cập nhật status thành 'hidden'
          await _getCommentsCollection(postId).doc(commentId).update({
            'status': 'hidden',
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // 3. Giảm số lượng bình luận trên bài viết
          await _firestore.collection(_postCollection).doc(postId).update({
            'commentsCount': FieldValue.increment(-1),
          });

          // 4. Nếu là reply, giảm counter comment cha
          if (parentCommentId != null && parentCommentId.isNotEmpty) {
            await _getCommentsCollection(postId).doc(parentCommentId).update({
              'commentsCount': FieldValue.increment(-1),
            });
          }

          print('✅ Comment đã được ẩn và commentsCount đã giảm');
        } else {
          print('⚠️ Comment không ở trạng thái active, bỏ qua');
        }
      }
    } catch (e) {
      print('❌ Lỗi khi ẩn comment: $e');
      rethrow;
    }
  }
}
