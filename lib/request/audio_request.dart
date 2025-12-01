import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_audio.dart';

class AudioRequest {
  static const String _collectionName = 'Audio';
  static const int _audioLimit = 50;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy danh sách âm thanh có sẵn
  Stream<List<AudioModel>> getAvailableAudio() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .limit(_audioLimit)
        .snapshots()
        .map(_mapAudioSnapshot);
  }

  /// Tạo metadata cho âm thanh sau khi upload
  Future<AudioModel> createAudio({
    required String uploaderId,
    required String name,
    required String audioUrl,
    String coverImageUrl = '',
  }) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(
        _buildAudioData(
          uploaderId: uploaderId,
          name: name,
          audioUrl: audioUrl,
          coverImageUrl: coverImageUrl,
        ),
      );

      final doc = await docRef.get();
      return AudioModel.fromFirestore(doc);
    } catch (e) {
      _logError('Tạo audio metadata', e);
      rethrow;
    }
  }

  /// Map snapshot sang danh sách AudioModel
  List<AudioModel> _mapAudioSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs
        .map((doc) => AudioModel.fromFirestore(doc))
        .toList();
  }

  /// Build dữ liệu audio cho Firestore
  Map<String, dynamic> _buildAudioData({
    required String uploaderId,
    required String name,
    required String audioUrl,
    required String coverImageUrl,
  }) {
    return {
      'uploaderId': uploaderId,
      'name': name,
      'url': audioUrl,
      'coverImageUrl': coverImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Log error một cách nhất quán
  void _logError(String operation, Object error) {
    print('❌ Lỗi khi $operation: $error');
  }
}