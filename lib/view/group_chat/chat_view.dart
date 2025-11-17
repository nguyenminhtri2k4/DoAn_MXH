
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/chat_viewmodel.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_media.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/view/widgets/full_screen_image_viewer.dart';
import 'package:mangxahoi/view/widgets/full_screen_video_player.dart';
import 'package:mangxahoi/view/group_chat/add_members_view.dart';
import 'package:mangxahoi/view/group_chat/group_management_view.dart';
import 'package:mangxahoi/model/model_qr_invite.dart';
import 'package:mangxahoi/request/group_request.dart';
import 'package:mangxahoi/notification/notification_service.dart';
import 'package:mangxahoi/model/model_group.dart';

class ChatView extends StatelessWidget {
  final String chatId;
  final String chatName;

  const ChatView({super.key, required this.chatId, required this.chatName});

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = context.watch<UserService>().currentUser?.id;

    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(chatId: chatId, currentUserId: currentUserId),
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

    // --- LOGIC CHO APPBAR TITLE ---
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
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var messages = snapshot.data!;
                  messages = messages.where((m) => m.status != 'deleted').toList();

                  if (!vm.isBlocked) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        vm.generateReplies(messages);
                      }
                    });
                  }

                  if (messages.isEmpty) {
                    return const Center(child: Text('Bắt đầu cuộc trò chuyện.'));
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(10.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final sender = firestoreListener.getUserById(message.senderId);
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
                          child: _MessageBubble(message: message, sender: sender, isMe: isMe),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            if (vm.isBlocked && !vm.isGroup)
              _buildBlockedNotification(context, vm)
            else ...[
              _buildSmartReplySuggestions(vm),
              _buildMessageComposer(context, vm),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedNotification(BuildContext context, ChatViewModel vm) {
    final isBlockedByMe = vm.blockedBy == vm.currentUserId;
    final text = isBlockedByMe
        ? 'Bạn đã chặn người dùng này.'
        : 'Bạn không thể nhắn tin cho tài khoản này.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
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
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildMediaPreview(vm),
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.image, color: Theme.of(context).primaryColor),
                  onPressed: vm.isLoading ? null : vm.pickImages,
                ),
                IconButton(
                  icon: Icon(Icons.videocam, color: Theme.of(context).primaryColor),
                  onPressed: vm.isLoading ? null : vm.pickVideo,
                ),
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
                vm.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        iconSize: 25.0,
                        color: Theme.of(context).primaryColor,
                        onPressed: vm.isLoading ? null : vm.sendMessage,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(ChatViewModel viewModel) {
    if (viewModel.selectedMedia.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 100,
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.selectedMedia.length,
        itemBuilder: (context, index) {
          final file = viewModel.selectedMedia[index];
          final bool isVideo = file.path.toLowerCase().endsWith('.mp4') || file.path.toLowerCase().endsWith('.mov');
          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: 80, height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.grey[300],
                ),
                child: isVideo
                    ? Container(
                        alignment: Alignment.center,
                        color: Colors.black,
                        child: const Icon(Icons.videocam, color: Colors.white, size: 40),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(File(file.path), fit: BoxFit.cover),
                      ),
              ),
              GestureDetector(
                onTap: () => viewModel.removeMedia(file),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmartReplySuggestions(ChatViewModel vm) {
    final replies = vm.smartReplies;

    if (replies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gợi ý trả lời',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 6.0,
              children: replies.map((reply) {
                return InkWell(
                  onTap: () {
                    vm.selectReply(reply);
                  },
                  borderRadius: BorderRadius.circular(20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            reply,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: AppColors.primary.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// ==================== BONG BÓNG CHAT ================================
// ====================================================================

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? sender;
  final bool isMe;

  const _MessageBubble({required this.message, required this.sender, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (message.status == 'recalled') return _buildRecalledMessageBubble();
    if (message.type == 'share_post' && message.sharedPostId != null) return _buildSharedPostBubble(context);
    if (message.type == 'share_group_qr' && message.sharedPostId != null) return _buildSharedGroupQRBubble(context);
    if (message.type == 'call_audio' || message.type == 'call_video') return _buildCallMessageBubble(context);
    return _buildTextBubble(context);
  }

  Widget _buildCallMessageBubble(BuildContext context) {
    final bool isAudioCall = message.type == 'call_audio';
    final String? currentAuthid = context.read<UserService>().currentUser?.id;
    final bool isCallFromMe = message.senderId == currentAuthid;

    IconData callIcon;
    Color iconColor;
    String callStatusText;
    String? durationText;

    if (message.content == 'missed') {
      callStatusText = isAudioCall ? 'Cuộc gọi thoại' : 'Cuộc gọi video';
      callIcon = isCallFromMe 
          ? (isAudioCall ? Icons.phone_forwarded : Icons.videocam)
          : (isAudioCall ? Icons.phone_missed : Icons.videocam); 
      iconColor = Colors.red;
      durationText = isCallFromMe ? 'Đã bị từ chối' : 'Nhỡ';
    } else if (message.content == 'declined') {
      callStatusText = isAudioCall ? 'Cuộc gọi thoại' : 'Cuộc gọi video';
      callIcon = isCallFromMe 
          ? (isAudioCall ? Icons.phone_forwarded : Icons.videocam)
          : (isAudioCall ? Icons.phone_missed : Icons.videocam);
      iconColor = Colors.red;
      durationText = 'Đã bị từ chối';
    } else if (message.content.startsWith('completed_')) {
      try {
        final duration = message.content.split('_')[1];
        callStatusText = isAudioCall ? 'Cuộc gọi thoại' : 'Cuộc gọi video';
        callIcon = isCallFromMe
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
    
    final avatarImage = sender?.avatar.isNotEmpty ?? false ? NetworkImage(sender!.avatar.first) : null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: isCallFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isCallFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCallFromMe) ...[
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!, width: 1)
                  ),
                  child: CircleAvatar(
                    radius: 18.0,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: avatarImage,
                    child: avatarImage == null ? const Icon(Icons.person, size: 18, color: Colors.grey) : null,
                  ),
                ),
                const SizedBox(width: 8.0),
              ],
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: isCallFromMe ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
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
              right: isCallFromMe ? 8 : 0
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
                  _buildStatusIcon(message.status)
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedGroupQRBubble(BuildContext context) {
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowAlignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final avatarImage = sender?.avatar.isNotEmpty ?? false ? NetworkImage(sender!.avatar.first) : null;

    QRInviteData? qrData;
    try {
      qrData = QRInviteData.fromQRString(message.content);
    } catch (e) {
      print('Lỗi phân tích QR invite data: $e');
      return _buildTextBubble(context);
    }

    final currentUserId = context.read<UserService>().currentUser?.id ?? '';
    final group = context.watch<FirestoreListener>().getGroupById(message.sharedPostId!);
    final bool isAlreadyMember = group?.members.contains(currentUserId) ?? false;

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
                      child: Text(
                        '${sender!.name} đã gửi lời mời nhóm', 
                        style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                    ),
                  _GroupInvitePreview(
                    qrData: qrData,
                    groupId: message.sharedPostId!,
                    isAlreadyMember: isAlreadyMember,
                    currentUserId: currentUserId,
                  ),
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
                if (isMe) ...[const SizedBox(width: 4), _buildStatusIcon(message.status)]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecalledMessageBubble() {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
          child: const Text('Tin nhắn đã bị thu hồi', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
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
                  if (message.content.isNotEmpty)
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
                if (isMe) ...[const SizedBox(width: 4), _buildStatusIcon(message.status)]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBubble(BuildContext context) {
    const Radius messageRadius = Radius.circular(18.0);
    final avatarImage = sender?.avatar.isNotEmpty ?? false ? NetworkImage(sender!.avatar.first) : null;
    final bool hasText = message.content.isNotEmpty;
    final bool hasMedia = message.mediaIds.isNotEmpty;

    final messageContent = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : Colors.white,
        borderRadius: isMe
            ? const BorderRadius.only(topLeft: messageRadius, bottomLeft: messageRadius, topRight: messageRadius)
            : const BorderRadius.only(topRight: messageRadius, bottomRight: messageRadius, topLeft: messageRadius),
        boxShadow: [if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: isMe
            ? const BorderRadius.only(topLeft: messageRadius, bottomLeft: messageRadius, topRight: messageRadius)
            : const BorderRadius.only(topRight: messageRadius, bottomRight: messageRadius, topLeft: messageRadius),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && sender != null)
              Padding(
                padding: EdgeInsets.only(top: hasMedia ? 8.0 : 10.0, left: 14.0, right: 14.0, bottom: (hasMedia || hasText) ? 4.0 : 10.0),
                child: Text(sender!.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14.0)),
              ),
            if (hasMedia) _buildMessageMedia(context, message.mediaIds, hasText),
            if (hasText)
              Padding(
                padding: EdgeInsets.only(top: (hasMedia || (!isMe && sender != null)) ? 8.0 : 10.0, bottom: 10.0, left: 14.0, right: 14.0),
                child: Text(message.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15.0)),
              ),
          ],
        ),
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
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey[200]!, width: 1)),
                  child: CircleAvatar(
                    radius: 18.0, backgroundColor: Colors.grey[100], backgroundImage: avatarImage,
                    child: avatarImage == null ? const Icon(Icons.person, size: 18, color: Colors.grey) : null,
                  ),
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
                if (isMe) ...[const SizedBox(width: 4), _buildStatusIcon(message.status)]
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
      case 'seen': iconData = Icons.done_all; color = Colors.blue; break;
      case 'delivered': iconData = Icons.done_all; break;
      default: iconData = Icons.check; break;
    }
    return Icon(iconData, size: 14, color: color);
  }

  Widget _buildMessageMedia(BuildContext context, List<String> mediaIds, bool hasText) {
    final double mediaWidth = MediaQuery.of(context).size.width * 0.75;
    final firestoreListener = context.read<FirestoreListener>();
    final int count = mediaIds.length;
    const double spacing = 3.0;
    const double borderRadius = 0.0;

    if (count == 1) {
      return _buildMediaItem(context: context, media: firestoreListener.getMediaById(mediaIds.first), width: mediaWidth, height: 250, borderRadius: borderRadius);
    }
    if (count == 2) {
      final itemWidth = (mediaWidth - spacing) / 2;
      return Row(children: [
        _buildMediaItem(context: context, media: firestoreListener.getMediaById(mediaIds[0]), width: itemWidth, height: 180, borderRadius: borderRadius),
        const SizedBox(width: spacing),
        _buildMediaItem(context: context, media: firestoreListener.getMediaById(mediaIds[1]), width: itemWidth, height: 180, borderRadius: borderRadius),
      ]);
    }
    final itemWidth = (mediaWidth - (2 * spacing)) / 3;
    return Row(children: [
      _buildMediaItem(context: context, media: firestoreListener.getMediaById(mediaIds[0]), width: itemWidth, height: 120, borderRadius: borderRadius),
      const SizedBox(width: spacing),
      _buildMediaItem(context: context, media: firestoreListener.getMediaById(mediaIds[1]), width: itemWidth, height: 120, borderRadius: borderRadius),
      const SizedBox(width: spacing),
      _buildMediaItem(context: context, media: firestoreListener.getMediaById(mediaIds[2]), width: itemWidth, height: 120, borderRadius: borderRadius),
    ]);
  }

  Widget _buildMediaItem({required BuildContext context, required MediaModel? media, required double width, required double height, required double borderRadius}) {
    if (media == null) {
      return Container(width: width, height: height, decoration: BoxDecoration(color: Colors.grey[300]?.withOpacity(0.5), borderRadius: BorderRadius.circular(borderRadius)), child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0)));
    }
    if (media.type == 'image') {
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: media.url))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CachedNetworkImage(imageUrl: media.url, width: width, height: height, fit: BoxFit.cover, placeholder: (context, url) => Container(color: Colors.grey[300]?.withOpacity(0.5)), errorWidget: (context, url, error) => Container(color: Colors.grey[300]?.withOpacity(0.5), child: Icon(Icons.broken_image, color: Colors.grey[600]))),
        ),
      );
    }
    if (media.type == 'video') {
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenVideoPlayer(videoUrl: media.url))),
        child: _MessageVideoPlayer(videoUrl: media.url, width: width, height: height, borderRadius: borderRadius),
      );
    }
    return const SizedBox.shrink();
  }
}

