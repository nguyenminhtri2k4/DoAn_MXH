// lib/view/messages_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/messages_viewmodel.dart';
import 'package:mangxahoi/model/model_chat.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesView extends StatelessWidget {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessagesViewModel(),
      child: const _MessagesViewContent(),
    );
  }
}

class _MessagesViewContent extends StatelessWidget {
  const _MessagesViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MessagesViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ChatModel>>(
              stream: vm.chatsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Không có tin nhắn nào.'));
                }
                final chats = snapshot.data!;
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    return _ChatListItem(
                      chat: chats[index],
                      currentUserId: vm.currentUserDocId!,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;

  const _ChatListItem({required this.chat, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final firestoreListener = context.watch<FirestoreListener>();

    Widget buildPrivateChatTile() {
      final otherUserId = chat.members.firstWhere((id) => id != currentUserId, orElse: () => '');
      if (otherUserId.isEmpty) return const SizedBox.shrink();

      final otherUser = firestoreListener.getUserById(otherUserId);
      if (otherUser == null) {
        return const ListTile(title: Text("Đang tải..."));
      }

      final avatarImage = otherUser.avatar.isNotEmpty ? NetworkImage(otherUser.avatar.first) : null;

      return ListTile(
        leading: CircleAvatar(
          backgroundImage: avatarImage,
          child: avatarImage == null ? const Icon(Icons.person) : null,
        ),
        title: Text(otherUser.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          chat.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(DateFormat('HH:mm').format(chat.updatedAt)),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: {'chatId': chat.id, 'chatName': otherUser.name},
          );
        },
      );
    }

    Widget buildGroupChatTile() {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Group').doc(chat.id).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTile(
              leading: CircleAvatar(child: Icon(Icons.group)),
              title: Text("Đang tải..."),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists || snapshot.data!.data() == null) {
             return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.error_outline)),
              title: const Text("Nhóm không tồn tại"),
              subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final group = GroupModel.fromMap(snapshot.data!.id, groupData);

          // Xác định ảnh đại diện cho nhóm
          ImageProvider? backgroundImage;
          if (group.coverImage.isNotEmpty) {
            backgroundImage = NetworkImage(group.coverImage);
          } else {
            // Dùng ảnh mặc định từ assets nếu không có coverImage
            backgroundImage = const AssetImage(AppColors.defaultAvatar);
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              foregroundColor: AppColors.primary,
              backgroundImage: backgroundImage,
              // Nếu dùng ảnh mặc định mà vẫn lỗi (ví dụ chưa thêm vào assets), hiện chữ cái đầu
              onBackgroundImageError: (_, __) {}, 
              child: (group.coverImage.isEmpty)
                  ? null // Nếu đang dùng ảnh mặc định thì không hiện text đè lên
                  : null,
            ),
            title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              chat.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(DateFormat('HH:mm').format(chat.updatedAt)),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/chat',
                arguments: {'chatId': group.id, 'chatName': group.name},
              );
            },
          );
        },
      );
    }

    return chat.type == 'group' ? buildGroupChatTile() : buildPrivateChatTile();
  }
}