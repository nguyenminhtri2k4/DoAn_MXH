import 'package:cloud_firestore/cloud_firestore.dart'; // SỬA LỖI IMPORT
import 'package:mangxahoi/model/model_media.dart'; // SỬA LỖI IMPORT

class MediaRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Media';

  /// Thêm một media mới vào Firestore và trả về ID của document
  Future<String> createMedia(MediaModel media) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(media.toMap());
      return docRef.id;
    } catch (e) {
      print('Lỗi khi tạo media document: $e');
      rethrow;
    }
  }
}