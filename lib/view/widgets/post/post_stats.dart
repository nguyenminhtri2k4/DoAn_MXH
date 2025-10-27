// lib/view/widgets/post/post_stats.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/constant/app_colors.dart';

// --- Widget PostStats ---
class PostStats extends StatelessWidget {
  final String postId;

  const PostStats({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder để lắng nghe thay đổi likesCount, commentsCount
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Post')
            .doc(postId)
            .snapshots(),
        builder: (context, snapshot) {
          // Trạng thái loading hoặc chưa có dữ liệu
          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
            // Có thể hiển thị một placeholder nhỏ nếu muốn
            return const SizedBox(height: 8); // Giữ chiều cao cố định
          }

          final postData = snapshot.data!.data() as Map<String, dynamic>?;
          final likes = postData?['likesCount'] as int? ?? 0;
          final comments = postData?['commentsCount'] as int? ?? 0;

          // Chỉ hiển thị nếu có like hoặc comment
          if (likes == 0 && comments == 0) {
            return const SizedBox(height: 8); // Giữ chiều cao cố định
          }

          // Giao diện hiển thị
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding gốc
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chỉ hiển thị text nếu > 0
                if (likes > 0)
                  Text('$likes lượt thích', style: const TextStyle(color: AppColors.textSecondary)),
                // Spacer để đẩy bình luận sang phải nếu không có like
                 if (likes == 0 && comments > 0) const Spacer(),
                 if (comments > 0)
                  Text('$comments bình luận', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        });
  }
}