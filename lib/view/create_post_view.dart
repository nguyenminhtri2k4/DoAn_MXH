import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/viewmodel/post_view_model.dart';
import 'package:mangxahoi/notification/notification_service.dart';

class CreatePostView extends StatelessWidget {
  final UserModel currentUser;
  const CreatePostView({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostViewModel(),
      child: _CreatePostViewContent(currentUser: currentUser),
    );
  }
}

class _CreatePostViewContent extends StatefulWidget {
  final UserModel currentUser;
  const _CreatePostViewContent({required this.currentUser});

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
        title: const Text('Tạo bài viết'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: viewModel.isLoading 
                  ? null 
                  : () async {
                      final success = await viewModel.createPost(
                        authorDocId: widget.currentUser.id, 
                        visibility: _selectedVisibility
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
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: viewModel.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Đăng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            // ====> WIDGET CHỌN QUYỀN RIÊNG TƯ <====
                            DropdownButton<String>(
                              value: _selectedVisibility,
                              underline: const SizedBox(), // Bỏ gạch chân
                              isDense: true,
                              items: <String>['public', 'friends', 'private']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      Icon(_getVisibilityIcon(value), size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 8),
                                      Text(_getVisibilityText(value)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedVisibility = newValue!;
                                });
                              },
                            ),
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
                      hintStyle: TextStyle(fontSize: 20),
                    ),
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // ====> CÁC NÚT CHỨC NĂNG <====
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Ảnh/Video',
                  color: Colors.green,
                  onPressed: () {
                    // TODO: Mở thư viện ảnh/video
                    NotificationService().showInfoDialog(context: context, title: 'Đang phát triển', message: 'Chức năng chọn ảnh/video sẽ sớm có mặt!');
                  },
                ),
                _buildActionButton(
                  icon: Icons.person_add,
                  label: 'Gắn thẻ',
                  color: Colors.blue,
                  onPressed: () {
                    // TODO: Mở màn hình chọn bạn bè để gắn thẻ
                    NotificationService().showInfoDialog(context: context, title: 'Đang phát triển', message: 'Chức năng gắn thẻ bạn bè sẽ sớm có mặt!');
                  },
                ),
                _buildActionButton(
                  icon: Icons.tag_faces,
                  label: 'Cảm xúc',
                  color: Colors.orange,
                  onPressed: () {
                    // TODO: Mở bảng chọn cảm xúc
                    NotificationService().showInfoDialog(context: context, title: 'Đang phát triển', message: 'Chức năng thêm cảm xúc sẽ sớm có mặt!');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper để lấy icon tương ứng
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

  // Helper để lấy text tương ứng
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

  // Helper để tạo nút chức năng
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