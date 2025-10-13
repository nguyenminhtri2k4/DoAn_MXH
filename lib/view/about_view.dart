// import 'package:flutter/material.dart';
// import 'package:mangxahoi/viewmodel/profile_view_model.dart';
// import 'package:mangxahoi/constant/app_colors.dart';
// import 'package:intl/intl.dart';

// class AboutView extends StatelessWidget {
//   final ProfileViewModel viewModel;
//   final bool isCurrentUser; // Biến xác định có phải chủ nhân profile không

//   const AboutView({
//     super.key,
//     required this.viewModel,
//     required this.isCurrentUser,
//   });

//   String _formatDate(DateTime? date) {
//     if (date == null) return 'Chưa cung cấp';
//     return DateFormat('dd/MM/yyyy').format(date);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = viewModel.user!;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Giới thiệu'),
//         backgroundColor: AppColors.backgroundLight,
//         elevation: 1,
//       ),
//       backgroundColor: AppColors.background,
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // ==================== HEADER VỚI AVATAR VÀ TÊN ====================
//             Container(
//               color: Colors.white,
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundColor: Colors.grey.shade300,
//                     backgroundImage: user.avatar.isNotEmpty
//                         ? NetworkImage(user.avatar.first)
//                         : null,
//                     child: user.avatar.isEmpty
//                         ? const Icon(Icons.person, size: 50, color: Colors.grey)
//                         : null,
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     user.name,
//                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                   ),
//                    if (user.bio.isNotEmpty && user.bio != "No")
//                     Padding(
//                       padding: const EdgeInsets.only(top: 4.0),
//                       child: Text(
//                         user.bio,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             // =================================================================

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Column(
//                 children: [
//                   // Phần thông tin liên hệ
//                   _buildSection(
//                     title: 'Thông tin liên hệ',
//                     children: [
//                       _buildInfoRow(
//                         icon: Icons.email_outlined,
//                         mainText: user.email,
//                         subText: 'Email',
//                       ),
//                       _buildInfoRow(
//                         icon: Icons.phone_outlined,
//                         mainText: user.phone,
//                         subText: 'Di động',
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   // Phần thông tin cơ bản
//                   _buildSection(
//                     title: 'Thông tin cơ bản',
//                     children: [
//                       _buildInfoRow(
//                         icon: Icons.wc_outlined,
//                         mainText: user.gender,
//                         subText: 'Giới tính',
//                       ),
//                       _buildInfoRow(
//                         icon: Icons.cake_outlined,
//                         mainText: _formatDate(user.dateOfBirth),
//                         subText: 'Ngày sinh',
//                       ),
//                       _buildInfoRow(
//                         icon: Icons.favorite_outline,
//                         mainText: user.relationship,
//                         subText: 'Tình trạng quan hệ',
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   // Phần nơi sống
//                   _buildSection(
//                     title: 'Nơi từng sống',
//                     children: [
//                       _buildInfoRow(
//                         icon: Icons.home_work_outlined,
//                         mainText: user.liveAt,
//                         subText: 'Nơi ở hiện tại',
//                       ),
//                       _buildInfoRow(
//                         icon: Icons.location_on_outlined,
//                         mainText: user.comeFrom,
//                         subText: 'Quê quán',
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
//                   // Nút cập nhật hồ sơ
//                   if (isCurrentUser)
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.pushNamed(context, '/edit_profile', arguments: viewModel);
//                         },
//                         icon: const Icon(Icons.edit),
//                         label: const Text('Cập nhật hồ sơ'),
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           backgroundColor: AppColors.backgroundDark,
//                           foregroundColor: AppColors.textPrimary,
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSection({
//     required String title,
//     required List<Widget> children,
//   }) {
//     final visibleChildren = children.where((child) => child is! SizedBox).toList();
    
//     if (visibleChildren.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//           const Divider(height: 24),
//           ...visibleChildren,
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow({
//     required IconData icon,
//     required String mainText,
//     String? subText,
//   }) {
//     if (mainText.isEmpty || mainText == 'Chưa cung cấp') {
//       return const SizedBox.shrink();
//     }
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: AppColors.textSecondary, size: 24),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(mainText, style: const TextStyle(fontSize: 16)),
//                 if (subText != null && subText.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 2.0),
//                     child: Text(
//                       subText,
//                       style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
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