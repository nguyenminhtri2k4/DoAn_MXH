// lib/view/locket/locket_manage_friends_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/locket_request.dart';
// import 'package:mangxahoi/request/user_request.dart'; // <-- Không cần nữa
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart'; // <-- THÊM IMPORT
import 'package:cached_network_image/cached_network_image.dart';

class LocketManageFriendsView extends StatefulWidget {
  const LocketManageFriendsView({super.key});

  @override
  State<LocketManageFriendsView> createState() => _LocketManageFriendsViewState();
}

class _LocketManageFriendsViewState extends State<LocketManageFriendsView> {
  final LocketRequest _locketRequest = LocketRequest();
  // final UserRequest _userRequest = UserRequest(); // <-- Không cần nữa

  // --- SỬA LỖI: Xóa các state list, chỉ giữ lại ID ---
  // bool _isLoading = true; // <-- Sẽ được xử lý trong build
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Chỉ lấy ID, không lấy data
    final currentUser = context.read<UserService>().currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.id;
    }
    // --- SỬA LỖI: Xóa _loadData() ---
  }

  // --- SỬA LỖI: Xóa hàm _loadData ---

  // --- SỬA LỖI: Cập nhật hàm _toggleFriend ---
  void _toggleFriend(BuildContext context, String friendId, bool isSelected) {
    if (_currentUserId == null) return;

    // 1. Gửi request lên server (không cần await)
    if (isSelected) {
      _locketRequest.addLocketFriend(_currentUserId!, friendId);
    } else {
      _locketRequest.removeLocketFriend(_currentUserId!, friendId);
    }

    // 2. Cập nhật local state (cache) NGAY LẬP TỨC
    // Dùng context.read vì đang ở trong 1 hàm
    context.read<FirestoreListener>().updateLocalLocketFriend(_currentUserId!, friendId, isSelected);

    // 3. Không cần setState, vì listener sẽ notify và build() (đang watch)
    // sẽ tự động chạy lại.
  }

  @override
  Widget build(BuildContext context) {
    // --- BẮT ĐẦU SỬA LỖI ---
    // 1. WATCH (lắng nghe) FirestoreListener
    final firestoreListener = context.watch<FirestoreListener>();

    // 2. Xử lý nếu ID người dùng chưa có
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý Locket')),
        body: const Center(child: Text('Lỗi: Không tìm thấy người dùng.')),
      );
    }

    // 3. Lấy currentUser MỚI NHẤT từ listener
    final freshCurrentUser = firestoreListener.getUserById(_currentUserId!);

    // 4. Xử lý nếu listener chưa tải xong
    if (freshCurrentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý Locket')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 5. Lấy danh sách bạn bè MỚI NHẤT từ freshCurrentUser
    final allFriendIds = freshCurrentUser.friends;
    final locketFriendIds = freshCurrentUser.locketFriends; // List locket mới nhất

    // 6. Build chi tiết bạn bè ngay trong hàm build
    final allFriendsDetails = allFriendIds
        .map((id) => firestoreListener.getUserById(id))
        .whereType<UserModel>() // Lọc ra những user null (nếu có)
        .toList();

    // 7. Xác định trạng thái tải
    final bool isLoading = false; // Đã tải xong vì freshCurrentUser != null
    // --- KẾT THÚC SỬA LỖI ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Locket'),
        backgroundColor: AppColors.backgroundLight,
      ),
      backgroundColor: AppColors.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allFriendsDetails.isEmpty
              ? const Center(child: Text('Bạn chưa có bạn bè nào.'))
              : ListView.builder(
                  itemCount: allFriendsDetails.length,
                  itemBuilder: (context, index) {
                    final friend = allFriendsDetails[index];
                    
                    // SỬA LỖI: Dùng list locketFriendIds mới nhất
                    final bool isLocketFriend = locketFriendIds.contains(friend.id);
                    final friendAvatar = (friend.avatar.isNotEmpty) ? friend.avatar.first : null;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (friendAvatar != null
                                  ? CachedNetworkImageProvider(friendAvatar)
                                  : const AssetImage('assets/logoapp.png'))
                              as ImageProvider,
                        ),
                        title: Text(friend.name, style: const TextStyle(color: AppColors.textPrimary)),
                        trailing: Checkbox(
                          value: isLocketFriend,
                          onChanged: (bool? newValue) {
                            if (newValue != null) {
                              // SỬA LỖI: Truyền context vào
                              _toggleFriend(context, friend.id, newValue);
                            }
                          },
                          activeColor: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}