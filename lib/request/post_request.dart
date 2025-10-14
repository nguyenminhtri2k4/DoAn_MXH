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

  /// Lấy danh sách tất cả bài viết (dạng stream để tự động cập nhật)
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

  // ==================== THÊM HÀM MỚI DƯỚI ĐÂY ====================
  /// Lấy danh sách bài viết của một người dùng cụ thể
  Stream<List<PostModel>> getPostsByAuthorId(String authorId) {
    return _firestore
        .collection(_collectionName)
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromMap(doc.id, doc.data())).toList());
  }
}