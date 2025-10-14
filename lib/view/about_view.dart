
import 'package:flutter/material.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:intl/intl.dart';

class AboutView extends StatelessWidget {
  final ProfileViewModel viewModel;
  final bool isCurrentUser;

  const AboutView({
    super.key,
    required this.viewModel,
    required this.isCurrentUser,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa cung cấp';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // HÀM MỚI ĐỂ HIỂN THỊ DIALOG CHỈNH SỬA AVATAR
  void _showEditAvatarDialog(BuildContext context) {
    final avatarController = TextEditingController(
      text: viewModel.user!.avatar.isNotEmpty ? viewModel.user!.avatar.first : ''
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thay đổi ảnh đại diện'),
          content: TextField(
            controller: avatarController,
            decoration: const InputDecoration(
              labelText: 'URL ảnh đại diện mới',
              hintText: 'https://example.com/image.png',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                viewModel.updateAvatar(avatarController.text);
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = viewModel.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giới thiệu'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ==================== MỤC ẢNH ĐẠI DIỆN MỚI ====================
            _buildSection(
              context: context,
              title: 'Ảnh đại diện',
              isCurrentUser: isCurrentUser,
              onEdit: () => _showEditAvatarDialog(context),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: user.avatar.isNotEmpty
                        ? NetworkImage(user.avatar.first)
                        : null,
                    child: user.avatar.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // =============================================================
            _buildSection(
              context: context,
              title: 'Thông tin liên hệ',
              isCurrentUser: false, // Không cần nút sửa ở đây nữa
              children: [
                _buildInfoRow(Icons.email_outlined, 'Email', user.email),
                _buildInfoRow(Icons.phone_outlined, 'Di động', user.phone),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: 'Thông tin cơ bản',
              isCurrentUser: false,
              children: [
                _buildInfoRow(Icons.wc_outlined, 'Giới tính', user.gender),
                _buildInfoRow(Icons.cake_outlined, 'Ngày sinh', _formatDate(user.dateOfBirth)),
                _buildInfoRow(Icons.favorite_outline, 'Tình trạng quan hệ', user.relationship),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context: context,
              title: 'Nơi từng sống',
              isCurrentUser: false,
              children: [
                _buildInfoRow(Icons.home_work_outlined, 'Nơi ở hiện tại', user.liveAt),
                _buildInfoRow(Icons.location_on_outlined, 'Quê quán', user.comeFrom),
              ],
            ),
            const SizedBox(height: 24),
           if (isCurrentUser)
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                onPressed: () {
                    Navigator.pushNamed(context, '/edit_profile', arguments: viewModel);
                },
                icon: Icon(
                    Icons.edit_note,
                    color: AppColors.textWhite, // 👈 icon cùng màu với chữ
                ),
                label: const Text('Chỉnh sửa chi tiết'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    elevation: 0,
                ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    required bool isCurrentUser,
    VoidCallback? onEdit,
  }) {
    // ... (Giữ nguyên không thay đổi)
        final visibleChildren = children.where((child) => child is! SizedBox).toList();
    
    if (visibleChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (isCurrentUser && onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                  onPressed: onEdit,
                ),
            ],
          ),
          const Divider(height: 24),
          ...visibleChildren, // Chỉ hiển thị các dòng có nội dung
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String subText, String mainText) {
    if (mainText.isEmpty || mainText == 'Chưa cung cấp') {
      return const SizedBox.shrink();
    }
    // ... (Giữ nguyên không thay đổi)
        return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mainText, style: const TextStyle(fontSize: 16)),
                if (subText != null && subText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      subText,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}