import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/services/user_service.dart';

class CallMessageBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? sender;
  final bool isMe;

  const CallMessageBubble({
    required this.message,
    required this.sender,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAudioCall = message.type == 'call_audio';
    final String? currentAuthid = context.read<UserService>().currentUser?.id;
    final bool isCallFromMe = message.senderId == currentAuthid;

    IconData callIcon;
    Color iconColor;
    String callStatusText;
    String? durationText;

    if (message.content == 'missed') {
      callStatusText = isAudioCall ? 'Cuộc gọi thoại' : 'Cuộc gọi video';
      callIcon =
          isCallFromMe
              ? (isAudioCall ? Icons.phone_forwarded : Icons.videocam)
              : (isAudioCall ? Icons.phone_missed : Icons.videocam);
      iconColor = Colors.red;
      durationText = isCallFromMe ? 'Đã bị từ chối' : 'Nhỡ';
    } else if (message.content == 'declined') {
      callStatusText = isAudioCall ? 'Cuộc gọi thoại' : 'Cuộc gọi video';
      callIcon =
          isCallFromMe
              ? (isAudioCall ? Icons.phone_forwarded : Icons.videocam)
              : (isAudioCall ? Icons.phone_missed : Icons.videocam);
      iconColor = Colors.red;
      durationText = 'Đã bị từ chối';
    } else if (message.content.startsWith('completed_')) {
      try {
        final duration = message.content.split('_')[1];
        callStatusText = isAudioCall ? 'Cuộc gọi thoại' : 'Cuộc gọi video';
        callIcon =
            isCallFromMe
                ? (isAudioCall ? Icons.phone_forwarded : Icons.videocam)
                : (isAudioCall ? Icons.phone_callback : Icons.videocam);
        iconColor = const Color(0xFF0084FF);
        durationText = duration;
      } catch (e) {
        callStatusText = isAudioCall ? 'Cuộc gọi thoại' : 'Cuộc gọi video';
        callIcon = isAudioCall ? Icons.phone : Icons.videocam;
        iconColor = Colors.grey[600]!;
        durationText = 'Đã kết thúc';
      }
    } else {
      callStatusText = isAudioCall ? 'Cuộc gọi thoại' : 'Cuộc gọi video';
      callIcon = isAudioCall ? Icons.phone : Icons.videocam;
      iconColor = Colors.grey[600]!;
      durationText = null;
    }

    final avatarImage =
        sender?.avatar.isNotEmpty ?? false
            ? NetworkImage(sender!.avatar.first)
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment:
            isCallFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isCallFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCallFromMe) ...[
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 18.0,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: avatarImage,
                    child:
                        avatarImage == null
                            ? const Icon(
                              Icons.person,
                              size: 18,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                ),
                const SizedBox(width: 8.0),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color:
                      isCallFromMe
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey[300]!, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(callIcon, size: 18, color: iconColor),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          callStatusText,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (durationText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            durationText,
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isCallFromMe ? 0 : 52,
              right: isCallFromMe ? 8 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: const TextStyle(fontSize: 10.0, color: Colors.grey),
                ),
                if (isCallFromMe) ...[
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