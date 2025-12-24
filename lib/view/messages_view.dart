
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:mangxahoi/viewmodel/messages_viewmodel.dart';
// import 'package:mangxahoi/model/model_chat.dart';
// import 'package:mangxahoi/model/model_user.dart';
// import 'package:mangxahoi/model/model_group.dart';
// import 'package:mangxahoi/authanet/firestore_listener.dart';
// import 'package:mangxahoi/constant/app_colors.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:convert';
// import 'package:mangxahoi/model/model_qr_invite.dart';

// class MessagesView extends StatelessWidget {
//   const MessagesView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => MessagesViewModel()..initialize(), // GỌI initialize() NGAY TẠI ĐÂY!!!
//       child: const _MessagesViewContent(),
//     );
//   }
// }

// class _MessagesViewContent extends StatelessWidget {
//   const _MessagesViewContent();

//   @override
//   Widget build(BuildContext context) {
//     final vm = context.watch<MessagesViewModel>();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Tin nhắn'),
//         backgroundColor: AppColors.backgroundLight,
//         elevation: 1,
//       ),
//       body: vm.isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : vm.currentUserDocId == null
//               ? const Center(child: Text('Đang tải người dùng...'))
//               : StreamBuilder<List<ChatModel>>(
//                   stream: vm.chatsStream,
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//                     if (snapshot.hasError) {
//                       return const Center(child: Text('Lỗi tải tin nhắn'));
//                     }
//                     if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                       return const Center(
//                         child: Text(
//                           'Không có tin nhắn nào.\nBắt đầu trò chuyện ngay!',
//                           textAlign: TextAlign.center,
//                         ),
//                       );
//                     }
//                     final chats = snapshot.data!;
//                     return ListView.builder(
//                       itemCount: chats.length,
//                       itemBuilder: (context, index) {
//                         return _ChatListItem(
//                           chat: chats[index],
//                           currentUserId: vm.currentUserDocId!, // BÂY GIỜ AN TOÀN 100%
//                         );
//                       },
//                     );
//                   },
//                 ),
//     );
//   }
// }

//     // === HÀM HELPER HOÀN HẢO ===
//     Widget _buildSummary(String lastMessage) {
//       if (lastMessage.isEmpty) {
//         return const Text(
//           'Đã gửi một tệp media.',
//           style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
//           overflow: TextOverflow.ellipsis,
//         );
//       }

//       try {
//         final qrData = QRInviteData.fromQRString(lastMessage);
//         return Text(
//           'Lời mời tham gia ${qrData.groupName}',
//           style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
//           overflow: TextOverflow.ellipsis,
//         );
//       } catch (e) {
//         // Không phải lời mời → hiển thị bình thường
//       }

//       return Text(
//         lastMessage,
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//         style: const TextStyle(color: Colors.grey),
//       );
//     }

// class _ChatListItem extends StatelessWidget {
//   final ChatModel chat;
//   final String currentUserId;

//   const _ChatListItem({required this.chat, required this.currentUserId});

//   @override
//   Widget build(BuildContext context) {
//     final firestoreListener = context.watch<FirestoreListener>();

//     Widget buildPrivateChatTile() {
//       final otherUserId = chat.members.firstWhere((id) => id != currentUserId, orElse: () => '');
//       if (otherUserId.isEmpty) return const SizedBox.shrink();

//       final otherUser = firestoreListener.getUserById(otherUserId);
//       if (otherUser == null) {
//         return const ListTile(
//           leading: CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
//           title: Text("Đang tải..."),
//         );
//       }

//       return ListTile(
//         leading: CircleAvatar(
//           backgroundImage: otherUser.avatar.isNotEmpty
//               ? NetworkImage(otherUser.avatar.first)
//               : null,
//           child: otherUser.avatar.isEmpty ? const Icon(Icons.person) : null,
//         ),
//         title: Text(otherUser.name, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: _buildSummary(chat.lastMessage),
//         trailing: Text(DateFormat('HH:mm').format(chat.updatedAt)),
//         onTap: () {
//           Navigator.pushNamed(
//             context,
//             '/chat',
//             arguments: {'chatId': chat.id, 'chatName': otherUser.name},
//           );
//         },
//       );
//     }

//     Widget buildGroupChatTile() {
//       return FutureBuilder<DocumentSnapshot>(
//         future: FirebaseFirestore.instance.collection('Group').doc(chat.id).get(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const ListTile(
//               leading: CircleAvatar(child: Icon(Icons.group)),
//               title: Text("Đang tải nhóm..."),
//             );
//           }

//           if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
//             // return ListTile(
//             //   leading: const CircleAvatar(child: Icon(Icons.error_outline)),
//             //   title: const Text("Nhóm không tồn tại"),
//             //   subtitle: _buildSummary(chat.lastMessage),
//             // );
//             return const SizedBox.shrink();
//           }

//           final groupData = snapshot.data!.data() as Map<String, dynamic>;
//           final group = GroupModel.fromMap(snapshot.data!.id, groupData);

