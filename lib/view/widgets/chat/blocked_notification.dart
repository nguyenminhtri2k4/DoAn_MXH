
// FILE: blocked_notification.dart
import 'package:flutter/material.dart';
import 'package:mangxahoi/viewmodel/chat_viewmodel.dart';

class BlockedNotification extends StatelessWidget {
  final ChatViewModel vm;

  const BlockedNotification({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isBlockedByMe = vm.blockedBy == vm.currentUserId;
    final text =
        isBlockedByMe
            ? 'Bạn đã chặn người dùng này.'
            : 'Bạn không thể nhắn tin cho tài khoản này.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}