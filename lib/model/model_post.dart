
// import 'package:cloud_firestore/cloud_firestore.dart';

// class PostModel {
//   final String id;
//   final String authorId;
//   final String content;
//   final List<String> mediaIds;
//   final String? groupId;
//   final int commentsCount;
//   final Map<String, int> reactionsCount;
//   final int shareCount;
//   final String status;
//   final String visibility;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final DateTime? deletedAt; 
//   final String? originalPostId; 
//   final String? originalAuthorId; 

//   const PostModel({
//     required this.id,
//     required this.authorId,
//     required this.content,
//     required this.mediaIds,
//     this.groupId,
//     required this.commentsCount,
//     required this.reactionsCount,
//     required this.shareCount,
//     required this.status,
//     required this.visibility,
//     required this.createdAt,
//     required this.updatedAt,
//     this.deletedAt,
//     this.originalPostId,
//     this.originalAuthorId,
//   });

//   /// Factory constructor
//   factory PostModel.fromMap(String id, Map<String, dynamic> map) {
//     return PostModel(
//       id: id,
//       authorId: map['authorId'] ?? '',
//       content: map['content'] ?? '',
//       mediaIds: List<String>.from(map['mediaIds'] ?? []),
//       groupId: map['groupId'],
//       commentsCount: map['commentsCount'] ?? 0,
//       reactionsCount: Map<String, int>.from(map['reactionsCount'] ?? {}),
//       shareCount: map['shareCount'] ?? 0,
//       status: map['status'] ?? 'active',
//       visibility: map['visibility'] ?? 'public',
//       createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(), 
//       originalPostId: map['originalPostId'],
//       originalAuthorId: map['originalAuthorId'],
//     );
//   }

//   /// Chuyển đổi thành Map
//   Map<String, dynamic> toMap() {
//     return {
//       'authorId': authorId,
//       'content': content,
//       'mediaIds': mediaIds,
//       'groupId': groupId,
//       'commentsCount': commentsCount,
//       'reactionsCount': reactionsCount,
//       'shareCount': shareCount,
//       'status': status,
//       'visibility': visibility,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'updatedAt': Timestamp.fromDate(updatedAt),
//       'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null, 
//       'originalPostId': originalPostId,
//       'originalAuthorId': originalAuthorId,
//     };
//   }

//   /// CopyWith
//   PostModel copyWith({
//     String? id,
//     String? authorId,
//     String? content,
//     List<String>? mediaIds,
//     String? groupId,
//     int? commentsCount,
//     Map<String, int>? reactionsCount,
//     int? shareCount,
//     String? status,
//     String? visibility,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//     DateTime? deletedAt,
//     String? originalPostId,
//     String? originalAuthorId,
//   }) {
//     return PostModel(
//       id: id ?? this.id,
//       authorId: authorId ?? this.authorId,
//       content: content ?? this.content,
//       mediaIds: mediaIds ?? this.mediaIds,
//       groupId: groupId ?? this.groupId,
//       commentsCount: commentsCount ?? this.commentsCount,
//       reactionsCount: reactionsCount ?? this.reactionsCount,
//       shareCount: shareCount ?? this.shareCount,
//       status: status ?? this.status,
//       visibility: visibility ?? this.visibility,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//       deletedAt: deletedAt ?? this.deletedAt,
//       originalPostId: originalPostId ?? this.originalPostId,
//       originalAuthorId: originalAuthorId ?? this.originalAuthorId,
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String content;
  final List<String> mediaIds;
  final String? groupId;
  final int commentsCount;
  final Map<String, int> reactionsCount;
  final int shareCount;
  final String status;
  final String visibility;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt; 
  final String? originalPostId; 
  final String? originalAuthorId; 
  final List<String>? taggedUserIds; // <-- THÊM MỚI

  const PostModel({
    required this.id,
    required this.authorId,
    required this.content,
    required this.mediaIds,
    this.groupId,
    required this.commentsCount,
    required this.reactionsCount,
    required this.shareCount,
    required this.status,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.originalPostId,
    this.originalAuthorId,
    this.taggedUserIds, // <-- THÊM MỚI
  });

  /// Factory constructor
  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      content: map['content'] ?? '',
      mediaIds: List<String>.from(map['mediaIds'] ?? []),
      groupId: map['groupId'],
      commentsCount: map['commentsCount'] ?? 0,
      reactionsCount: Map<String, int>.from(map['reactionsCount'] ?? {}),
      shareCount: map['shareCount'] ?? 0,
      status: map['status'] ?? 'active',
      visibility: map['visibility'] ?? 'public',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(), 
      originalPostId: map['originalPostId'],
      originalAuthorId: map['originalAuthorId'],
      taggedUserIds: List<String>.from(map['taggedUserIds'] ?? []), // <-- THÊM MỚI
    );
  }

  /// Chuyển đổi thành Map
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      'mediaIds': mediaIds,
      'groupId': groupId,
      'commentsCount': commentsCount,
      'reactionsCount': reactionsCount,
      'shareCount': shareCount,
      'status': status,
      'visibility': visibility,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null, 
      'originalPostId': originalPostId,
      'originalAuthorId': originalAuthorId,
      'taggedUserIds': taggedUserIds, // <-- THÊM MỚI
    };
  }

  /// CopyWith
  PostModel copyWith({
    String? id,
    String? authorId,
    String? content,
    List<String>? mediaIds,
    String? groupId,
    int? commentsCount,
    Map<String, int>? reactionsCount,
    int? shareCount,
    String? status,
    String? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? originalPostId,
    String? originalAuthorId,
    List<String>? taggedUserIds, // <-- THÊM MỚI
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      mediaIds: mediaIds ?? this.mediaIds,
      groupId: groupId ?? this.groupId,
      commentsCount: commentsCount ?? this.commentsCount,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      shareCount: shareCount ?? this.shareCount,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originalPostId: originalPostId ?? this.originalPostId,
      originalAuthorId: originalAuthorId ?? this.originalAuthorId,
      taggedUserIds: taggedUserIds ?? this.taggedUserIds, // <-- THÊM MỚI
    );
  }
}