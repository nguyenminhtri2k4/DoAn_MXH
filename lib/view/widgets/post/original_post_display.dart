// lib/view/widgets/post/original_post_display.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:provider/provider.dart';
// import 'post_header.dart'; // Không dùng header chung nữa
import 'post_content.dart';
import 'post_media.dart';
import 'package:flutter/gestures.dart'; // Cần cho TapGestureRecognizer
import 'package:mangxahoi/constant/app_colors.dart'; // Cần cho màu sắc


// --- Widget OriginalPostDisplay ---
class OriginalPostDisplay extends StatelessWidget {
  final String originalPostId;
  final String currentUserDocId;
  final String Function(DateTime) formatTimestamp;

  const OriginalPostDisplay({
    super.key,
    required this.originalPostId,
    required this.currentUserDocId,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Post')
          .doc(originalPostId)
          .snapshots(),
      builder: (context, snapshot) {
        // --- Trạng thái Loading ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        // --- Trạng thái Lỗi hoặc Không tồn tại ---
        if (!snapshot.hasData || !snapshot.data!.exists || snapshot.hasError) {
          return _buildInfoContainer('Bài viết gốc không còn tồn tại hoặc đã bị xóa.');
        }

        // --- Xử lý dữ liệu ---
        try {
           final originalPostData = snapshot.data!.data() as Map<String, dynamic>;

          // Kiểm tra status 'deleted'
          if (originalPostData['status'] == 'deleted') {
            return _buildInfoContainer('Bài viết gốc đã bị xóa.');
          }

          final originalPost = PostModel.fromMap(snapshot.data!.id, originalPostData);
          final listener = context.read<FirestoreListener>();
          final originalAuthor = listener.getUserById(originalPost.authorId);

          // --- Hiển thị bài viết gốc ---
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header của bài gốc (không có nút options) ---
                // <<< SỬA LỖI PADDING Ở ĐÂY >>>
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _OriginalPostHeaderInternal( // Thêm child:
                     author: originalAuthor,
                     createdAt: originalPost.createdAt,
                     formatTimestamp: formatTimestamp,
                   ),
                ),
                // <<< KẾT THÚC SỬA LỖI PADDING >>>

                // --- Content của bài gốc ---
                if (originalPost.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                    child: PostContent(content: originalPost.content),
                  ),
                // --- Media của bài gốc ---
                if (originalPost.mediaIds.isNotEmpty)
                   PostMedia(
                     key: ValueKey('original_media_${originalPost.id}'),
                     mediaIds: originalPost.mediaIds
                    ),
              ],
            ),
          );
        } catch (e) {
           print("Lỗi khi parse original post: $e");
           return _buildInfoContainer('Lỗi hiển thị bài viết gốc.');
        }
      },
    );
  }

  // Helper widget để hiển thị thông báo
  Widget _buildInfoContainer(String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }
} // Kết thúc OriginalPostDisplay


// --- Widget _OriginalPostHeaderInternal (Private) ---
// (Giữ nguyên không đổi so với lần trước)
class _OriginalPostHeaderInternal extends StatelessWidget {
  final UserModel? author;
  final DateTime createdAt;
  final String Function(DateTime) formatTimestamp;
  // final String? groupId; // Không cần groupId nữa

  const _OriginalPostHeaderInternal({
    required this.author,
    required this.createdAt,
    required this.formatTimestamp,
    // this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    if (author == null) return const SizedBox.shrink();

    // final listener = context.read<FirestoreListener>();
    // final group = groupId != null && groupId!.isNotEmpty ? listener.getGroupById(groupId!) : null;
    // final isGroupPost = group != null; // Không cần thiết nữa

    final String timestamp = formatTimestamp(createdAt);

    Widget avatarWidget;
    Widget titleWidget;
    Widget subtitleWidget;

    // Chỉ cần hiển thị thông tin tác giả bài gốc
     avatarWidget = GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/profile', arguments: author!.id),
        child: CircleAvatar(
          radius: 20,
          backgroundImage: (author!.avatar.isNotEmpty) ? NetworkImage(author!.avatar.first) : null,
          child: (author!.avatar.isEmpty) ? const Icon(Icons.person, size: 20) : null,
        ),
      );

     titleWidget = GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/profile', arguments: author!.id),
        child: Text(author!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );

      subtitleWidget = Text(timestamp, style: const TextStyle(color: Colors.grey, fontSize: 13));


    return Row(
      children: [
        avatarWidget,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 2),
              subtitleWidget,
            ],
          ),
        ),
        // No options button here
      ],
    );
  }
} // Kết thúc _OriginalPostHeaderInternal