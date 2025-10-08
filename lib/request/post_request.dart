// // lib/request/post_request.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mangxahoi/model/model_post.dart';

// class PostRequest {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String _collectionName = 'Post'; // Tên collection cho bài viết

//   /// Tạo và lưu bài viết mới lên Firestore
//   Future<String> createPost(PostModel post) async {
//     try {
//       final postMap = post.toMap();
//       // Bỏ qua id vì nó là document ID, sẽ được tự động gán khi .add()
//       postMap.remove('id'); 
      
//       // Thêm bài viết mới vào collection 'Post'
//       final docRef = await _firestore.collection(_collectionName).add(postMap);
//       print('✅ Bài viết mới đã được tạo với ID: ${docRef.id}');
//       return docRef.id;
//     } catch (e) {
//       print('❌ Lỗi khi tạo bài viết: $e');
//       rethrow;
//     }
//   }

//   // Bạn có thể thêm các hàm khác như getPost, updatePost, deletePost tại đây.
// }
// lib/request/post_request.dart
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

  // ====> THÊM HÀM NÀY <====
  /// Lấy danh sách bài viết (dạng stream để tự động cập nhật)
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
}