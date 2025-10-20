
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
  List<UserModel> _filteredFriends = [];
  final List<UserModel> _selectedFriends = [];
  bool _isLoading = true;
  bool _isSending = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchController.addListener(_filterFriends);
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
        _filteredFriends = friendsList;
        _isLoading = false;
      });
    } else {
       setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFriends = _friends.where((friend) {
        return friend.name.toLowerCase().contains(query);
      }).toList();
    });
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isSending 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Text('Gửi'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bạn bè...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 24),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFriends.isEmpty
                    ? Center(child: Text(_friends.isEmpty ? 'Bạn chưa có bạn bè nào.' : 'Không tìm thấy bạn bè.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: _filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = _filteredFriends[index];
                          final isSelected = _selectedFriends.contains(friend);
                          final avatarImage = friend.avatar.isNotEmpty ? NetworkImage(friend.avatar.first) : null;
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundImage: avatarImage,
                                child: avatarImage == null ? const Icon(Icons.person) : null,
                              ),
                              title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              trailing: Checkbox(
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
                                activeColor: AppColors.primary,
                              ),
                              onTap: () {
                                 setState(() {
                                    if (isSelected) {
                                      _selectedFriends.remove(friend);
                                    } else {
                                      _selectedFriends.add(friend);
                                    }
                                  });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}