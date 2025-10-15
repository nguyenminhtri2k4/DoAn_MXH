
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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Cập nhật hồ sơ thành công!'),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card cho thông tin cá nhân
                _buildSectionCard(
                  title: 'Thông tin cá nhân',
                  icon: Icons.person_outline,
                  children: [
                    _buildTextField(_nameController, 'Họ tên', Icons.person),
                    const SizedBox(height: 20),
                    _buildTextField(_bioController, 'Tiểu sử', Icons.info_outline, maxLines: 3),
                    const SizedBox(height: 20),
                    _buildTextField(_phoneController, 'Số điện thoại', Icons.phone),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Card cho ngày sinh và giới tính
                _buildSectionCard(
                  title: 'Thông tin cơ bản',
                  icon: Icons.cake_outlined,
                  children: [
                    _buildDatePicker(),
                    const SizedBox(height: 20),
                    _buildGenderDropdown(),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Card cho tình trạng và địa chỉ
                _buildSectionCard(
                  title: 'Tình trạng & Địa chỉ',
                  icon: Icons.favorite_outline,
                  children: [
                    _buildRelationshipDropdown(),
                    const SizedBox(height: 20),
                    _buildTextField(_liveAtController, 'Sống tại', Icons.location_on_outlined),
                    const SizedBox(height: 20),
                    _buildTextField(_comeFromController, 'Quê quán', Icons.home_outlined),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        
        // Nút lưu với shadow đẹp
        Container(
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
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: _handleSaveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Lưu thay đổi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF5D6D7E),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ngày sinh',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF5D6D7E),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.cake, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Text(
                  _formatDate(_selectedDate),
                  style: TextStyle(
                    fontSize: 15,
                    color: _selectedDate == null ? Colors.grey[600] : Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, color: Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới tính',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF5D6D7E),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender.isEmpty ? null : _selectedGender,
          hint: const Text('Chọn giới tính'),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            prefixIcon: Icon(Icons.wc, color: AppColors.primary, size: 22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: ['Nam', 'Nữ', 'Khác'].map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Text(gender, style: const TextStyle(fontSize: 15)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedGender = value);
          },
        ),
      ],
    );
  }

  Widget _buildRelationshipDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tình trạng quan hệ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF5D6D7E),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRelationship.isEmpty ? null : _selectedRelationship,
          hint: const Text('Chọn tình trạng'),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            prefixIcon: Icon(Icons.favorite, color: AppColors.primary, size: 22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: ['Độc thân', 'Đang hẹn hò', 'Đã kết hôn', 'Phức tạp'].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status, style: const TextStyle(fontSize: 15)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedRelationship = value);
          },
        ),
      ],
    );
  }
}