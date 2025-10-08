import 'package:flutter/material.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';

class NotificationSettingsCard extends StatelessWidget {
  final ProfileViewModel viewModel;

  const NotificationSettingsCard({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final notifSettings = viewModel.user!.notificationSettings;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Cài đặt thông báo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildNotificationSwitch(
              context,
              'comments',
              '💬 Bình luận',
              'Nhận thông báo khi có người bình luận',
              notifSettings['comments'] ?? true,
            ),
            _buildNotificationSwitch(
              context,
              'likes',
              '❤️ Lượt thích',
              'Nhận thông báo khi có người thích bài viết',
              notifSettings['likes'] ?? true,
            ),
            _buildNotificationSwitch(
              context,
              'friendRequests',
              '👥 Lời mời kết bạn',
              'Nhận thông báo về lời mời kết bạn',
              notifSettings['friendRequests'] ?? true,
            ),
            _buildNotificationSwitch(
              context,
              'messages',
              '💌 Tin nhắn',
              'Nhận thông báo khi có tin nhắn mới',
              notifSettings['messages'] ?? true,
            ),
            _buildNotificationSwitch(
              context,
              'tags',
              '🏷️ Gắn thẻ',
              'Nhận thông báo khi được gắn thẻ',
              notifSettings['tags'] ?? true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch(
    BuildContext context,
    String key,
    String title,
    String subtitle,
    bool value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: (newValue) {
              viewModel.updateNotificationSetting(key, newValue);
            },
          ),
        ],
      ),
    );
  }
}