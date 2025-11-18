// lib/model/model_locket_photo.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LocketPhoto {
  final String id;
  final String userId; // Document ID của user
  final String imageUrl;
  final Timestamp timestamp;
  final String status;     // <--- THÊM MỚI: 'active', 'deleted'
  final Timestamp? deletedAt; // <--- THÊM MỚI

  LocketPhoto({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.timestamp,
    this.status = 'active', // <--- THÊM MỚI
    this.deletedAt,          // <--- THÊM MỚI
  });

  factory LocketPhoto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LocketPhoto(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: data['status'] ?? 'active', // <--- THÊM MỚI
      deletedAt: data['deletedAt'] as Timestamp?, // <--- THÊM MỚI
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'status': status,       // <--- THÊM MỚI
      'deletedAt': deletedAt, // <--- THÊM MỚI
    };
  }

  // Hàm copyWith để dễ cập nhật
  LocketPhoto copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    Timestamp? timestamp,
    String? status,
    Timestamp? deletedAt,
    bool setDeletedAtNull = false, // Cờ để xóa deletedAt khi khôi phục
  }) {
    return LocketPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      deletedAt: setDeletedAtNull ? null : (deletedAt ?? this.deletedAt),
    );
  }
}