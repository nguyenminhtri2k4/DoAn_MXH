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

  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<PostModel>> getPostsPaginated(
      {int limit = 10, DocumentSnapshot? startAfter}) async {
    Query query = _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  Stream<List<PostModel>> getPostsByAuthorId(String authorId) {
    return _firestore
        .collection(_collectionName)
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromMap(doc.id, doc.data())).toList());
  }
  
  Stream<List<PostModel>> getPostsByGroupId(String groupId) {
    return _firestore
        .collection(_collectionName)
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromMap(doc.id, doc.data())).toList());
  }

  // === CẬP NHẬT HÀM CHIA SẺ BÀI VIẾT ===
  Future<void> sharePost({
    required PostModel originalPost,
    required String sharerId,
    String? content,
    required String visibility, // Thêm tham số visibility
  }) async {
    try {
      final sharedPost = PostModel(
        id: '',
        authorId: sharerId,
        content: content ?? '',
        createdAt: DateTime.now(),
        visibility: visibility, // Sử dụng visibility được truyền vào
        originalPostId: originalPost.id,
        originalAuthorId: originalPost.authorId,
      );

      final batch = _firestore.batch();
      final newPostRef = _firestore.collection(_collectionName).doc();
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