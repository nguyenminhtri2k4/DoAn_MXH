
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ THÊM
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/locket_request.dart';
import 'package:mangxahoi/request/user_request.dart'; // ✅ THÊM LẠI
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LocketManageFriendsView extends StatefulWidget {
  const LocketManageFriendsView({super.key});

  @override
  State<LocketManageFriendsView> createState() => _LocketManageFriendsViewState();
}

class _LocketManageFriendsViewState extends State<LocketManageFriendsView> {
  final LocketRequest _locketRequest = LocketRequest();
  final UserRequest _userRequest = UserRequest(); // ✅ THÊM LẠI
  final FirebaseAuth _auth = FirebaseAuth.instance; // ✅ THÊM

  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  // ✅ HÀM MỚI: Lấy currentUserId từ Firebase Auth
  Future<void> _initUser() async {
    print("🔧 [LocketManageFriends] Bắt đầu init...");
    
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        print("⚠️ [LocketManageFriends] Chưa đăng nhập Firebase");
        setState(() => _isLoading = false);
        return;
      }

      print("🔍 [LocketManageFriends] Firebase UID: ${firebaseUser.uid}");
      
      // ✅ Lấy user từ Firestore bằng UID
      final user = await _userRequest.getUserByUid(firebaseUser.uid)
          .timeout(const Duration(seconds: 5));
      
      if (user != null) {
        print("✅ [LocketManageFriends] Đã tìm thấy user: ${user.id}");
        setState(() {
          _currentUserId = user.id;
          _isLoading = false;
        });
      } else {
        print("⚠️ [LocketManageFriends] Không tìm thấy user trong Firestore");
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      print("❌ [LocketManageFriends] Lỗi init: $e");
      print("❌ [LocketManageFriends] StackTrace: $stackTrace");
      setState(() => _isLoading = false);
    }
  }

  void _toggleFriend(String friendId, bool isSelected) {
    if (_currentUserId == null) return;

    // 1. Gửi request lên server
    if (isSelected) {
      _locketRequest.addLocketFriend(_currentUserId!, friendId);
    } else {
      _locketRequest.removeLocketFriend(_currentUserId!, friendId);
    }

    // 2. Cập nhật local cache
    context.read<FirestoreListener>().updateLocalLocketFriend(_currentUserId!, friendId, isSelected);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ KIỂM TRA: Đang loading
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Locket'),
          backgroundColor: AppColors.backgroundLight,
        ),
        backgroundColor: AppColors.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải thông tin người dùng...'),
            ],
          ),
        ),
      );
    }

    // ✅ KIỂM TRA: Không có currentUserId
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Locket'),
          backgroundColor: AppColors.backgroundLight,
        ),
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Lỗi: Không tìm thấy người dùng.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng đăng xuất và đăng nhập lại',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _initUser();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Lấy FirestoreListener
    final firestoreListener = context.watch<FirestoreListener>();
    final freshCurrentUser = firestoreListener.getUserById(_currentUserId!);

    // ✅ KIỂM TRA: Listener chưa sync xong
    if (freshCurrentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Locket'),
          backgroundColor: AppColors.backgroundLight,
        ),
        backgroundColor: AppColors.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang đồng bộ dữ liệu...'),
            ],
          ),
        ),
      );
    }

    // ✅ Lấy danh sách bạn bè
    final allFriendIds = freshCurrentUser.friends;
    final locketFriendIds = freshCurrentUser.locketFriends;

    final allFriendsDetails = allFriendIds
        .map((id) => firestoreListener.getUserById(id))
        .whereType<UserModel>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Locket'),
        backgroundColor: AppColors.backgroundLight,
      ),
      backgroundColor: AppColors.background,
      body: allFriendsDetails.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn chưa có bạn bè nào',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thêm bạn bè để bắt đầu chia sẻ Locket',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: allFriendsDetails.length,
              itemBuilder: (context, index) {
                final friend = allFriendsDetails[index];
                final bool isLocketFriend = locketFriendIds.contains(friend.id);
                final friendAvatar = (friend.avatar.isNotEmpty) ? friend.avatar.first : null;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: (friendAvatar != null
                              ? CachedNetworkImageProvider(friendAvatar)
                              : const AssetImage('assets/logoapp.png'))
                          as ImageProvider,
                    ),
                    title: Text(
                      friend.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: isLocketFriend
                        ? const Text(
                            'Bạn Locket',
                            style: TextStyle(color: AppColors.primary, fontSize: 13),
                          )
                        : null,
                    trailing: Checkbox(
                      value: isLocketFriend,
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          _toggleFriend(friend.id, newValue);
                        }
                      },
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}