import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShareUserQRToMessengerView extends StatefulWidget {
  final String qrDataString;

  const ShareUserQRToMessengerView({
    Key? key,
    required this.qrDataString,
  }) : super(key: key);

  @override
  State<ShareUserQRToMessengerView> createState() => _ShareUserQRToMessengerViewState();
}

class _ShareUserQRToMessengerViewState extends State<ShareUserQRToMessengerView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _friends = [];
  List<UserModel> _filteredFriends = [];
  bool _isLoading = true;
  String _searchQuery = '';
  // Map để theo dõi trạng thái gửi của từng người (đang gửi/đã gửi)
  final Map<String, bool> _sendingStatus = {}; 
  final Map<String, bool> _sentStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final currentUser = userService.currentUser;
      
      if (currentUser != null && currentUser.friends.isNotEmpty) {
        // Chia nhỏ danh sách bạn bè để query (tối đa 10 người mỗi lần query whereIn)
        final chunks = <List<String>>[];
        for (var i = 0; i < currentUser.friends.length; i += 10) {
          chunks.add(
            currentUser.friends.sublist(
              i, 
              i + 10 > currentUser.friends.length ? currentUser.friends.length : i + 10
            )
          );
        }

        for (final chunk in chunks) {
          final snapshot = await _firestore
              .collection('User')
              .where('id', whereIn: chunk)
              .get();
          
          final friends = snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc)) // <--- ĐÃ SỬA LỖI TẠI ĐÂY
              .toList();
          _friends.addAll(friends);
        }
      }
      
      if (mounted) {
        setState(() {
          _filteredFriends = _friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi tải bạn bè: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterFriends(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFriends = _friends;
      } else {
        _filteredFriends = _friends.where((friend) {
          return friend.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _sendQRToFriend(UserModel friend) async {
    setState(() => _sendingStatus[friend.id] = true);

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final currentUser = userService.currentUser!;

      // 1. Tìm đoạn chat riêng (Private Chat) giữa 2 người
      String? chatId;
      
      final chatQuery = await _firestore
          .collection('Chat')
          .where('members', arrayContains: currentUser.id)
          .get();

      for (var doc in chatQuery.docs) {
        final data = doc.data();
        final members = List<String>.from(data['members']);
        // Kiểm tra đúng loại chat private và chứa người kia
        if (data['type'] == 'private' && members.contains(friend.id)) {
          chatId = doc.id;
          break;
        }
      }

      // 2. Nếu chưa có chat, tạo mới
      if (chatId == null) {
        final newChatRef = await _firestore.collection('Chat').add({
          'type': 'private',
          'members': [currentUser.id, friend.id],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': 'Đã gửi mã QR',
          'isSeen': {
             currentUser.id: true,
             friend.id: false,
          }
        });
        chatId = newChatRef.id;
      }

      // 3. Gửi tin nhắn chứa mã QR
      await _firestore.collection('Chat').doc(chatId).collection('messages').add({
        'senderId': currentUser.id,
        'content': widget.qrDataString, // Chuỗi JSON QR
        'type': 'qr_user', 
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      // 4. Cập nhật lastMessage cho chat
      await _firestore.collection('Chat').doc(chatId).update({
        'lastMessage': '${currentUser.name} đã gửi mã QR',
        'updatedAt': FieldValue.serverTimestamp(),
        'isSeen.${friend.id}': false,
      });

      if (mounted) {
        setState(() {
          _sendingStatus[friend.id] = false;
          _sentStatus[friend.id] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã gửi cho ${friend.name}')),
        );
      }
    } catch (e) {
      print('Lỗi gửi tin nhắn: $e');
      if (mounted) {
        setState(() => _sendingStatus[friend.id] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi thất bại, vui lòng thử lại')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi qua Messenger'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterFriends,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn bè...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          
          // Danh sách bạn bè
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFriends.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty 
                              ? 'Bạn chưa có bạn bè nào' 
                              : 'Không tìm thấy kết quả',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = _filteredFriends[index];
                          final isSending = _sendingStatus[friend.id] ?? false;
                          final isSent = _sentStatus[friend.id] ?? false;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              backgroundImage: friend.avatar.isNotEmpty
                                  ? CachedNetworkImageProvider(friend.avatar.first)
                                  : null,
                              child: friend.avatar.isEmpty
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            title: Text(
                              friend.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            trailing: isSent
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Đã gửi',
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 12),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: isSending
                                        ? null
                                        : () => _sendQRToFriend(friend),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 0),
                                    ),
                                    child: isSending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Gửi',
                                            style: TextStyle(
                                                color: Colors.white, fontSize: 13),
                                          ),
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