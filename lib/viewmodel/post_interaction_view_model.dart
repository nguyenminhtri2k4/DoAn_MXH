import 'package:flutter/material.dart';
import 'package:mangxahoi/request/comment_request.dart';
import 'package:mangxahoi/request/reaction_request.dart';
import 'package:mangxahoi/model/model_comment.dart';

class PostInteractionViewModel extends ChangeNotifier {
  final String postId;
  final _reactionRequest = ReactionRequest();
  final _commentRequest = CommentRequest();

  late Stream<List<CommentModel>> commentsStream;
  final TextEditingController commentController = TextEditingController();

  PostInteractionViewModel(this.postId) {
    commentsStream = _commentRequest.getComments(postId);
  }

  Future<void> toggleLike(String? userDocId) async {
    if (userDocId == null || userDocId.isEmpty) return;
    try {
      final bool currentlyLiked = await _reactionRequest.hasUserLikedPost(postId, userDocId);
      if (currentlyLiked) {
        await _reactionRequest.removeLike(postId, userDocId);
      } else {
        await _reactionRequest.addLike(postId, userDocId);
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }
  
  Future<void> addComment(String? userDocId, {String? parentId}) async {
    final content = commentController.text.trim();
    if (userDocId == null || content.isEmpty) return;

    final newComment = CommentModel(
      id: '',
      postId: postId,
      authorId: userDocId,
      content: content,
      parentCommentId: parentId,
      createdAt: DateTime.now(),
    );

    await _commentRequest.addComment(postId, newComment);
    commentController.clear();
  }
  
  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}