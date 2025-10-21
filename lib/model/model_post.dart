
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String content;
  final List<String> mediaIds;
  final String? groupId; // Có thể null nếu là bài viết cá nhân
  final int commentsCount;
  final int likesCount;
  final int shareCount;
  final String status;
  final String visibility; // public, friends, private
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt; // THÊM MỚI: Theo dõi thời gian xóa
  final String? originalPostId; // Dùng cho bài viết được chia sẻ
  final String? originalAuthorId; // Dùng cho bài viết được chia sẻ

  const PostModel({
    required this.id,
    required this.authorId,
    required this.content,
    required this.mediaIds,
    this.groupId,
    required this.commentsCount,
    required this.likesCount,
    required this.shareCount,
    required this.status,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.originalPostId,
    this.originalAuthorId,
  });

  /// Factory constructor để tạo một đối tượng PostModel từ một DocumentSnapshot của Firestore.
  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      content: map['content'] ?? '',
      mediaIds: List<String>.from(map['mediaIds'] ?? []),
      groupId: map['groupId'],
      commentsCount: map['commentsCount'] ?? 0,
      likesCount: map['likesCount'] ?? 0,
      shareCount: map['shareCount'] ?? 0,
      status: map['status'] ?? 'active',
      visibility: map['visibility'] ?? 'public',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(), // THÊM MỚI
      originalPostId: map['originalPostId'],
      originalAuthorId: map['originalAuthorId'],
    );
  }

  /// Chuyển đổi một đối tượng PostModel thành một Map để lưu trữ trên Firestore.
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      'mediaIds': mediaIds,
      'groupId': groupId,
      'commentsCount': commentsCount,
      'likesCount': likesCount,
      'shareCount': shareCount,
      'status': status,
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null, // THÊM MỚI
      'originalPostId': originalPostId,
      'originalAuthorId': originalAuthorId,
    };
  }

  /// Tạo một bản sao của đối tượng PostModel nhưng với một vài trường được cập nhật.
  PostModel copyWith({
    String? id,
    String? authorId,
    String? content,
    List<String>? mediaIds,
    String? groupId,
    int? commentsCount,
    int? likesCount,
    int? shareCount,
    String? status,
    String? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? originalPostId,
    String? originalAuthorId,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      mediaIds: mediaIds ?? this.mediaIds,
      groupId: groupId ?? this.groupId,
      commentsCount: commentsCount ?? this.commentsCount,
      likesCount: likesCount ?? this.likesCount,
      shareCount: shareCount ?? this.shareCount,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originalPostId: originalPostId ?? this.originalPostId,
      originalAuthorId: originalAuthorId ?? this.originalAuthorId,
    );
  }
}