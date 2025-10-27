// lib/view/widgets/post/post_actions.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_post.dart'; // Cần cho ShareBottomSheet
import 'package:mangxahoi/view/widgets/comment_sheet.dart';
import 'package:mangxahoi/view/widgets/share_bottom_sheet.dart';
import 'package:mangxahoi/viewmodel/post_interaction_view_model.dart'; // ViewModel
import 'package:provider/provider.dart';

// --- Widget PostActions ---
class PostActions extends StatelessWidget {
  final PostModel post; // Cần post để truyền cho ShareBottomSheet
  final String currentUserDocId;

  const PostActions({
    super.key,
    required this.post,
    required this.currentUserDocId,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy ViewModel từ Provider được tạo ở PostWidget
    final viewModel = Provider.of<PostInteractionViewModel>(context, listen: false);

    // StreamBuilder để lắng nghe trạng thái like
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Post')
          .doc(post.id) // Sử dụng post.id thay vì _currentPost.id
          .collection('reactions')
          .doc(currentUserDocId)
          .snapshots(),
      builder: (context, snapshot) {
        // Không cần check connectionState vì StreamBuilder tự xử lý
        final isLiked = snapshot.hasData && snapshot.data!.exists;

        // --- Giao diện các nút ---
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // --- Nút Like ---
            _buildActionButton(
              icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              label: 'Thích',
              color: isLiked ? AppColors.primary : AppColors.textSecondary,
              onPressed: () => viewModel.toggleLike(currentUserDocId),
            ),
            // --- Nút Comment ---
            _buildActionButton(
              icon: Icons.comment_outlined,
              label: 'Bình luận',
              color: AppColors.textSecondary,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommentSheet(
                    postId: post.id, // Sử dụng post.id
                    currentUserDocId: currentUserDocId,
                  ),
                );
              },
            ),
            // --- Nút Share ---
            _buildActionButton(
              icon: Icons.share_outlined,
              label: 'Chia sẻ',
              color: AppColors.textSecondary,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  // isScrollControlled: true, // Không cần scroll cho share sheet nhỏ
                  backgroundColor: Colors.white, // Nền trắng cho share sheet
                   shape: const RoundedRectangleBorder( // Bo góc trên
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                   ),
                  builder: (_) => ShareBottomSheet(
                    post: post, // Truyền post vào ShareBottomSheet
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Helper widget để tạo nút action
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20), // Giảm size icon một chút
        label: Text(
          label,
          style: TextStyle(color: color, fontSize: 13), // Giảm size chữ
        ),
        style: TextButton.styleFrom(
           padding: const EdgeInsets.symmetric(vertical: 10), // Giảm padding
          // foregroundColor: color, // Màu chữ và icon khi nhấn
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Bo góc nhẹ
        ),
      ),
    );
  }
} // Kết thúc PostActions