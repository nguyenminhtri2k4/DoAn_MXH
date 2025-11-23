import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/chat_viewmodel.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/view/group_chat/add_members_view.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
// Import widget components
import 'package:mangxahoi/view/widgets/chat/message_bubble.dart';
import 'package:mangxahoi/view/widgets/chat/message_composer.dart';
import 'package:mangxahoi/view/widgets/chat/smart_reply_suggestions.dart';
import 'package:mangxahoi/view/widgets/chat/blocked_notification.dart';

class ChatViewContent extends StatelessWidget {
  final String chatName;
  const ChatViewContent({required this.chatName});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final firestoreListener = context.watch<FirestoreListener>();
    final currentUser = context.watch<UserService>().currentUser;

    if (vm.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      });
    }

    Widget appBarTitle;

    if (vm.isGroup) {
      final group = firestoreListener.getGroupById(vm.chatId);
      final bool hasCoverImage = group?.coverImage.isNotEmpty ?? false;

      if (hasCoverImage) {
        appBarTitle = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: CachedNetworkImageProvider(group!.coverImage),
            ),
            const SizedBox(width: 12),
            Text(chatName),
          ],
        );
      } else {
        appBarTitle = Text(chatName);
      }
    } else {
      appBarTitle = Text(chatName);
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: appBarTitle,
          centerTitle: false,
          titleSpacing: 0,
          backgroundColor: AppColors.backgroundLight,
          elevation: 1,
          actions: [
            if (!vm.isGroup && !vm.isBlocked)
              IconButton(
                icon: const Icon(Icons.call),
                onPressed: () => vm.startAudioCall(context),
              ),
            if (!vm.isGroup && !vm.isBlocked)
              IconButton(
                icon: const Icon(Icons.videocam),
                onPressed: () => vm.startVideoCall(context),
              ),
            if (vm.isGroup)
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'Thêm thành viên',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMembersView(groupId: vm.chatId),
                    ),
                  );
                },
              ),
            if (vm.isGroup)
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Thông tin nhóm',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/group_management',
                    arguments: vm.chatId,
                  );
                },
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: vm.messagesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  var messages =
                      snapshot.data!
                          .where((m) => m.status != 'deleted')
                          .toList();

                  if (messages.isNotEmpty) {
                    final lastMessage = messages.first;
                    final bool isGeminiEnabled =
                        currentUser?.serviceGemini ?? false;

                    print('--- DEBUG SMART REPLY ---');
                    print('1. SenderID tin cuối: ${lastMessage.senderId}');
                    print('2. My ID: ${vm.currentUserId}');
                    print('3. Is Group: ${vm.isGroup}');
                    print('4. Is Blocked: ${vm.isBlocked}');
                    print('5. Setting bật chưa: $isGeminiEnabled');
                    print('-------------------------');
                    if (lastMessage.senderId != vm.currentUserId &&
                        !vm.isGroup &&
                        !vm.isBlocked) {
                      Future.microtask(
                        () => vm.generateReplies(messages, isGeminiEnabled),
                      );
                    }
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(10.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final sender = firestoreListener.getUserById(
                        message.senderId,
                      );
                      final isMe = message.senderId == vm.currentUserId;

                      return VisibilityDetector(
                        key: Key(message.id),
                        onVisibilityChanged: (visibilityInfo) {
                          if (visibilityInfo.visibleFraction == 1.0 &&
                              !isMe &&
                              message.status != 'seen') {
                            vm.markAsSeen(message.id);
                          }
                        },
                        child: GestureDetector(
                          onLongPress: () {
                            if (isMe) {
                              _showMessageOptions(context, vm, message);
                            }
                          },
                          child: MessageBubble(
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
            if (vm.isBlocked && !vm.isGroup)
              BlockedNotification(vm: vm)
            else ...[
              SmartReplySuggestions(vm: vm),
              MessageComposer(vm: vm),
            ],
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(
    BuildContext context,
    ChatViewModel vm,
    MessageModel message,
  ) {
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
}