import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/viewmodel/post_interaction_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'comment_sheet.dart';

class PostWidget extends StatelessWidget {
  final PostModel post;
  final String currentUserDocId;

  const PostWidget({
    super.key,
    required this.post,
    required this.currentUserDocId,
  });

  @override
  Widget build(BuildContext context) {
    final author = context.select<FirestoreListener, UserModel?>(
      (listener) => listener.getUserById(post.authorId),
    );
 
    return ChangeNotifierProvider(
      key: ValueKey(post.id),
      create: (_) => PostInteractionViewModel(post.id),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostHeader(author),
              const SizedBox(height: 12),
              if (post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(post.content, style: const TextStyle(fontSize: 16)),
                ),
              _buildPostStats(),
              const Divider(),
              Builder(
                builder: (BuildContext innerContext) {
                  return _buildActionButtons(innerContext);
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader(UserModel? author) {
     if (author == null) return const SizedBox.shrink();
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: (author.avatar.isNotEmpty) ? NetworkImage(author.avatar.first) : null,
          child: (author.avatar.isEmpty) ? const Icon(Icons.person, size: 20) : null,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(author.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${post.createdAt.hour.toString().padLeft(2, '0')}:${post.createdAt.minute.toString().padLeft(2, '0')} · ${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostStats() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('Post').doc(post.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 20);
        final postData = snapshot.data!.data() as Map<String, dynamic>?;
        final likes = postData?['likesCount'] ?? 0;
        final comments = postData?['commentsCount'] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$likes lượt thích'),
              Text('$comments bình luận'),
            ],
          ),
        );
      }
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Lấy viewModel từ context của widget Builder
    final viewModel = Provider.of<PostInteractionViewModel>(context, listen: false);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Post')
          .doc(post.id)
          .collection('reactions')
          .doc(currentUserDocId)
          .snapshots(),
      builder: (context, snapshot) {
        final isLiked = snapshot.hasData && snapshot.data!.exists;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => viewModel.toggleLike(currentUserDocId),
                icon: Icon(
                  isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: isLiked ? AppColors.primary : AppColors.textSecondary,
                ),
                label: Text('Thích', style: TextStyle(color: isLiked ? AppColors.primary : AppColors.textSecondary)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CommentSheet(
                      postId: post.id,
                      currentUserDocId: currentUserDocId,
                    ),
                  );
                },
                icon: const Icon(Icons.comment_outlined, color: AppColors.textSecondary),
                label: const Text('Bình luận', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
                label: const Text('Chia sẻ', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        );
      },
    );
  }
}