class _MessageVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final double borderRadius;

  const _MessageVideoPlayer({Key? key, required this.videoUrl, required this.width, required this.height, required this.borderRadius}) : super(key: key);

  @override
  _MessageVideoPlayerState createState() => _MessageVideoPlayerState();
}

class _MessageVideoPlayerState extends State<_MessageVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))..initialize().then((_) { if (mounted) setState(() => _isInitialized = true); })..setLooping(true);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: widget.width, height: widget.height, color: Colors.black,
        child: _isInitialized
            ? Stack(alignment: Alignment.center, fit: StackFit.expand, children: [FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: _controller.value.size.width, height: _controller.value.size.height, child: VideoPlayer(_controller))), Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.white, size: 30))])
            : const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)),
      ),
    );
  }
}

class _SharedPostPreview extends StatelessWidget {
  final String postId;
  const _SharedPostPreview({required this.postId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/post_detail', arguments: postId),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('Post').doc(postId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) return const Padding(padding: EdgeInsets.all(16.0), child: Text('Bài viết đã bị xóa.', style: TextStyle(fontStyle: FontStyle.italic)));
            final post = PostModel.fromMap(snapshot.data!.id, snapshot.data!.data() as Map<String, dynamic>);
            final author = context.read<FirestoreListener>().getUserById(post.authorId);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(children: [CircleAvatar(radius: 18, backgroundImage: (author?.avatar.isNotEmpty ?? false) ? NetworkImage(author!.avatar.first) : null, child: (author?.avatar.isEmpty ?? true) ? const Icon(Icons.person, size: 18) : null), const SizedBox(width: 8), Expanded(child: Text(author?.name ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))]),
                ),
                if (post.content.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis)),
                if (post.mediaIds.isNotEmpty) _buildMediaPreview(context, post),
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
    if (media.type == 'video') return Container(height: 150, decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.vertical(bottom: Radius.circular(15))), child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 40)));
    return ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)), child: CachedNetworkImage(imageUrl: media.url, height: 150, width: double.infinity, fit: BoxFit.cover));
  }
}

