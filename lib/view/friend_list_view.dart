import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart'; // Cần import UserRequest
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FriendListView extends StatefulWidget {
  final String userId;
  final String userName;

  const FriendListView({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FriendListView> createState() => _FriendListViewState();
}

class _FriendListViewState extends State<FriendListView> {
  // Dùng Future để tải danh sách một lần
  late Future<List<UserModel>> _friendsFuture;
  final UserRequest _userRequest = UserRequest();

  @override
  void initState() {
    super.initState();
    // Khởi tạo Future khi widget được tạo
    _friendsFuture = _loadAllFriends();
  }

  Future<List<UserModel>> _loadAllFriends() async {
    try {
      // 1. Lấy thông tin người dùng để lấy danh sách ID bạn bè
      final user = await _userRequest.getUserData(widget.userId);
      if (user == null || user.friends.isEmpty) {
        return []; // Trả về danh sách rỗng nếu không có bạn bè
      }

      // 2. Lấy thông tin chi tiết của TẤT CẢ bạn bè
      // (Phương thức getUsersByIds trong UserRequest đã hỗ trợ batching)
      final friendList = await _userRequest.getUsersByIds(user.friends);
      return friendList;
    } catch (e) {
      print('❌ Lỗi khi tải danh sách bạn bè: $e');
      rethrow; // Ném lỗi để FutureBuilder bắt
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bạn bè của ${widget.userName}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          // Đang tải...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Bị lỗi
          if (snapshot.hasError) {
            return Center(
                child: Text('Lỗi tải danh sách: ${snapshot.error}'));
          }

          // Không có dữ liệu hoặc danh sách rỗng
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Người này không có bạn bè nào.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Có dữ liệu
          final friends = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return _buildFriendTile(context, friend);
            },
          );
        },
      ),
    );
  }

  // Widget để hiển thị thông tin từng người bạn
  Widget _buildFriendTile(BuildContext context, UserModel friend) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: friend.avatar.isNotEmpty
              ? CachedNetworkImageProvider(friend.avatar.first)
              : null,
          backgroundColor: Colors.grey[200],
          child: friend.avatar.isEmpty
              ? const Icon(Icons.person, size: 28, color: Colors.grey)
              : null,
        ),
        title: Text(
          friend.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: friend.bio.isNotEmpty && friend.bio != "No"
            ? Text(
                friend.bio,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          // Khi nhấn vào, điều hướng đến trang cá nhân của người bạn đó
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: friend.id,
          );
        },
      ),
    );
  }
}