//           return ListTile(
//             leading: CircleAvatar(
//               backgroundImage: group.coverImage.isNotEmpty
//                   ? NetworkImage(group.coverImage)
//                   : const AssetImage('assets/images/default_group.png') as ImageProvider,
//               onBackgroundImageError: (_, __) {},
//             ),
//             title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
//             subtitle: _buildSummary(chat.lastMessage),
//             trailing: Text(DateFormat('HH:mm').format(chat.updatedAt)),
//             onTap: () {
//               Navigator.pushNamed(
//                 context,
//                 '/chat',
//                 arguments: {'chatId': group.id, 'chatName': group.name},
//               );
//             },
//           );
//         },
//       );
//     }

//     return chat.type == 'group' ? buildGroupChatTile() : buildPrivateChatTile();
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/messages_viewmodel.dart';
import 'package:mangxahoi/model/model_chat.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_qr_invite.dart';

// ĐẢM BẢO: Bạn đã tạo file ChatManagementView tại đúng đường dẫn này.
// Nếu file nằm ở thư mục khác, hãy sửa lại đường dẫn import cho đúng.
import 'package:mangxahoi/view/widgets/chat/chat_management_view.dart';

class MessagesView extends StatelessWidget {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessagesViewModel()..initialize(),
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
          : vm.currentUserDocId == null
              ? const Center(child: Text('Đang tải người dùng...'))
              : StreamBuilder<List<ChatModel>>(
                  stream: vm.chatsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Lỗi tải tin nhắn'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'Không có tin nhắn nào.\nBắt đầu trò chuyện ngay!',
                          textAlign: TextAlign.center,
                        ),
                      );
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

// === HÀM HELPER HIỂN THỊ TIN NHẮN CUỐI ===
Widget _buildSummary(String lastMessage) {
  if (lastMessage.isEmpty) {
    return const Text(
      'Đã gửi một tệp media.',
      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      overflow: TextOverflow.ellipsis,
    );
  }

  try {
    final qrData = QRInviteData.fromQRString(lastMessage);
    return Text(
      'Lời mời tham gia ${qrData.groupName}',
      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      overflow: TextOverflow.ellipsis,
    );
  } catch (e) {
    // Không phải lời mời → hiển thị bình thường
  }

  return Text(
    lastMessage,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(color: Colors.grey),
  );
}

class _ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;

  const _ChatListItem({required this.chat, required this.currentUserId});

  // Hàm helper điều hướng đến trang quản lý
  void _openManagement(BuildContext context, String chatId, bool isGroup, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatManagementView(
          chatId: chatId,
          isGroup: isGroup,
          chatName: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreListener = context.watch<FirestoreListener>();

    // 1. GIAO DIỆN CHAT 1-1
    Widget buildPrivateChatTile() {
      final otherUserId = chat.members.firstWhere((id) => id != currentUserId, orElse: () => '');
      if (otherUserId.isEmpty) return const SizedBox.shrink();

      final otherUser = firestoreListener.getUserById(otherUserId);
      if (otherUser == null) {
        return const ListTile(
          leading: CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
          title: Text("Đang tải..."),
        );
      }

      return ListTile(
        // GIỮ LẠI AVATAR USER Ở ĐÂY
        leading: CircleAvatar(
          backgroundImage: otherUser.avatar.isNotEmpty
              ? NetworkImage(otherUser.avatar.first) // Lấy ảnh đầu tiên trong mảng avatar
              : null,
          child: otherUser.avatar.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(otherUser.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: _buildSummary(chat.lastMessage),
        // NÚT 3 CHẤM NẰM TRÊN GIỜ
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _openManagement(context, chat.id, false, otherUser.name),
              child: const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('HH:mm').format(chat.updatedAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(context, '/chat', arguments: {'chatId': chat.id, 'chatName': otherUser.name});
        },
      );
    }

    // 2. GIAO DIỆN CHAT NHÓM
    Widget buildGroupChatTile() {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Group').doc(chat.id).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTile(
              leading: CircleAvatar(child: Icon(Icons.group)),
              title: Text("Đang tải nhóm..."),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const SizedBox.shrink();
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final group = GroupModel.fromMap(snapshot.data!.id, groupData);

          return ListTile(
            // GIỮ LẠI AVATAR NHÓM Ở ĐÂY
            leading: CircleAvatar(
              backgroundImage: group.coverImage.isNotEmpty
                  ? NetworkImage(group.coverImage) // Dùng coverImage của GroupModel
                  : null,
              child: group.coverImage.isEmpty ? const Icon(Icons.group) : null,
            ),
            title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: _buildSummary(chat.lastMessage),
            // NÚT 3 CHẤM NẰM TRÊN GIỜ
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _openManagement(context, group.id, true, group.name),
                  child: const Icon(Icons.more_horiz, color: Colors.grey, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('HH:mm').format(chat.updatedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(context, '/chat', arguments: {'chatId': group.id, 'chatName': group.name});
            },
          );
        },
      );
    }

    return chat.type == 'group' ? buildGroupChatTile() : buildPrivateChatTile();
  }
}