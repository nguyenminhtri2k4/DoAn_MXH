import 'package:flutter/material.dart';
import 'package:mangxahoi/constant/app_colors.dart';
// Không cần PostModel
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/request/chat_request.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/notification/notification_service.dart';

class ShareQRToMessengerView extends StatefulWidget {
  // Thay đổi tham số: nhận chuỗi dữ liệu QR, tên nhóm và ID nhóm
  final String qrDataString;
  final String groupName;
  final String groupId;

  const ShareQRToMessengerView({
    super.key,
    required this.qrDataString,
    required this.groupName,
    required this.groupId,
  });

  @override
  State<ShareQRToMessengerView> createState() => _ShareQRToMessengerViewState();
}

class _ShareQRToMessengerViewState extends State<ShareQRToMessengerView> {
  final List<UserModel> _selectedFriends = [];
  bool _isSending = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _handleSend() async {
    if (_selectedFriends.isEmpty) {
      NotificationService().showErrorDialog(
        context: context,
        title: 'Chưa chọn người nhận',
        message: 'Vui lòng chọn ít nhất một người bạn để mời.',
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
        final chatId =
            await chatRequest.getOrCreatePrivateChat(currentUser.id, friend.id);

        // 2. Tạo tin nhắn đặc biệt loại 'share_group_qr'
        final message = MessageModel(
          id: '',
          // Gửi payload QR trong content
          // Giao diện chat sẽ đọc content này và hiển thị nút "Tham gia"
          content: widget.qrDataString,
          createdAt: DateTime.now(),
          senderId: currentUser.uid, // Dùng auth Uid
          mediaIds: [], // Không phải media
          status: 'sent',
          type: 'share_group_qr', // Loại tin nhắn mới
          sharedPostId: widget.groupId, // ID của nhóm để tham chiếu
        );

        // 3. Gửi tin nhắn
        await chatRequest.sendMessage(chatId, message);
        successCount++;
      } catch (e) {
        print('Lỗi khi gửi lời mời nhóm cho ${friend.name}: $e');
      }
    }

    setState(() => _isSending = false);

    if (mounted) {
      Navigator.pop(context); // Đóng màn hình chọn bạn
      NotificationService().showSuccessDialog(
        context: context,
        title: 'Đã gửi',
        message: 'Đã gửi lời mời nhóm đến $successCount người bạn.',
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(() {
      setState(() {});
    });
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Phần logic lấy danh sách bạn bè giữ nguyên như file gốc
    final firestoreListener = context.watch<FirestoreListener>();
    final userService = context.read<UserService>();
    final staleCurrentUser = userService.currentUser;

    if (staleCurrentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mời vào nhóm')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentUser = firestoreListener.getUserById(staleCurrentUser.id);
    List<UserModel> allFriends = [];
    bool isLoading = true; 

    if (currentUser != null) {
      isLoading = false; 
      allFriends = currentUser.friends
          .map((id) => firestoreListener.getUserById(id))
          .where((user) => user != null)
          .cast<UserModel>()
          .toList();
    }

    final query = _searchController.text.toLowerCase();
    final filteredFriends = allFriends.where((friend) {
      return friend.name.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        // Thay đổi tiêu đề
        title: const Text('Mời vào nhóm'),
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Gửi'), // Giữ nguyên chữ 'Gửi'
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              // ... (Phần search UI giữ nguyên)
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm bạn bè để mời...', // Thay đổi hint
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: Colors.grey[400], size: 24),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: Colors.grey[400], size: 20),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            // Phần danh sách bạn bè giữ nguyên
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredFriends.isEmpty
                    ? Center(
                        child: Text(allFriends.isEmpty
                            ? 'Bạn chưa có bạn bè nào.'
                            : 'Không tìm thấy bạn bè.'))
                    : ListView.builder(
                        // ... (Phần ListView giữ nguyên)
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = filteredFriends[index];
                          final isSelected = _selectedFriends.contains(friend);
                          final avatarImage = friend.avatar.isNotEmpty
                              ? NetworkImage(friend.avatar.first)
                              : null;
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundImage: avatarImage,
                                child: avatarImage == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(friend.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
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