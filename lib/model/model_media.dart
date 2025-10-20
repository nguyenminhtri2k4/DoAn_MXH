import 'package:cloud_firestore/cloud_firestore.dart';

class MediaModel {
  final String id;
  final String url;
  final String type; // 'image' or 'video'
  final String uploaderId;
  final DateTime createdAt;

  MediaModel({
    required this.id,
    required this.url,
    required this.type,
    required this.uploaderId,
    required this.createdAt,
  });

  factory MediaModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MediaModel(
      id: doc.id,
      url: data['url'] ?? '',
      type: data['type'] ?? 'image',
      uploaderId: data['uploaderId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type,
      'uploaderId': uploaderId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}