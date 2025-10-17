

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_group.dart';
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
    final listener = context.watch<FirestoreListener>();
    final author = listener.getUserById(post.authorId);
    // Lấy thông tin nhóm nếu bài viết có groupId
    final group = post.groupId != null && post.groupId!.isNotEmpty
        ? listener.getGroupById(post.groupId!)
        : null;

    return ChangeNotifierProvider(
      key: ValueKey(post.id),
      create: (_) => PostInteractionViewModel(post.id),
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostHeader(context, author, group), // Truyền group vào header
              const SizedBox(height: 12),
              if (post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(post.content, style: const TextStyle(fontSize: 16)),
                ),
              // Có thể thêm hiển thị ảnh/video ở đây nếu có
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

  Widget _buildPostHeader(BuildContext context, UserModel? author, GroupModel? group) {
    if (author == null) return const SizedBox.shrink();

    final String timestamp = '${post.createdAt.hour.toString().padLeft(2, '0')}:${post.createdAt.minute.toString().padLeft(2, '0')} · ${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}';

    // ==========================================================
    // LOGIC MỚI: HIỂN THỊ TIÊU ĐỀ BÀI ĐĂNG NHÓM
    // ==========================================================
    if (group != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar của nhóm, khi nhấn vào sẽ đến trang nhóm
          GestureDetector(
            onTap: () {
              if (group.type == 'post') {
                Navigator.pushNamed(context, '/post_group', arguments: group);
              }
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.groups, size: 20, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên nhóm (chữ to, đậm), khi nhấn vào sẽ đến trang nhóm
                GestureDetector(
                  onTap: () {
                    if (group.type == 'post') {
                      Navigator.pushNamed(context, '/post_group', arguments: group);
                    }
                  },
                  child: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                // Tên tác giả và thời gian (chữ nhỏ)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile', arguments: author.id),
                      child: Text(
                        author.name,
                        style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Text(' · ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                     Text(timestamp, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Giao diện mặc định cho bài đăng cá nhân (như cũ)
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile', arguments: author.id),
      child: Row(
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
              Text(author.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                timestamp,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(likes > 0 ? '$likes lượt thích' : '', style: const TextStyle(color: AppColors.textSecondary)),
              Text(comments > 0 ? '$comments bình luận' : '', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildActionButtons(BuildContext context) {
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