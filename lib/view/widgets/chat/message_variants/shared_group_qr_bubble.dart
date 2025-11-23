// FILE: shared_group_qr_bubble.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_qr_invite.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/view/widgets/chat/group_invite_preview.dart';

class SharedGroupQRBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? sender;
  final bool isMe;

  const SharedGroupQRBubble({
    required this.message,
    required this.sender,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowAlignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final avatarImage =
        sender?.avatar.isNotEmpty ?? false
            ? NetworkImage(sender!.avatar.first)
            : null;

    QRInviteData? qrData;
    try {
      qrData = QRInviteData.fromQRString(message.content);
    } catch (e) {
      print('Lỗi phân tích QR invite data: $e');
      return const SizedBox.shrink();
    }

    final currentUserId = context.read<UserService>().currentUser?.id ?? '';
    final group = context.watch<FirestoreListener>().getGroupById(
      message.sharedPostId!,
    );
    final bool isAlreadyMember =
        group?.members.contains(currentUserId) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: rowAlignment,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!isMe) ...[
                CircleAvatar(
                  radius: 18.0,
                  backgroundImage: avatarImage,
                  child:
                      avatarImage == null
                          ? const Icon(Icons.person, size: 18)
                          : null,
                ),
                const SizedBox(width: 8.0),
              ],
              Column(
                crossAxisAlignment: alignment,
                children: [
                  if (!isMe && sender != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                      child: Text(
                        '${sender!.name} đã gửi lời mời nhóm',
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  GroupInvitePreview(
                    qrData: qrData!,
                    groupId: message.sharedPostId!,
                    isAlreadyMember: isAlreadyMember,
                    currentUserId: currentUserId,
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isMe ? 0 : 52,
              right: isMe ? 8 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color color = Colors.grey;
    switch (status) {
      case 'seen':
        iconData = Icons.done_all;
        color = Colors.blue;
        break;
      case 'delivered':
        iconData = Icons.done_all;
        break;
      default:
        iconData = Icons.check;
        break;
    }
    return Icon(iconData, size: 14, color: color);
  }
}