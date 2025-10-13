import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/view/widgets/notification_settings_card.dart';

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..loadProfile(),
      child: const _NotificationSettingsContent(),
    );
  }
}

class _NotificationSettingsContent extends StatelessWidget {
  const _NotificationSettingsContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.user == null
              ? const Center(child: Text('Không thể tải cài đặt'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: NotificationSettingsCard(viewModel: vm),
                ),
    );
  }
}