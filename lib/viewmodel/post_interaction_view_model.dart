// lib/viewmodel/post_interaction_view_model.dart
import 'package:flutter/material.dart';
import 'package:mangxahoi/request/comment_request.dart';
import 'package:mangxahoi/request/reaction_request.dart';
import 'package:mangxahoi/model/model_comment.dart';

class PostInteractionViewModel extends ChangeNotifier {
  final String postId;
  final ReactionRequest _reactionRequest = ReactionRequest();
  final CommentRequest _commentRequest = CommentRequest();

  late Stream<List<CommentModel>> commentsStream;
  final TextEditingController commentController = TextEditingController();

  PostInteractionViewModel(this.postId) {
    commentsStream = _commentRequest.getComments(postId);
  }

  /// Xử lý khi người dùng chọn một reaction (like, love, haha...)
  Future<void> handleReaction(String userDocId, String reactionType) async {
    if (userDocId.isEmpty) return;

    try {
      // 1. Lấy reaction hiện tại của user
      final String? oldReactionType = await _reactionRequest.getUserReactionType(
        postId, 
        userDocId
      );

      if (oldReactionType == reactionType) {
        // 2. Nếu nhấn lại reaction cũ -> Xóa reaction
        await _reactionRequest.removeReaction(
          postId, 
          userDocId, 
          reactionType,
        );
        print('🔄 Đã xóa reaction: $reactionType');
      } else {
        // 3. Nếu là reaction mới (hoặc thay đổi) -> Đặt reaction
        await _reactionRequest.setReaction(
          postId, 
          userDocId, 
          reactionType, 
          oldReactionType,
        );
        print('🔄 Đã thay đổi reaction: $oldReactionType -> $reactionType');
      }
    } catch (e) {
      print("❌ Error handling reaction: $e");
    }
  }
  
  /// Thêm comment mới
  Future<void> addComment(String userDocId, {String? parentId}) async {
    final content = commentController.text.trim();
    if (userDocId.isEmpty || content.isEmpty) return;

    try {
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
      print('✅ Đã thêm comment');
    } catch (e) {
      print('❌ Error adding comment: $e');
    }
  }
  
  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}