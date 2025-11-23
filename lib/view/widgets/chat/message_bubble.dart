import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_media.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/view/widgets/full_screen_image_viewer.dart';
import 'package:mangxahoi/view/widgets/full_screen_video_player.dart';
// Import sub-components
import 'package:mangxahoi/view/widgets/chat/message_variants/call_message_bubble.dart';
import 'package:mangxahoi/view/widgets/chat/message_variants/qr_user_bubble.dart';
import 'package:mangxahoi/view/widgets/chat/message_variants/shared_post_bubble.dart';
import 'package:mangxahoi/view/widgets/chat/message_variants/shared_group_qr_bubble.dart';
import 'package:mangxahoi/view/widgets/chat/message_variants/text_bubble.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? sender;
  final bool isMe;

  const MessageBubble({
    required this.message,
    required this.sender,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (message.status == 'recalled') return _buildRecalledMessageBubble();
    if (message.type == 'qr_user') return QRUserBubble(message: message, sender: sender, isMe: isMe);
    if (message.type == 'share_post' && message.sharedPostId != null)
      return SharedPostBubble(message: message, sender: sender, isMe: isMe);
    if (message.type == 'share_group_qr' && message.sharedPostId != null)
      return SharedGroupQRBubble(message: message, sender: sender, isMe: isMe);
    if (message.type == 'call_audio' || message.type == 'call_video')
      return CallMessageBubble(message: message, sender: sender, isMe: isMe);
    return TextBubble(message: message, sender: sender, isMe: isMe);
  }

  Widget _buildRecalledMessageBubble() {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Tin nhắn đã bị thu hồi',
            style: TextStyle(
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}