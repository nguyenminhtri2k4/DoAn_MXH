// lib/view/widgets/post/post_header.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:provider/provider.dart';

// --- Widget PostHeader ---
class PostHeader extends StatelessWidget {
  final PostModel post;
  final UserModel? author;
  final String currentUserDocId;
  final VoidCallback onShowOwnerOptions;
  final VoidCallback onShowGuestOptions;
  final VoidCallback onShowPrivacyPicker;
  final String Function(DateTime) formatTimestamp; // Hàm helper từ PostWidget
  final IconData Function(String) getVisibilityIcon; // Hàm helper
  final String Function(String) getVisibilityText;   // Hàm helper

  const PostHeader({
    super.key,
    required this.post,
    required this.author,
    required this.currentUserDocId,
    required this.onShowOwnerOptions,
    required this.onShowGuestOptions,
    required this.onShowPrivacyPicker,
    required this.formatTimestamp,
    required this.getVisibilityIcon,
    required this.getVisibilityText,
  });

  @override
  Widget build(BuildContext context) {
    if (author == null) return const SizedBox.shrink(); // Trường hợp author chưa load kịp

    final listener = context.read<FirestoreListener>(); // Dùng read vì chỉ cần lấy dữ liệu 1 lần
    final group = post.groupId != null && post.groupId!.isNotEmpty
        ? listener.getGroupById(post.groupId!)
        : null;
    final isGroupPost = group != null;
    final isOwner = currentUserDocId == post.authorId;

    final String timestamp = formatTimestamp(post.createdAt); // Sử dụng hàm helper

    // Widget avatar, title, subtitle
    Widget avatarWidget;
    Widget titleWidget;
    Widget subtitleWidget;

    if (isGroupPost && group != null) { // Thêm kiểm tra group != null
      // --- Bố cục bài đăng nhóm ---
      avatarWidget = GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/post_group', arguments: group),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.backgroundDark,
          child: Text(
            group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      );
      titleWidget = GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/post_group', arguments: group),
        child: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );
      subtitleWidget = RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          children: [
            TextSpan(
              text: author!.name, // Đã kiểm tra null ở đầu
              style: const TextStyle(fontWeight: FontWeight.w600),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.pushNamed(context, '/profile', arguments: author!.id),
            ),
            TextSpan(text: ' • $timestamp'),
          ],
        ),
      );
    } else {
      // --- Bố cục bài đăng cá nhân ---
      avatarWidget = GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/profile', arguments: author!.id), // Đã kiểm tra null
        child: CircleAvatar(
          radius: 20,
          backgroundImage: (author!.avatar.isNotEmpty) ? NetworkImage(author!.avatar.first) : null,
          child: (author!.avatar.isEmpty) ? const Icon(Icons.person, size: 20) : null,
        ),
      );
      titleWidget = GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/profile', arguments: author!.id), // Đã kiểm tra null
        child: Text(author!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );
      subtitleWidget = Text(timestamp, style: const TextStyle(color: Colors.grey, fontSize: 13));
    }

    // --- Giao diện chung ---
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
        // --- Nút Privacy và Options ---
        if (isOwner) ...[
          _buildPrivacyButton(context), // Nút riêng tư
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: onShowOwnerOptions, // Gọi callback từ PostWidget
          ),
        ] else ...[
          // Nút 3 chấm cho người xem
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: onShowGuestOptions, // Gọi callback từ PostWidget
          ),
        ]
      ],
    );
  }

  // Hàm build nút Privacy (giữ lại ở đây vì chỉ dùng cho header của chủ bài viết)
  Widget _buildPrivacyButton(BuildContext context) {
    return InkWell(
      onTap: onShowPrivacyPicker, // Gọi callback từ PostWidget
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Giữ kích thước nhỏ gọn
          children: [
            Icon(getVisibilityIcon(post.visibility), size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              getVisibilityText(post.visibility),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
} // Kết thúc PostHeader