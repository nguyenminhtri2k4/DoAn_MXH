
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/viewmodel/post_view_model.dart';
import 'package:mangxahoi/notification/notification_service.dart';
import 'package:video_player/video_player.dart';

class CreatePostView extends StatelessWidget {
  final UserModel currentUser;
  final String? groupId;

  const CreatePostView({
    super.key,
    required this.currentUser,
    this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostViewModel(),
      child: _CreatePostViewContent(
        currentUser: currentUser,
        groupId: groupId,
      ),
    );
  }
}

class _CreatePostViewContent extends StatefulWidget {
  final UserModel currentUser;
  final String? groupId;

  const _CreatePostViewContent({
    required this.currentUser,
    this.groupId,
  });

  @override
  State<_CreatePostViewContent> createState() => _CreatePostViewContentState();
}

class _CreatePostViewContentState extends State<_CreatePostViewContent> {
  String _selectedVisibility = 'public';

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo bài viết'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
        foregroundColor: AppColors.textPrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: viewModel.isLoading
                  ? null
                  : () async {
                      final success = await viewModel.createPost(
                        authorDocId: widget.currentUser.id,
                        visibility: _selectedVisibility,
                        groupId: widget.groupId,
                      );

                      if (success && mounted) {
                        Navigator.pop(context);
                        NotificationService().showSuccessDialog(
                          context: context,
                          title: 'Thành công',
                          message: 'Bài viết của bạn đã được đăng!',
                        );
                      } else if (viewModel.errorMessage != null && mounted) {
                        NotificationService().showErrorDialog(
                          context: context,
                          title: 'Lỗi đăng bài',
                          message: viewModel.errorMessage!,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: viewModel.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Đăng',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
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
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
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
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: viewModel.contentController,
                    autofocus: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Bạn đang nghĩ gì?',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 24, color: AppColors.textDisabled),
                    ),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  _buildMediaPreview(viewModel),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.backgroundLight,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Ảnh',
                  color: Colors.green,
                  onPressed: () => viewModel.pickImages(),
                ),
                _buildActionButton(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.red,
                  onPressed: () => viewModel.pickVideo(),
                ),
                _buildActionButton(
                  icon: Icons.person_add,
                  label: 'Gắn thẻ',
                  color: Colors.blue,
                  onPressed: () {
                    NotificationService().showInfoDialog(context: context, title: 'Đang phát triển', message: 'Chức năng gắn thẻ bạn bè sẽ sớm có mặt!');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(PostViewModel viewModel) {
    if (viewModel.selectedImages.isNotEmpty) {
      return _buildImagePreview(viewModel);
    }
    if (viewModel.selectedVideo != null) {
      return _buildVideoPreview(viewModel);
    }
    return const SizedBox.shrink();
  }

  Widget _buildImagePreview(PostViewModel viewModel) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: viewModel.selectedImages.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                viewModel.selectedImages[index],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => viewModel.removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideoPreview(PostViewModel viewModel) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black,
            ),
            child: const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => viewModel.removeVideo(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
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
              subtitle: const Text('Mọi người đều có thể xem'),
              onTap: () {
                setState(() => _selectedVisibility = 'public');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(_getVisibilityIcon('friends')),
              title: const Text('Bạn bè'),
              subtitle: const Text('Chỉ bạn bè của bạn có thể xem'),
              onTap: () {
                setState(() => _selectedVisibility = 'friends');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(_getVisibilityIcon('private')),
              title: const Text('Chỉ mình tôi'),
              subtitle: const Text('Chỉ bạn mới có thể xem'),
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
      case 'private':
        return Icons.lock;
      case 'friends':
        return Icons.group;
      case 'public':
      default:
        return Icons.public;
    }
  }

  String _getVisibilityText(String visibility) {
    switch (visibility) {
      case 'private':
        return 'Chỉ mình tôi';
      case 'friends':
        return 'Bạn bè';
      case 'public':
      default:
        return 'Công khai';
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}