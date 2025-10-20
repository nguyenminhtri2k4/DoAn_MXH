import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String content;
  final String? groupId;
  final List<String> mediaIds;
  final int commentsCount;
  final int likesCount;
  final int shareCount;
  final String status;
  final String visibility;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // --- THÊM CÁC TRƯỜ...ng MỚI ---
  final String? originalPostId;
  final String? originalAuthorId;
  // --------------------------

  PostModel({
    required this.id,
    required this.authorId,
    required this.content,
    this.groupId,
    this.mediaIds = const [],
    this.commentsCount = 0,
    this.likesCount = 0,
    this.shareCount = 0,
    this.status = 'active',
    this.visibility = 'public',
    required this.createdAt,
    this.updatedAt,
    // --- THÊM VÀO CONSTRUCTOR ---
    this.originalPostId,
    this.originalAuthorId,
  });

  static int _parseCount(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is List) return v.length;
    return 0;
  }

  static List<String> _parseListString(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) return [v];
    return [];
  }

  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      content: map['content'] ?? '',
      groupId: map['groupId'],
      mediaIds: _parseListString(map['mediaIds'] ?? map['mediaId']),
      commentsCount: _parseCount(map['commentsCount']),
      likesCount: _parseCount(map['likesCount']),
      shareCount: _parseCount(map['shareCount']),
      status: map['status'] ?? 'active',
      visibility: map['visibility'] ?? 'public',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      // --- ĐỌC DỮ LIỆU TỪ FIRESTORE ---
      originalPostId: map['originalPostId'],
      originalAuthorId: map['originalAuthorId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      if (groupId != null) 'groupId': groupId,
      'mediaIds': mediaIds,
      'commentsCount': commentsCount,
      'likesCount': likesCount,
      'shareCount': shareCount,
      'status': status,
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      // --- GHI DỮ LIỆU VÀO FIRESTORE ---
      if (originalPostId != null) 'originalPostId': originalPostId,
      if (originalAuthorId != null) 'originalAuthorId': originalAuthorId,
    };
  }
}