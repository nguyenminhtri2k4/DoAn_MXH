import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/model/model_comment.dart';
import 'package:mangxahoi/viewmodel/post_interaction_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'comment_widget.dart';

class CommentSheet extends StatefulWidget {
  final String postId;
  final String currentUserDocId;

  const CommentSheet({super.key, required this.postId, required this.currentUserDocId});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  CommentModel? _replyingToComment;
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void dispose() {
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostInteractionViewModel(widget.postId),
      child: Consumer<PostInteractionViewModel>(
        builder: (context, viewModel, child) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
                        const SizedBox(height: 8),
                        const Text('Bình luận', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: StreamBuilder<List<CommentModel>>(
                      stream: viewModel.commentsStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        if (snapshot.data!.isEmpty) return const Center(child: Text('Chưa có bình luận nào.'));
                        
                        final allComments = snapshot.data!;
                        final topLevelComments = allComments.where((c) => c.parentCommentId == null || c.parentCommentId!.isEmpty).toList();
                        final replies = allComments.where((c) => c.parentCommentId != null && c.parentCommentId!.isNotEmpty).toList();

                        final repliesMap = <String, List<CommentModel>>{};
                        for (var reply in replies) {
                          repliesMap.putIfAbsent(reply.parentCommentId!, () => []).add(reply);
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: topLevelComments.length,
                          itemBuilder: (context, index) {
                            final parentComment = topLevelComments[index];
                            final commentReplies = repliesMap[parentComment.id] ?? [];

                            return Column(
                              children: [
                                CommentWidget(
                                  comment: parentComment,
                                  onReply: () {
                                    setState(() => _replyingToComment = parentComment);
                                    _commentFocusNode.requestFocus();
                                  },
                                ),
                                if (commentReplies.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 40.0),
                                    child: Column(
                                      children: commentReplies.map((reply) => CommentWidget(
                                        comment: reply,
                                        isReply: true,
                                        onReply: () {
                                          setState(() => _replyingToComment = parentComment);
                                          _commentFocusNode.requestFocus();
                                        },
                                      )).toList(),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  _buildCommentInputField(context, viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentInputField(BuildContext context, PostInteractionViewModel viewModel) {
    final replyingToUser = _replyingToComment != null
        ? context.read<FirestoreListener>().getUserById(_replyingToComment!.authorId)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToComment != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(child: Text('Đang trả lời ${replyingToUser?.name ?? '...'}', style: TextStyle(color: Colors.grey[700]))),
                  GestureDetector(
                    onTap: () => setState(() => _replyingToComment = null),
                    child: const Icon(Icons.close, size: 18, color: Colors.grey),
                  )
                ],
              ),
            ),
          TextField(
            focusNode: _commentFocusNode,
            controller: viewModel.commentController,
            decoration: InputDecoration(
              hintText: _replyingToComment == null ? 'Viết bình luận...' : 'Viết câu trả lời của bạn...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: AppColors.primary),
                onPressed: () {
                  if (viewModel.commentController.text.isNotEmpty) {
                    viewModel.addComment(widget.currentUserDocId, parentId: _replyingToComment?.id);
                    setState(() => _replyingToComment = null);
                    _commentFocusNode.unfocus();
                  }
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }
}