class _GroupInvitePreview extends StatefulWidget {
  final QRInviteData qrData;
  final String groupId;
  final bool isAlreadyMember;
  final String currentUserId;

  const _GroupInvitePreview({
    required this.qrData,
    required this.groupId,
    required this.isAlreadyMember,
    required this.currentUserId,
  });

  @override
  State<_GroupInvitePreview> createState() => _GroupInvitePreviewState();
}

class _GroupInvitePreviewState extends State<_GroupInvitePreview> {
  bool _isLoading = false;
  final GroupRequest _groupRequest = GroupRequest();

  void _handleJoinGroup() async {
    if (widget.isAlreadyMember || _isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('Group')
          .doc(widget.groupId)
          .get();
      
      if (!groupDoc.exists) {
        if (mounted) NotificationService().showErrorDialog(context: context, title: 'Lỗi', message: 'Nhóm không còn tồn tại.');
        return;
      }
      final group = GroupModel.fromMap(groupDoc.id, groupDoc.data()!);
      if (group.members.contains(widget.currentUserId)) {
        if (mounted) NotificationService().showSuccessDialog(context: context, title: 'Thông báo', message: 'Bạn đã ở trong nhóm này.');
        return; 
      }
      await _groupRequest.joinGroup(widget.groupId, widget.currentUserId);
      if (mounted) {
        NotificationService().showSuccessDialog(
          context: context,
          title: 'Thành công',
          message: 'Đã tham gia nhóm "${widget.qrData.groupName}".',
        );
      }
    } catch (e) {
      print('Lỗi tham gia nhóm từ lời mời: $e');
      if (mounted) {
        NotificationService().showErrorDialog(
          context: context,
          title: 'Thất bại',
          message: 'Không thể tham gia nhóm. $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToGroupInfo() {
    Navigator.pushNamed(
      context,
      '/group_management',
      arguments: widget.groupId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCover = widget.qrData.groupCover?.isNotEmpty ?? false;

    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300)
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _navigateToGroupInfo, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: hasCover 
                      ? CachedNetworkImageProvider(widget.qrData.groupCover!) 
                      : null,
                    child: !hasCover 
                      ? const Icon(Icons.groups, size: 24) 
                      : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.qrData.groupName, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), 
                          overflow: TextOverflow.ellipsis
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lời mời từ ${widget.qrData.inviterName}', 
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: widget.isAlreadyMember 
              ? _navigateToGroupInfo 
              : _handleJoinGroup,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      widget.isAlreadyMember ? 'Xem thông tin' : 'Tham gia nhóm',
                      style: TextStyle(
                        color: widget.isAlreadyMember ? AppColors.textPrimary : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}