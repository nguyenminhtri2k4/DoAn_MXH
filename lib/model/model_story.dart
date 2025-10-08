import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String authorId;
  final String caption;
  final List<String> mediaIds;
  final String privacy;
  final List<String> allowedUsers;
  final List<String> blockedUsers;
  final int viewCount;
  final int reactionCount;
  final Timestamp createdAt;
  final Timestamp expireAt;

  StoryModel({
    required this.id,
    required this.authorId,
    required this.caption,
    required this.mediaIds,
    required this.privacy,
    required this.allowedUsers,
    required this.blockedUsers,
    required this.viewCount,
    required this.reactionCount,
    required this.createdAt,
    required this.expireAt,
  });

  factory StoryModel.fromMap(Map<String, dynamic> data, String id) {
    return StoryModel(
      id: id,
      authorId: data['authorId'] ?? '',
      caption: data['caption'] ?? '',
      mediaIds: List<String>.from(data['mediaId'] ?? []),
      privacy: data['privacy'] ?? 'public',
      allowedUsers: List<String>.from(data['allowedUsers'] ?? []),
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      viewCount: data['viewCount'] ?? 0,
      reactionCount: data['reactionCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      expireAt: data['expireAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'caption': caption,
      'mediaId': mediaIds,
      'privacy': privacy,
      'allowedUsers': allowedUsers,
      'blockedUsers': blockedUsers,
      'viewCount': viewCount,
      'reactionCount': reactionCount,
      'createdAt': createdAt,
      'expireAt': expireAt,
    };
  }
}
