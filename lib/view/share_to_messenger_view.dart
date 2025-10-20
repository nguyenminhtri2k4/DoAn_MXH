// lib/view/share_to_messenger_view.dart
import 'package:flutter/material.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/request/chat_request.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/notification/notification_service.dart';

class ShareToMessengerView extends StatefulWidget {
  final PostModel postToShare;

  const ShareToMessengerView({super.key, required this.postToShare});

  @override
  State<ShareToMessengerView> createState() => _ShareToMessengerViewState();
}

class _ShareToMessengerViewState extends State<ShareToMessengerView> {
  List<UserModel> _friends = [];
  final List<UserModel> _selectedFriends = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final userService = context.read<UserService>();
    final firestoreListener = context.read<FirestoreListener>();
    
    final currentUser = userService.currentUser;
    if (currentUser != null) {
      final friendIds = currentUser.friends;
      final friendsList = friendIds
          .map((id) => firestoreListener.getUserById(id))
          .where((user) => user != null)
          .cast<UserModel>()
          .toList();
      setState(() {
        _friends = friendsList;
        _isLoading = false;
      });
    } else {
       setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSend() async {
      if (_selectedFriends.isEmpty) {
          NotificationService().showErrorDialog(
              context: context,
              title: 'Chưa chọn người nhận',
              message: 'Vui lòng chọn ít nhất một người bạn để gửi.',
          );
          return;
      }

      setState(() => _isSending = true);

      final currentUser = context.read<UserService>().currentUser;
      if (currentUser == null) {
          setState(() => _isSending = false);
          return;
      }

      final chatRequest = ChatRequest();
      int successCount = 0;

      for (final friend in _selectedFriends) {
          try {
              // 1. Lấy hoặc tạo phòng chat
              final chatId = await chatRequest.getOrCreatePrivateChat(currentUser.id, friend.id);

              // 2. Tạo tin nhắn đặc biệt
              final message = MessageModel(
                  id: '',
                  content: '${currentUser.name} đã chia sẻ một bài viết.',
                  createdAt: DateTime.now(),
                  senderId: currentUser.uid,
                  mediaIds: [],
                  status: 'sent',
                  type: 'share_post', // Loại tin nhắn đặc biệt
                  sharedPostId: widget.postToShare.id, // ID bài viết được chia sẻ
              );
              
              // 3. Gửi tin nhắn
              await chatRequest.sendMessage(chatId, message);
              successCount++;
          } catch (e) {
              print('Lỗi khi gửi tin nhắn cho ${friend.name}: $e');
          }
      }

      setState(() => _isSending = false);
      
      if (mounted) {
          Navigator.pop(context); // Đóng màn hình chọn bạn
          NotificationService().showSuccessDialog(
              context: context,
              title: 'Đã gửi',
              message: 'Đã gửi bài viết đến $successCount người bạn.',
          );
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi trong Messenger'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: (_selectedFriends.isEmpty || _isSending) ? null : _handleSend,
              child: _isSending 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Text('Gửi'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? const Center(child: Text('Bạn chưa có bạn bè nào.'))
              : ListView.builder(
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    final isSelected = _selectedFriends.contains(friend);
                    return CheckboxListTile(
                      secondary: CircleAvatar(
                        backgroundImage: friend.avatar.isNotEmpty ? NetworkImage(friend.avatar.first) : null,
                        child: friend.avatar.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      title: Text(friend.name),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedFriends.add(friend);
                          } else {
                            _selectedFriends.remove(friend);
                          }
                        });
                      },
                    );
                  },
                ),
    );
  }
}