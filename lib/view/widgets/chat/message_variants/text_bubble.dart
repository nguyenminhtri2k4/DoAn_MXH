import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_media.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/view/widgets/full_screen_image_viewer.dart';
import 'package:mangxahoi/view/widgets/full_screen_video_player.dart';
import 'package:mangxahoi/view/widgets/chat/message_video_player.dart';

class TextBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? sender;
  final bool isMe;

  const TextBubble({
    required this.message,
    required this.sender,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    const Radius messageRadius = Radius.circular(18.0);
    final avatarImage =
        sender?.avatar.isNotEmpty ?? false
            ? NetworkImage(sender!.avatar.first)
            : null;
    final bool hasText = message.content.isNotEmpty;
    final bool hasMedia = message.mediaIds.isNotEmpty;

    final messageContent = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : Colors.white,
        borderRadius:
            isMe
                ? const BorderRadius.only(
                  topLeft: messageRadius,
                  bottomLeft: messageRadius,
                  topRight: messageRadius,
                )
                : const BorderRadius.only(
                  topRight: messageRadius,
                  bottomRight: messageRadius,
                  topLeft: messageRadius,
                ),
        boxShadow: [
          if (!isMe)
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            isMe
                ? const BorderRadius.only(
                  topLeft: messageRadius,
                  bottomLeft: messageRadius,
                  topRight: messageRadius,
                )
                : const BorderRadius.only(
                  topRight: messageRadius,
                  bottomRight: messageRadius,
                  topLeft: messageRadius,
                ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && sender != null)
              Padding(
                padding: EdgeInsets.only(
                  top: hasMedia ? 8.0 : 10.0,
                  left: 14.0,
                  right: 14.0,
                  bottom: (hasMedia || hasText) ? 4.0 : 10.0,
                ),
                child: Text(
                  sender!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14.0,
                  ),
                ),
              ),
            if (hasMedia)
              _buildMessageMedia(context, message.mediaIds, hasText),
            if (hasText)
              Padding(
                padding: EdgeInsets.only(
                  top: (hasMedia || (!isMe && sender != null)) ? 8.0 : 10.0,
                  bottom: 10.0,
                  left: 14.0,
                  right: 14.0,
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!isMe) ...[
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
              messageContent,
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

  Widget _buildMessageMedia(
    BuildContext context,
    List<String> mediaIds,
    bool hasText,
  ) {
    final double mediaWidth = MediaQuery.of(context).size.width * 0.75;
    final firestoreListener = context.read<FirestoreListener>();
    final int count = mediaIds.length;
    const double spacing = 3.0;
    const double borderRadius = 0.0;

    if (count == 1) {
      return _buildMediaItem(
        context: context,
        media: firestoreListener.getMediaById(mediaIds.first),
        width: mediaWidth,
        height: 250,
        borderRadius: borderRadius,
      );
    }
    if (count == 2) {
      final itemWidth = (mediaWidth - spacing) / 2;
      return Row(
        children: [
          _buildMediaItem(
            context: context,
            media: firestoreListener.getMediaById(mediaIds[0]),
            width: itemWidth,
            height: 180,
            borderRadius: borderRadius,
          ),
          const SizedBox(width: spacing),
          _buildMediaItem(
            context: context,
            media: firestoreListener.getMediaById(mediaIds[1]),
            width: itemWidth,
            height: 180,
            borderRadius: borderRadius,
          ),
        ],
      );
    }
    final itemWidth = (mediaWidth - (2 * spacing)) / 3;
    return Row(
      children: [
        _buildMediaItem(
          context: context,
          media: firestoreListener.getMediaById(mediaIds[0]),
          width: itemWidth,
          height: 120,
          borderRadius: borderRadius,
        ),
        const SizedBox(width: spacing),
        _buildMediaItem(
          context: context,
          media: firestoreListener.getMediaById(mediaIds[1]),
          width: itemWidth,
          height: 120,
          borderRadius: borderRadius,
        ),
        const SizedBox(width: spacing),
        _buildMediaItem(
          context: context,
          media: firestoreListener.getMediaById(mediaIds[2]),
          width: itemWidth,
          height: 120,
          borderRadius: borderRadius,
        ),
      ],
    );
  }

  Widget _buildMediaItem({
    required BuildContext context,
    required MediaModel? media,
    required double width,
    required double height,
    required double borderRadius,
  }) {
    if (media == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
      );
    }
    if (media.type == 'image') {
      return GestureDetector(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageViewer(imageUrl: media.url),
              ),
            ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CachedNetworkImage(
            imageUrl: media.url,
            width: width,
            height: height,
            fit: BoxFit.cover,
            placeholder:
                (context, url) =>
                    Container(color: Colors.grey[300]?.withOpacity(0.5)),
            errorWidget:
                (context, url, error) => Container(
                  color: Colors.grey[300]?.withOpacity(0.5),
                  child: Icon(Icons.broken_image, color: Colors.grey[600]),
                ),
          ),
        ),
      );
    }
    if (media.type == 'video') {
      return GestureDetector(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenVideoPlayer(videoUrl: media.url),
              ),
            ),
        child: MessageVideoPlayer(
          videoUrl: media.url,
          width: width,
          height: height,
          borderRadius: borderRadius,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}