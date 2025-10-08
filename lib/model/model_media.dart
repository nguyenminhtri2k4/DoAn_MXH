import 'package:cloud_firestore/cloud_firestore.dart';

class MediaModel {
  final String id;
  final String url;
  final String type; // image | video | audio | file
  final String uploadedBy;
  final DateTime? createdAt;

  MediaModel({
    required this.id,
    required this.url,
    required this.type,
    required this.uploadedBy,
    this.createdAt,
  });

  /// 🔹 Firestore → Dart Object
  factory MediaModel.fromMap(String id, Map<String, dynamic> map) {
    return MediaModel(
      id: id,
      url: map['url'] ?? '',
      type: map['type'] ?? 'image',
      uploadedBy: map['uploadedBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// 🔹 Dart Object → Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
