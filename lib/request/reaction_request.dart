
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/request/post_activity_request.dart'; // 🔥 Import mới

class ReactionRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PostActivityRequest _postActivityRequest = PostActivityRequest(); // 🔥 Tạo instance
  
  final String _postCollection = 'Post';
  final String _reactionSubcollection = 'reactions';

  /// Lấy loại reaction hiện tại của người dùng cho một bài viết.
  Future<String?> getUserReactionType(String postId, String userDocId) async {
    try {
      final doc = await _firestore
          .collection(_postCollection)
          .doc(postId)
          .collection(_reactionSubcollection)
          .doc(userDocId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['type'] as String?;
      }
      return null;
    } catch (e) {
      print("❌ Lỗi khi lấy reaction: $e");
      return null;
    }
  }

  /// Đặt hoặc thay đổi một reaction.
  Future<void> setReaction(
    String postId, 
    String userDocId, 
    String reactionType, 
    String? oldReactionType
  ) async {
    try {
      final postRef = _firestore.collection(_postCollection).doc(postId);
      final reactionRef = postRef.collection(_reactionSubcollection).doc(userDocId);
      final batch = _firestore.batch();

      // 1. Thêm/Cập nhật document reaction của user
      batch.set(reactionRef, {
        'type': reactionType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Tăng đếm cho reaction mới
      batch.update(postRef, {
        'reactionsCount.$reactionType': FieldValue.increment(1),
      });

      // 3. Giảm đếm cho reaction cũ (nếu có và khác reaction mới)
      if (oldReactionType != null && oldReactionType != reactionType) {
        batch.update(postRef, {
          'reactionsCount.$oldReactionType': FieldValue.increment(-1),
        });
      }

      await batch.commit();
      print('✅ Reaction đã được cập nhật: $reactionType');

      // 🔥 GỬI THÔNG BÁO (chỉ khi là reaction mới lần đầu)
      if (oldReactionType == null) {
        await _postActivityRequest.onReactionAdded(
          postId: postId,
          userId: userDocId,
          reactionType: reactionType,
        );
      }
    } catch (e) {
      print('❌ Lỗi khi set reaction: $e');
      rethrow;
    }
  }

  /// Xóa một reaction (khi người dùng nhấn lại reaction đã chọn).
  Future<void> removeReaction(
    String postId, 
    String userDocId, 
    String oldReactionType
  ) async {
    try {
      final postRef = _firestore.collection(_postCollection).doc(postId);
      final reactionRef = postRef.collection(_reactionSubcollection).doc(userDocId);
      final batch = _firestore.batch();

      // 1. Xóa document reaction của user
      batch.delete(reactionRef);

      // 2. Giảm đếm cho reaction cũ
      batch.update(postRef, {
        'reactionsCount.$oldReactionType': FieldValue.increment(-1),
      });

      await batch.commit();
      print('✅ Reaction đã được xóa');

      // 🔥 GỌI HÀM XÓA THÔNG BÁO (nếu cần)
      await _postActivityRequest.onReactionRemoved(
        postId: postId,
        userId: userDocId,
      );
    } catch (e) {
      print('❌ Lỗi khi xóa reaction: $e');
      rethrow;
    }
  }

  /// Stream để lắng nghe tất cả reactions của một bài viết
  Stream<QuerySnapshot> getReactionsStream(String postId) {
    return _firestore
        .collection(_postCollection)
        .doc(postId)
        .collection(_reactionSubcollection)
        .snapshots();
  }

  /// Stream để lắng nghe reaction của một user cụ thể
  Stream<DocumentSnapshot> getUserReactionStream(String postId, String userDocId) {
    return _firestore
        .collection(_postCollection)
        .doc(postId)
        .collection(_reactionSubcollection)
        .doc(userDocId)
        .snapshots();
  }
}