
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_notification.dart';
import 'package:mangxahoi/viewmodel/notification_view_model.dart';

// Widget con hiển thị item
class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;        // Tap vào nội dung
  final VoidCallback onDelete;     // Vuốt xóa
  final VoidCallback onAvatarTap;  // 🔥 Tap vào Avatar
  final String timeAgo;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
    required this.onAvatarTap, // Thêm tham số này
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    // Kiểm tra ảnh hợp lệ (không rỗng và bắt đầu bằng http để tránh crash NetworkImage)
    bool isValidAvatar = notification.fromUserAvatar.isNotEmpty && 
                         notification.fromUserAvatar.startsWith('http');

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade500,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 Bọc Avatar bằng GestureDetector
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: isValidAvatar
                      ? NetworkImage(notification.fromUserAvatar)
                      : const AssetImage('assets/logoapp.png') as ImageProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.content,
                      style: TextStyle(color: Colors.grey[800], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: notification.isRead ? Colors.grey : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 15),
                  child: CircleAvatar(radius: 5, backgroundColor: Colors.blue),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Màn hình chính
class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  final NotificationViewModel _viewModel = NotificationViewModel();

  // Dialog xóa tất cả
  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.red.shade600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Xóa tất cả thông báo?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Hành động này không thể hoàn tác',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _viewModel.deleteAllNotifications();
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Xóa',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 1,
        actions: [
          Tooltip(
            message: 'Xóa tất cả thông báo',
            child: IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: Colors.red.shade600, size: 24),
              onPressed: _showDeleteAllDialog,
              splashRadius: 24,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _viewModel.notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Log lỗi ra console để debug, UI hiện thông báo nhẹ nhàng
            print("Lỗi stream: ${snapshot.error}");
            return const Center(child: Text('Đang tải thông báo...'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data;
          if (notifications == null || notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    'Không có thông báo nào',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return NotificationItem(
                notification: notif,
                // 1. Tap nội dung
                onTap: () => _viewModel.handleNotificationTap(context, notif),
                // 2. Tap Avatar -> Qua profile
                onAvatarTap: () => _viewModel.handleAvatarTap(context, notif.fromUserId),
                // 3. Xóa
                onDelete: () => _viewModel.deleteNotification(notif.id),
                timeAgo: _viewModel.formatTime(notif.createdAt),
              );
            },
          );
        },
      ),
    );
  }
}