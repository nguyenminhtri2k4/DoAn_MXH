
import 'package:flutter/material.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';
import 'package:mangxahoi/view/widgets/edit_profile_form.dart';
import 'package:mangxahoi/constant/app_colors.dart';

class EditProfileView extends StatelessWidget {
  final ProfileViewModel viewModel;
  const EditProfileView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: EditProfileForm(viewModel: viewModel),
    );
  }
}