import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/view/widgets/notification_settings_card.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..loadProfile(),
      child: const _ProfileContent(),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.user == null
              ? const Center(child: Text('Không tìm thấy thông tin người dùng'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(context, vm),
                      const SizedBox(height: 20),
                      _buildInfoSection(context, vm),
                      const SizedBox(height: 16),
                      //Cài đặt thông báo
                      NotificationSettingsCard(viewModel: vm),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton.icon(
                          onPressed: () => _showEditProfileDialog(context, vm),
                          icon: const Icon(Icons.edit),
                          label: const Text('Cập nhật hồ sơ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(BuildContext context, ProfileViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: vm.user!.avatar.isNotEmpty
                      ? NetworkImage(vm.user!.avatar.first)
                      : null,
                  child: vm.user!.avatar.isEmpty
                      ? const Icon(Icons.person, size: 60, color: Colors.blue)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Icon(Icons.camera_alt, size: 20, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            vm.user!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          if (vm.user!.bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                vm.user!.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Bài viết', vm.user!.posterList.length.toString()),
                _buildStatItem('Người theo dõi', vm.user!.followerCount.toString()),
                _buildStatItem('Bạn Bè', vm.user!.followingCount.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, ProfileViewModel vm) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _buildInfoRow(Icons.email, 'Email', vm.user!.email),
            _buildInfoRow(Icons.phone, 'Số điện thoại', vm.user!.phone),
            _buildInfoRow(Icons.cake, 'Ngày sinh',
                vm.user!.dateOfBirth?.toString().split(' ')[0] ?? 'Chưa có'),
            _buildInfoRow(Icons.wc, 'Giới tính', vm.user!.gender),
            _buildInfoRow(Icons.favorite, 'Tình trạng', vm.user!.relationship),
            _buildInfoRow(Icons.location_on, 'Sống tại', vm.user!.liveAt),
            _buildInfoRow(Icons.home, 'Quê quán', vm.user!.comeFrom),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty || value == 'Chưa có') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, ProfileViewModel vm) {
    final nameController = TextEditingController(text: vm.user!.name);
    final bioController = TextEditingController(text: vm.user!.bio);
    final phoneController = TextEditingController(text: vm.user!.phone);
    final liveAtController = TextEditingController(text: vm.user!.liveAt);
    final comeFromController = TextEditingController(text: vm.user!.comeFrom);

    String selectedGender = vm.user!.gender;
    String selectedRelationship = vm.user!.relationship;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Chỉnh sửa hồ sơ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(nameController, 'Họ tên', Icons.person),
                      const SizedBox(height: 16),
                      _buildTextField(bioController, 'Tiểu sử', Icons.info,
                          maxLines: 3),
                      const SizedBox(height: 16),
                      _buildTextField(
                          phoneController, 'Số điện thoại', Icons.phone),
                      const SizedBox(height: 16),
                      const Text('Giới tính',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedGender.isEmpty ? 'Nam' : selectedGender,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.wc),
                        ),
                        items: ['Nam', 'Nữ', 'Khác'].map((gender) {
                          return DropdownMenuItem(
                              value: gender, child: Text(gender));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedGender = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Tình trạng',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedRelationship.isEmpty
                            ? 'Độc thân'
                            : selectedRelationship,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.favorite),
                        ),
                        items: [
                          'Độc thân',
                          'Đang hẹn hò',
                          'Đã kết hôn',
                          'Phức tạp'
                        ].map((status) {
                          return DropdownMenuItem(
                              value: status, child: Text(status));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedRelationship = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                          liveAtController, 'Sống tại', Icons.location_on),
                      const SizedBox(height: 16),
                      _buildTextField(
                          comeFromController, 'Quê quán', Icons.home),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    vm.updateProfile(
                      name: nameController.text,
                      bio: bioController.text,
                      phone: phoneController.text,
                      gender: selectedGender,
                      relationship: selectedRelationship,
                      liveAt: liveAtController.text,
                      comeFrom: comeFromController.text,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('✅ Cập nhật hồ sơ thành công!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Lưu thay đổi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }
}