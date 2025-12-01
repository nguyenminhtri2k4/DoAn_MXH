import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_post.dart';

class PostRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Post';

  // ==================== CHỨC NĂNG: ĐĂNG BÀI ====================

  /// Tạo bài viết mới với kiểm tra quyền đăng trong Group
  Future<String> createPost(PostModel post) async {
    try {
      final postMap = post.toMap();

      if (post.groupId != null && post.groupId!.isNotEmpty) {
        await _checkAndUpdatePostPermissionInGroup(postMap, post);
      }

      final docRef = await _firestore.collection(_collectionName).add(postMap);
      return docRef.id;
    } catch (e) {
      print('❌ Lỗi khi tạo bài viết: $e');
      rethrow;
    }
  }

  /// Kiểm tra quyền đăng bài trong Group và cập nhật status nếu cần
  Future<void> _checkAndUpdatePostPermissionInGroup(
    Map<String, dynamic> postMap,
    PostModel post,
  ) async {
    try {
      final groupDoc =
          await _firestore.collection('Group').doc(post.groupId).get();

      if (!groupDoc.exists) return;

      final groupData = groupDoc.data()!;
      final settings = groupData['settings'] is Map
          ? groupData['settings'] as Map
          : <String, dynamic>{};

      final String postPermission = settings['post_permission']?.toString() ?? 'all';
      final String authorId = post.authorId;
      final String ownerId = groupData['ownerId'] ?? '';
      final List managers =
          groupData['managers'] is List ? groupData['managers'] : [];

      bool needsApproval = false;

      if (postPermission == 'owner') {
        needsApproval = authorId != ownerId;
      } else if (postPermission == 'managers') {
        needsApproval = authorId != ownerId && !managers.contains(authorId);
      }

      if (needsApproval) {
        postMap['status'] = 'pending';
        print('🔒 Bài viết trong nhóm cần duyệt. Status đã chuyển sang pending.');
      }
    } catch (e) {
      print('⚠️ Lỗi khi kiểm tra quyền Group: $e');
    }
  }

  /// Cập nhật bài viết
  Future<void> updatePost(PostModel post) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(post.id)
          .update(post.toMap());
    } catch (e) {
      print('❌ Lỗi khi cập nhật bài viết: $e');
      rethrow;
    }
  }

  // ==================== CHỨC NĂNG: DUYỆT BÀI (NHÓM) ====================

  /// Lấy danh sách bài viết đang chờ duyệt của một nhóm
  Stream<List<PostModel>> getPendingPostsByGroupId(String groupId) {
    return _firestore
        .collection(_collectionName)
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromMap(doc.id, doc.data())).toList());
  }

  /// Duyệt bài viết (Chuyển status sang active)
  Future<void> approveGroupPost(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).update({
        'status': 'active',
        'approvedAt': Timestamp.now(),
      });
    } catch (e) {
      print('❌ Lỗi khi duyệt bài viết: $e');
      rethrow;
    }
  }

  /// Từ chối bài viết
  Future<void> rejectGroupPost(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).delete();
    } catch (e) {
      print('❌ Lỗi khi từ chối bài viết: $e');
      rethrow;
    }
  }

  // ==================== CHỨC NĂNG: XÓA BÀI ====================

  /// Xóa bài viết mềm (soft delete)
  Future<void> deletePostSoft(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).update({
        'status': 'deleted',
        'deletedAt': Timestamp.now(),
      });
    } catch (e) {
      print('❌ Lỗi khi xóa bài viết: $e');
      rethrow;
    }
  }

  /// Lấy các bài viết đã xóa của người dùng
  Stream<List<PostModel>> getDeletedPosts(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('authorId', isEqualTo: userId)
        .where('status', isEqualTo: 'deleted')
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Khôi phục bài viết từ thùng rác
  Future<void> restorePost(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).update({
        'status': 'active',
        'visibility': 'private',
        'deletedAt': null,
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

  // ==================== CHỨC NĂNG: LẤY BÀI VIẾT ====================

  /// Lấy danh sách bài viết active để phục vụ tìm kiếm (Client-side filtering)
  /// Hàm này lấy về một lượng lớn bài viết mới nhất để ViewModel lọc nội dung
  Future<List<PostModel>> getPostsForSearch({int limit = 1000}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PostModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('❌ Lỗi khi lấy danh sách bài viết tìm kiếm: $e');
      return [];
    }
  }

  /// Lấy các bài viết công khai và của bạn bè (có phân trang)
  Future<List<PostModel>> getPostsPaginated({
    required String currentUserId,
    required List<String> friendIds,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) {
    var query = _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.limit(limit * 2).get().then((snapshot) {
      final allPosts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      final visiblePosts = allPosts.where((post) {
        if (post.visibility == 'public') return true;
        if (post.visibility == 'friends' &&
            (friendIds.contains(post.authorId) || post.authorId == currentUserId)) {
          return true;
        }
        if (post.visibility == 'private' && post.authorId == currentUserId) {
          return true;
        }
        return false;
      }).take(limit).toList();

      return visiblePosts;
    });
  }

  /// Lấy bài viết theo tác giả
  Stream<List<PostModel>> getPostsByAuthorId(
    String authorId, {
    String? currentUserId,
    List<String> friendIds = const [],
  }) {
    return _firestore
        .collection(_collectionName)
        .where('authorId', isEqualTo: authorId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final allPosts = snapshot.docs
              .map((doc) => PostModel.fromMap(doc.id, doc.data()))
              .toList();

          if (currentUserId != null && authorId != currentUserId) {
            return allPosts.where((post) {
              if (post.visibility == 'public') return true;
              if (post.visibility == 'friends' && friendIds.contains(authorId)) {
                return true;
              }
              return false;
            }).toList();
          }

          return allPosts;
        });
  }

  /// Lấy bài viết theo nhóm
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

  // ==================== CHỨC NĂNG: CHIA SẺ BÀI ====================

  /// Chia sẻ bài viết
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
        reactionsCount: {},
        shareCount: 0,
        status: 'active',
      );

      batch.set(newPostRef, sharedPost.toMap());
      batch.update(
        _firestore.collection(_collectionName).doc(originalPost.id),
        {'shareCount': FieldValue.increment(1)},
      );

      await batch.commit();
      print('✅ Chia sẻ bài viết thành công!');
    } catch (e) {
      print('❌ Lỗi khi chia sẻ bài viết: $e');
      rethrow;
    }
  }
}