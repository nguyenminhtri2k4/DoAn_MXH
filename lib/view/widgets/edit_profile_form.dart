
import 'package:flutter/material.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:intl/intl.dart';

class EditProfileForm extends StatefulWidget {
  final ProfileViewModel viewModel;
  const EditProfileForm({super.key, required this.viewModel});

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  // ĐÃ XÓA _avatarController
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _liveAtController;
  late TextEditingController _comeFromController;

  late String _selectedGender;
  late String _selectedRelationship;
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final user = widget.viewModel.user!;
    _nameController = TextEditingController(text: user.name);
    _bioController = TextEditingController(text: user.bio);
    _phoneController = TextEditingController(text: user.phone);
    _liveAtController = TextEditingController(text: user.liveAt);
    _comeFromController = TextEditingController(text: user.comeFrom);
    _selectedGender = user.gender;
    _selectedRelationship = user.relationship;
    _selectedDate = user.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _liveAtController.dispose();
    _comeFromController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chọn ngày sinh';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _handleSaveChanges() {
    widget.viewModel.updateProfile(
      name: _nameController.text,
      bio: _bioController.text,
      phone: _phoneController.text,
      gender: _selectedGender,
      relationship: _selectedRelationship,
      liveAt: _liveAtController.text,
      comeFrom: _comeFromController.text,
      dateOfBirth: _selectedDate,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Cập nhật hồ sơ thành công!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ĐÃ XÓA TRƯỜNG NHẬP AVATAR
                _buildTextField(_nameController, 'Họ tên', Icons.person),
                const SizedBox(height: 16),
                _buildTextField(_bioController, 'Tiểu sử', Icons.info, maxLines: 3),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, 'Số điện thoại', Icons.phone),
                const SizedBox(height: 16),
                const Text('Ngày sinh', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.cake),
                    ),
                    child: Text(_formatDate(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                //... Các trường còn lại giữ nguyên
                 const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGender.isEmpty ? null : _selectedGender,
                  hint: const Text('Chọn giới tính'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.wc),
                  ),
                  items: ['Nam', 'Nữ', 'Khác'].map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedGender = value);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Tình trạng', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedRelationship.isEmpty ? null : _selectedRelationship,
                  hint: const Text('Chọn tình trạng quan hệ'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.favorite),
                  ),
                  items: ['Độc thân', 'Đang hẹn hò', 'Đã kết hôn', 'Phức tạp']
                      .map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedRelationship = value);
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(_liveAtController, 'Sống tại', Icons.location_on),
                const SizedBox(height: 16),
                _buildTextField(_comeFromController, 'Quê quán', Icons.home),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleSaveChanges,
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
    );
  }

  Widget _buildTextField(
    TextEditingController controller, String label, IconData icon,
    {int maxLines = 1}
  ) {
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