import 'package:cloud_firestore/cloud_firestore.dart';

class StoryViewModel {
  final String viewerId;
  final String reactionType;
  final Timestamp viewedAt;

  StoryViewModel({
    required this.viewerId,
    required this.reactionType,
    required this.viewedAt,
  });

  factory StoryViewModel.fromMap(Map<String, dynamic> data) {
    return StoryViewModel(
      viewerId: data['viewerId'] ?? '',
      reactionType: data['reactionType'] ?? '',
      viewedAt: data['viewedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'viewerId': viewerId,
      'reactionType': reactionType,
      'viewedAt': viewedAt,
    };
  }
}
