

import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_media.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/notification/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SharePostView extends StatefulWidget {
  final PostModel originalPost;
  final UserModel currentUser;

  const SharePostView({
    super.key,
    required this.originalPost,
    required this.currentUser,
  });

  @override
  State<SharePostView> createState() => _SharePostViewState();
}

class _SharePostViewState extends State<SharePostView> {
  final _contentController = TextEditingController();
  String _selectedVisibility = 'public';
  bool _isLoading = false;

  void _handleSharePost() async {
    setState(() => _isLoading = true);
    try {
      await PostRequest().sharePost(
        originalPost: widget.originalPost,
        sharerId: widget.currentUser.id,
        content: _contentController.text.trim(),
        visibility: _selectedVisibility,
      );

      if (mounted) {
        Navigator.pop(context); // Quay về màn hình trước đó
        NotificationService().showSuccessDialog(
          context: context,
          title: 'Thành công',
          message: 'Bài viết đã được chia sẻ!',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService().showErrorDialog(
          context: context,
          title: 'Lỗi',
          message: 'Không thể chia sẻ bài viết. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chia sẻ bài viết'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
        foregroundColor: AppColors.textPrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSharePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Đăng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildUserInfo(),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              autofocus: true,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'Hãy nói gì đó về bài viết này...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 20, color: AppColors.textDisabled),
              ),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            _buildOriginalPostPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: widget.currentUser.avatar.isNotEmpty
              ? NetworkImage(widget.currentUser.avatar.first)
              : null,
          child: widget.currentUser.avatar.isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.currentUser.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: _showVisibilityPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getVisibilityIcon(_selectedVisibility), size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _getVisibilityText(_selectedVisibility),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalPostPreview() {
    final originalPost = widget.originalPost;
    final listener = context.watch<FirestoreListener>();
    final originalAuthor = listener.getUserById(originalPost.authorId);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: (originalAuthor?.avatar.isNotEmpty ?? false) ? NetworkImage(originalAuthor!.avatar.first) : null,
                  child: (originalAuthor?.avatar.isEmpty ?? true) ? const Icon(Icons.person, size: 20) : null,
                ),
                const SizedBox(width: 10),
                Text(originalAuthor?.name ?? '...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            )
          ),
          if (originalPost.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
              child: Text(originalPost.content, style: const TextStyle(fontSize: 16)),
            ),
          if (originalPost.mediaIds.isNotEmpty)
            _buildOriginalPostMedia(context, originalPost),
        ],
      ),
    );
  }

   Widget _buildOriginalPostMedia(BuildContext context, PostModel originalPost) {
    final listener = context.read<FirestoreListener>();
    final mediaId = originalPost.mediaIds.first;
    final media = listener.getMediaById(mediaId);

    if (media == null) {
      return Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: Text('Không thể tải media')),
      );
    }

    // Nếu là video, hiển thị placeholder
    if (media.type == 'video') {
      return AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                  child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
              ),
          ),
      );
    }

    // Nếu là ảnh, hiển thị ảnh như bình thường
    return CachedNetworkImage(
      imageUrl: media.url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
        ),
    );
  }

  void _showVisibilityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(_getVisibilityIcon('public')),
              title: const Text('Công khai'),
              onTap: () {
                setState(() => _selectedVisibility = 'public');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(_getVisibilityIcon('friends')),
              title: const Text('Bạn bè'),
              onTap: () {
                setState(() => _selectedVisibility = 'friends');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(_getVisibilityIcon('private')),
              title: const Text('Chỉ mình tôi'),
              onTap: () {
                setState(() => _selectedVisibility = 'private');
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getVisibilityIcon(String visibility) {
    switch (visibility) {
      case 'private': return Icons.lock;
      case 'friends': return Icons.group;
      default: return Icons.public;
    }
  }

  String _getVisibilityText(String visibility) {
    switch (visibility) {
      case 'private': return 'Chỉ mình tôi';
      case 'friends': return 'Bạn bè';
      default: return 'Công khai';
    }
  }
}