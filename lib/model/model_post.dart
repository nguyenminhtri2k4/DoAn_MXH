// lib/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String content;
  final List<String> mediaIds;
  final int commentsCount;
  final int likesCount;
  final int shareCount;
  final String status;    // e.g. "active"
  final String visibility; // e.g. "public", "hidden"
  final DateTime createdAt;
  final DateTime? updatedAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.content,
    this.mediaIds = const [],
    this.commentsCount = 0,
    this.likesCount = 0,
    this.shareCount = 0,
    this.status = 'active',
    this.visibility = 'public',
    required this.createdAt,
    this.updatedAt,
  });

  // robust parser: hỗ trợ int | String | List
  static int _parseCount(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is List) {
      if (v.isEmpty) return 0;
      // nếu list có đúng 1 phần tử và phần tử là số (string) => coi đó là count
      if (v.length == 1 && v.first is String && int.tryParse(v.first) != null) {
        return int.tryParse(v.first) ?? 0;
      }
      // ngược lại coi list là danh sách id => trả về độ dài
      return v.length;
    }
    return 0;
  }

  static List<String> _parseListString(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    if (v is String && v.isNotEmpty) return [v];
    return [];
  }

  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      content: map['content'] ?? '',
      mediaIds: _parseListString(map['mediaIds'] ?? map['mediaId']),
      commentsCount: _parseCount(map['commentsCount']),
      likesCount: _parseCount(map['likesCount']),
      shareCount: _parseCount(map['shareCount']),
      status: map['status'] ?? 'active',
      visibility: map['visibility'] ?? 'public',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is String)
              ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
              : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['updatedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      'mediaIds': mediaIds,
      'commentsCount': commentsCount,
      'likesCount': likesCount,
      'shareCount': shareCount,
      'status': status,
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
