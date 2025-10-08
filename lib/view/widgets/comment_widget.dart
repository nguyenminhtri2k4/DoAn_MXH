import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/model/model_comment.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';

class CommentWidget extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onReply; // Hàm callback khi nhấn nút "Trả lời"
  final bool isReply; // Biến để xác định đây có phải là reply không

  const CommentWidget({
    super.key,
    required this.comment,
    required this.onReply,
    this.isReply = false, // Mặc định không phải là reply
  });

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin tác giả của bình luận
    final author = context.select<FirestoreListener, UserModel?>(
      (listener) => listener.getUserById(comment.authorId),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 16 : 20, // Avatar của reply nhỏ hơn
            backgroundImage: (author?.avatar.isNotEmpty ?? false)
                ? NetworkImage(author!.avatar.first)
                : null,
            child: (author?.avatar.isEmpty ?? true) ? Icon(Icons.person, size: isReply ? 16 : 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author?.name ?? 'Người dùng',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(comment.content, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Hàng chứa các nút chức năng (Like, Reply)
                Row(
                  children: [
                    Text(
                      'Thích',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        'Trả lời',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}