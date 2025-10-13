import 'package:flutter/material.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';
import 'package:mangxahoi/view/widgets/edit_profile_form.dart';
import 'package:mangxahoi/constant/app_colors.dart';

class EditProfileView extends StatelessWidget {
  // THÊM LẠI CONSTRUCTOR ĐÚNG
  final ProfileViewModel viewModel;
  const EditProfileView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      // Truyền viewModel đã nhận được vào form
      body: EditProfileForm(viewModel: viewModel),
    );
  }
}