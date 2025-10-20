
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/chat_viewmodel.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ChatView extends StatelessWidget {
  final String chatId;
  final String chatName;

  const ChatView({super.key, required this.chatId, required this.chatName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(chatId: chatId),
      child: _ChatViewContent(chatName: chatName),
    );
  }
}

class _ChatViewContent extends StatelessWidget {
  final String chatName;
  const _ChatViewContent({required this.chatName});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final firestoreListener = context.watch<FirestoreListener>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(chatName),
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: vm.messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var messages = snapshot.data!;
                // Lọc ra các tin nhắn đã bị xóa
                messages = messages.where((m) => m.status != 'deleted').toList();

                if (messages.isEmpty) {
                  return const Center(child: Text('Bắt đầu cuộc trò chuyện.'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final sender = firestoreListener.getUserByAuthUid(message.senderId);
                    final isMe = message.senderId == vm.currentUserId;

                    return VisibilityDetector(
                      key: Key(message.id),
                      onVisibilityChanged: (visibilityInfo) {
                        if (visibilityInfo.visibleFraction == 1.0 && !isMe && message.status != 'seen') {
                          vm.markAsSeen(message.id);
                        }
                      },
                      child: GestureDetector(
                        onLongPress: () {
                          if (isMe) {
                            _showMessageOptions(context, vm, message);
                          }
                        },
                        child: _MessageBubble(
                          message: message,
                          sender: sender,
                          isMe: isMe,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(context, vm),
        ],
      ),
    );
  }
  
  void _showMessageOptions(BuildContext context, ChatViewModel vm, MessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.undo),
              title: const Text('Thu hồi'),
              onTap: () {
                Navigator.pop(context);
                vm.recallMessage(message.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Xóa'),
              onTap: () {
                Navigator.pop(context);
                vm.deleteMessage(message.id);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageComposer(BuildContext context, ChatViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: vm.messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              iconSize: 25.0,
              color: Theme.of(context).primaryColor,
              onPressed: vm.sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? sender;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.sender,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (message.status == 'recalled') {
      return _buildRecalledMessageBubble();
    }
    if (message.type == 'share_post' && message.sharedPostId != null) {
      return _buildSharedPostBubble(context);
    }
    return _buildTextBubble(context);
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
            style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedPostBubble(BuildContext context) {
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowAlignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final avatarImage = sender?.avatar.isNotEmpty ?? false ? NetworkImage(sender!.avatar.first) : null;

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
                  child: avatarImage == null ? const Icon(Icons.person, size: 18) : null,
                ),
                const SizedBox(width: 8.0),
              ],
              Column(
                crossAxisAlignment: alignment,
                children: [
                  if (!isMe && sender != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                      child: Text(sender!.name, style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
                    ),
                  if(message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(message.content, style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                  _SharedPostPreview(postId: message.sharedPostId!),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 52, right: isMe ? 8 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('HH:mm').format(message.createdAt), style: const TextStyle(fontSize: 10.0, color: Colors.grey)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBubble(BuildContext context) {
    final Radius messageRadius = const Radius.circular(20);
    final avatarImage = sender?.avatar.isNotEmpty ?? false ? NetworkImage(sender!.avatar.first) : null;

    final messageContent = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).primaryColor : Colors.white,
        borderRadius: isMe
            ? BorderRadius.only(topLeft: messageRadius, bottomLeft: messageRadius, topRight: messageRadius)
            : BorderRadius.only(topRight: messageRadius, bottomRight: messageRadius, topLeft: messageRadius),
        boxShadow: [ if (!isMe) BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2)) ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe && sender != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(sender!.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14.0)),
            ),
          Text(message.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15.0)),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!isMe) ...[
                CircleAvatar(
                  radius: 18.0,
                  backgroundImage: avatarImage,
                  child: avatarImage == null ? const Icon(Icons.person, size: 18) : null,
                ),
                const SizedBox(width: 8.0),
              ],
              messageContent,
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 52, right: isMe ? 8 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('HH:mm').format(message.createdAt), style: const TextStyle(fontSize: 10.0, color: Colors.grey)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ]
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
      case 'sent':
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
      onTap: () {
        Navigator.pushNamed(context, '/post_detail', arguments: postId);
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('Post').doc(postId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Bài viết đã bị xóa hoặc không tồn tại.'),
              );
            }
            final post = PostModel.fromMap(snapshot.data!.id, snapshot.data!.data() as Map<String, dynamic>);
            final author = context.read<FirestoreListener>().getUserById(post.authorId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: (author?.avatar.isNotEmpty ?? false) ? NetworkImage(author!.avatar.first) : null,
                        child: (author?.avatar.isEmpty ?? true) ? const Icon(Icons.person, size: 18) : null,
                      ),
                      const SizedBox(width: 8),
                      Text(author?.name ?? '...', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (post.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                  ),
                if (post.mediaIds.isNotEmpty)
                  _buildMediaPreview(context, post),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context, PostModel post) {
    final media = context.read<FirestoreListener>().getMediaById(post.mediaIds.first);
    if (media == null) return const SizedBox.shrink();

    if (media.type == 'video') {
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
    }

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