
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_post.dart';

class PostRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Post';

  Future<String> createPost(PostModel post) async {
    try {
      final postMap = post.toMap();
      final docRef = await _firestore.collection(_collectionName).add(postMap);
      return docRef.id;
    } catch (e) {
      print('❌ Lỗi khi tạo bài viết: $e');
      rethrow;
    }
  }
  
  Future<void> updatePost(PostModel post) async {
    try {
      await _firestore.collection(_collectionName).doc(post.id).update(post.toMap());
    } catch (e) {
      print('❌ Lỗi khi cập nhật bài viết: $e');
      rethrow;
    }
  }

  Future<void> deletePostSoft(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).update({
        'status': 'deleted',
        'deletedAt': Timestamp.now(), // Cập nhật thời gian xóa
      });
    } catch (e) {
      print('❌ Lỗi khi xóa bài viết: $e');
      rethrow;
    }
  }
  
  // ==================== CÁC HÀM MỚI CHO THÙNG RÁC ====================

  /// Lấy các bài viết đã xóa của người dùng
  Stream<List<PostModel>> getDeletedPosts(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('authorId', isEqualTo: userId)
        .where('status', isEqualTo: 'deleted')
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromMap(doc.id, doc.data())).toList());
  }

  /// Khôi phục bài viết từ thùng rác
  Future<void> restorePost(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).update({
        'status': 'active', // Chuyển lại trạng thái active
        'visibility': 'private', // Đặt lại quyền riêng tư là cá nhân
        'deletedAt': null, // Xóa thời gian xóa
      });
    } catch (e) {
      print('❌ Lỗi khi khôi phục bài viết: $e');
      rethrow;
    }
  }

  /// Xóa vĩnh viễn bài viết
  Future<void> deletePostPermanently(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).delete();
    } catch (e) {
      print('❌ Lỗi khi xóa vĩnh viễn bài viết: $e');
      rethrow;
    }
  }
  // =================================================================

  Future<List<PostModel>> getPostsPaginated({
    required String currentUserId,
    required List<String> friendIds,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) {
    // Hàm này phức tạp hơn vì phải query nhiều điều kiện `whereIn`
    // Firestore không hỗ trợ query `IN` và `NOT-IN` trên cùng một trường trong một query.
    // Cách tiếp cận đơn giản và hiệu quả nhất là lấy tất cả bài viết công khai và của bạn bè,
    // sau đó lọc ở phía client.
    
    // Lấy các bài viết công khai hoặc của bạn bè
    var query = _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);
        
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.limit(limit * 2) // Lấy nhiều hơn để có đủ dữ liệu sau khi lọc
        .get()
        .then((snapshot) {
            final allPosts = snapshot.docs.map((doc) => PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
            
            final visiblePosts = allPosts.where((post) {
                if (post.visibility == 'public') return true;
                if (post.visibility == 'friends' && (friendIds.contains(post.authorId) || post.authorId == currentUserId)) return true;
                if (post.visibility == 'private' && post.authorId == currentUserId) return true;
                return false;
            }).take(limit).toList();

            return visiblePosts;
        });
  }

  Stream<List<PostModel>> getPostsByAuthorId(String authorId, {String? currentUserId, List<String> friendIds = const []}) {
    return _firestore
        .collection(_collectionName)
        .where('authorId', isEqualTo: authorId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
            final allPosts = snapshot.docs.map((doc) => PostModel.fromMap(doc.id, doc.data())).toList();
            // Nếu xem trang cá nhân của người khác, chỉ hiển thị bài công khai hoặc bạn bè
            if (currentUserId != null && authorId != currentUserId) {
                return allPosts.where((post) {
                    if (post.visibility == 'public') return true;
                    if (post.visibility == 'friends' && friendIds.contains(authorId)) return true;
                    return false;
                }).toList();
            }
            // Nếu xem trang của chính mình, hiển thị tất cả
            return allPosts;
        });
  }
  
  Stream<List<PostModel>> getPostsByGroupId(String groupId) {
    return _firestore
        .collection(_collectionName)
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> sharePost({
    required PostModel originalPost,
    required String sharerId,
    String? content,
    required String visibility,
  }) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();
      final newPostRef = _firestore.collection(_collectionName).doc();

      final sharedPost = PostModel(
        id: newPostRef.id,
        authorId: sharerId,
        content: content ?? '',
        createdAt: now,
        updatedAt: now,
        visibility: visibility,
        originalPostId: originalPost.id,
        originalAuthorId: originalPost.authorId,
        mediaIds: [],
        commentsCount: 0,
        reactionsCount: {}, // Một Map rỗng
        shareCount: 0,
        status: 'active',
      );

      batch.set(newPostRef, sharedPost.toMap());

      final originalPostRef = _firestore.collection(_collectionName).doc(originalPost.id);
      batch.update(originalPostRef, {
        'shareCount': FieldValue.increment(1),
      });

      await batch.commit();
      print('✅ Chia sẻ bài viết thành công!');
    } catch (e) {
      print('❌ Lỗi khi chia sẻ bài viết: $e');
      rethrow;
    }
  }
}