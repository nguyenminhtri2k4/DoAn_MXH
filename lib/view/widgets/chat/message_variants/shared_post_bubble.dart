
// FILE: shared_post_bubble.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/constant/app_colors.dart';

class SharedPostBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? sender;
  final bool isMe;

  const SharedPostBubble({
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
                        sender!.name,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  if (message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        message.content,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  _SharedPostPreview(postId: message.sharedPostId!),
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

class _SharedPostPreview extends StatelessWidget {
  final String postId;
  const _SharedPostPreview({required this.postId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => Navigator.pushNamed(context, '/post_detail', arguments: postId),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('Post')
                  .doc(postId)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists)
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Bài viết đã bị xóa.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              );
            final post = PostModel.fromMap(
              snapshot.data!.id,
              snapshot.data!.data() as Map<String, dynamic>,
            );
            final author = context.read<FirestoreListener>().getUserById(
              post.authorId,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            (author?.avatar.isNotEmpty ?? false)
                                ? NetworkImage(author!.avatar.first)
                                : null,
                        child:
                            (author?.avatar.isEmpty ?? true)
                                ? const Icon(Icons.person, size: 18)
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          author?.name ?? 'Người dùng',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Text(
                      post.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (post.mediaIds.isNotEmpty) _buildMediaPreview(context, post),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context, PostModel post) {
    final media = context.read<FirestoreListener>().getMediaById(
      post.mediaIds.first,
    );
    if (media == null) return const SizedBox.shrink();
    if (media.type == 'video')
      return Container(
        height: 150,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
        ),
      );
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
      child: CachedNetworkImage(
        imageUrl: media.url,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}