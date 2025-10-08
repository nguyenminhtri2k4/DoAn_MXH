// lib/model/model_comment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final String? parentCommentId;
  final List<String> likes;      // danh sách userId đã like (nếu lưu ids)
  final List<String> mediaIds;
  final int commentsCount;       // số reply count
  final int shareCount;
  final String status;           // active / deleted
  final String visibility;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    this.parentCommentId,
    this.likes = const [],
    this.mediaIds = const [],
    this.commentsCount = 0,
    this.shareCount = 0,
    this.status = 'active',
    this.visibility = 'public',
    required this.createdAt,
    this.updatedAt,
  });

  static int _parseCount(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is List) {
      if (v.isEmpty) return 0;
      if (v.length == 1 && v.first is String && int.tryParse(v.first) != null) {
        return int.tryParse(v.first) ?? 0;
      }
      return v.length;
    }
    return 0;
  }

  static List<String> _parseList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    if (v is String && v.isNotEmpty) return [v];
    return [];
  }

  factory CommentModel.fromDoc(String postId, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: postId,
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      parentCommentId: data['parentCommentId'],
      likes: _parseList(data['likesCount']), // nếu likesCount là list of userIds
      mediaIds: _parseList(data['mediaIds']),
      commentsCount: _parseCount(data['commentsCount']),
      shareCount: _parseCount(data['shareCount']),
      status: data['status'] ?? 'active',
      visibility: data['visibility'] ?? 'public',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      'parentCommentId': parentCommentId ?? '',
      'likesCount': likes,
      'mediaIds': mediaIds,
      'commentsCount': commentsCount,
      'shareCount': shareCount,
      'status': status,
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
