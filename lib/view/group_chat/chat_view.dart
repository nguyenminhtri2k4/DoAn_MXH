import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/chat_viewmodel.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:intl/intl.dart';

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
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final sender = firestoreListener.getUserByAuthUid(message.senderId);
                    final isMe = message.senderId == vm.currentUserId;
                    return _MessageBubble(
                      message: message,
                      sender: sender,
                      isMe: isMe,
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

// Widget hiển thị tin nhắn đã được cập nhật
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
    final Radius messageRadius = const Radius.circular(20);
    final avatarImage = sender?.avatar.isNotEmpty ?? false ? NetworkImage(sender!.avatar.first) : null;

    final messageContent = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).primaryColor : Colors.white,
        borderRadius: isMe
            ? BorderRadius.only(
                topLeft: messageRadius,
                bottomLeft: messageRadius,
                topRight: messageRadius,
              )
            : BorderRadius.only(
                topRight: messageRadius,
                bottomRight: messageRadius,
                topLeft: messageRadius,
              ),
        boxShadow: [
          if (!isMe)
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên người gửi bên trong bong bóng chat
          if (!isMe && sender != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                sender!.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 14.0,
                ),
              ),
            ),
          // Nội dung tin nhắn
          Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15.0,
            ),
          ),
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
            padding: EdgeInsets.only(
              top: 4,
              left: isMe ? 0 : 52,
              right: isMe ? 8 : 0,
            ),
            child: Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: const TextStyle(fontSize: 10.0, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}