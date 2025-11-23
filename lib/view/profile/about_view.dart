
import 'package:flutter/material.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:mangxahoi/view/profile/user_qr_code_view.dart';

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

  // <--- SỬA LỖI: THAY ĐỔI TOÀN BỘ HÀM NÀY --->
  void _pickAvatar(BuildContext context) async { // Thêm async
    final success = await viewModel.pickAndUpdateAvatar(); // Await kết quả
    
    // Kiểm tra context còn tồn tại trước khi dùng
    if (!context.mounted) return; 

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Cập nhật ảnh đại diện thành công!'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      // (Tùy chọn) Hiển thị thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('Cập nhật thất bại. Vui lòng thử lại.'),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
  // <--- KẾT THÚC SỬA ĐỔI --->

  @override
  Widget build(BuildContext context) {
    // Chúng ta không cần Consumer ở đây vì viewModel được truyền vào
    // và chúng ta xử lý logic trong hàm _pickAvatar
    final user = viewModel.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giới thiệu'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
        actions: [
          if (isCurrentUser) // Chỉ hiện nút QR nếu đây là trang của chính mình
            IconButton(
              icon: const Icon(Icons.qr_code, color: Colors.black87),
              tooltip: 'Mã QR của tôi',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserQRCodeView(user: user),
                  ),
                );
              },
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSection(
              context: context,
              title: 'Ảnh đại diện',
              isCurrentUser: isCurrentUser,
              onEdit: () => _pickAvatar(context), // <--- Gọi hàm đã sửa
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
            _buildSection(
              context: context,
              title: 'Thông tin liên hệ',
              isCurrentUser: false,
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
                    color: AppColors.textWhite,
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
          ...visibleChildren,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String subText, String mainText) {
    if (mainText.isEmpty || mainText == 'Chưa cung cấp') {
      return const SizedBox.shrink();
    }
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