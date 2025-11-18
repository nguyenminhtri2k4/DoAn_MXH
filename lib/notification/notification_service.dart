import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Thêm phương thức cho SnackBar thành công
  void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Phương thức hiển thị dialog toàn cục
  Future<void> showGlobalDialog({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    Color? iconColor,
    String? confirmText,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            icon,
            size: 48,
            color: iconColor ?? Theme.of(context).primaryColor,
          ),
          iconPadding: const EdgeInsets.only(top: 20, bottom: 10),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            if (confirmText != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm?.call();
                },
                child: Text(confirmText),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  // Phương thức cho thông báo thành công
  Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    VoidCallback? onConfirm,
  }) async {
    await showGlobalDialog(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle,
      iconColor: Colors.green,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  // Phương thức cho thông báo lỗi
  Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    await showGlobalDialog(
      context: context,
      title: title,
      message: message,
      icon: Icons.error,
      iconColor: Colors.red,
    );
  }

  // Phương thức cho thông báo cảnh báo
  Future<void> showWarningDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    VoidCallback? onConfirm,
  }) async {
    await showGlobalDialog(
      context: context,
      title: title,
      message: message,
      icon: Icons.warning,
      iconColor: Colors.orange,
      confirmText: confirmText,
      onConfirm: onConfirm,
    );
  }

  // Phương thức cho thông báo thông tin
  Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    await showGlobalDialog(
      context: context,
      title: title,
      message: message,
      icon: Icons.info,
      iconColor: Colors.blue,
    );
  }
}