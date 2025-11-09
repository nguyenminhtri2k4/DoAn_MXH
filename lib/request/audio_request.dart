import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_audio.dart';

class AudioRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Audio';

  /// Lấy danh sách âm thanh có sẵn
  Stream<List<AudioModel>> getAvailableAudio() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .limit(50) // Giới hạn 50 bài gần nhất
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AudioModel.fromFirestore(doc))
            .toList());
  }

  /// Tạo metadata cho âm thanh sau khi upload
  Future<AudioModel> createAudio({
    required String uploaderId,
    required String name,
    required String audioUrl,
    String coverImageUrl = '',
  }) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add({
        'uploaderId': uploaderId,
        'name': name,
        'url': audioUrl,
        'coverImageUrl': coverImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      final doc = await docRef.get();
      return AudioModel.fromFirestore(doc);
    } catch (e) {
      print('Lỗi khi tạo audio metadata: $e');
      rethrow;
    }
  }
}