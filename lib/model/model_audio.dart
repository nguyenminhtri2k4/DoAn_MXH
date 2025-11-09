import 'package:cloud_firestore/cloud_firestore.dart';

class AudioModel {
  final String id;
  final String uploaderId;
  final String name; // Tên âm thanh (ví dụ: "Nhạc nền chill")
  final String url; // Đường dẫn tới file .mp3 / .m4a
  final String coverImageUrl; // Ảnh đại diện cho âm thanh
  final DateTime createdAt;

  AudioModel({
    required this.id,
    required this.uploaderId,
    required this.name,
    required this.url,
    this.coverImageUrl = '',
    required this.createdAt,
  });

  /// Firestore -> Dart
  factory AudioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AudioModel(
      id: doc.id,
      uploaderId: data['uploaderId'] ?? '',
      name: data['name'] ?? '',
      url: data['url'] ?? '',
      coverImageUrl: data['coverImageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  /// Dart -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'uploaderId': uploaderId,
      'name': name,
      'url': url,
      'coverImageUrl': coverImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}