// lib/view/create_post_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/viewmodel/post_view_model.dart';
import 'package:mangxahoi/notification/notification_service.dart';

class CreatePostView extends StatelessWidget {
  const CreatePostView({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng ChangeNotifierProvider để cung cấp PostViewModel
    return ChangeNotifierProvider(
      create: (_) => PostViewModel(),
      child: const _CreatePostViewContent(),
    );
  }
}

class _CreatePostViewContent extends StatefulWidget {
  const _CreatePostViewContent();

  @override
  State<_CreatePostViewContent> createState() => _CreatePostViewContentState();
}

class _CreatePostViewContentState extends State<_CreatePostViewContent> {
  String _selectedVisibility = 'public'; // Mặc định là công khai

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bài viết mới'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Nút Đăng bài
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: viewModel.isLoading 
                  ? null 
                  : () async {
                      final success = await viewModel.createPost(_selectedVisibility);
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
              style: TextButton.styleFrom(
                backgroundColor: viewModel.isLoading 
                    ? AppColors.primary.withOpacity(0.5) 
                    : AppColors.primary, // Thay đổi màu nền nút
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mediumRadius,
                ),
              ),
              child: viewModel.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.textWhite,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Đăng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trường nhập nội dung
            TextFormField(
              controller: viewModel.contentController,
              autofocus: true,
              maxLines: null, // Cho phép nhiều dòng
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Bạn đang nghĩ gì?',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                filled: false,
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const Divider(height: 30),

            // Tùy chọn quyền riêng tư
            Row(
              children: [
                const Icon(Icons.public, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                const Text('Quyền riêng tư:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedVisibility,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedVisibility = newValue!;
                    });
                  },
                  items: <String>['public', 'private', 'friends']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(_getVisibilityIcon(value)),
                          const SizedBox(width: 8),
                          Text(_getVisibilityText(value)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const Divider(height: 30),

            // Nơi để thêm các nút thêm ảnh/video
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.photo_library, 'Ảnh/Video', () {
                  NotificationService().showInfoDialog(context: context, title: 'Tính năng đang phát triển', message: 'Chức năng chọn ảnh/video sẽ sớm có mặt!');
                }),
                _buildActionButton(Icons.tag_faces, 'Cảm xúc', () {
                  NotificationService().showInfoDialog(context: context, title: 'Tính năng đang phát triển', message: 'Chức năng thêm cảm xúc sẽ sớm có mặt!');
                }),
              ],
            ),
          ],
        ),
      ),
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

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.success),
      label: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
    );
  }
}