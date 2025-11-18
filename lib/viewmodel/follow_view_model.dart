
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/follow_request.dart';
import 'package:mangxahoi/request/user_request.dart';

class FollowViewModel extends ChangeNotifier {
  final String userId; // Document ID của người đang được xem
  final FollowRequest _followRequest = FollowRequest();
  final UserRequest _userRequest = UserRequest();

  String? _currentUserDocId;
  String? get currentUserDocId => _currentUserDocId; // ✅ Expose để UI có thể check

  // ✅ THÊM: Trạng thái loading
  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  FollowViewModel({required this.userId}) {
    _init(); // ✅ Tự động init như GroupsViewModel
  }

  // ✅ THÊM: Hàm init tự động
  void _init() async {
    print('🔧 [FollowViewModel] Bắt đầu khởi tạo cho userId: $userId');
    _isInitializing = true;
    notifyListeners();

    try {
      await _loadCurrentUserDocId();
    } catch (e) {
      print('❌ [FollowViewModel] Lỗi khi init: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
      print('✅ [FollowViewModel] Khởi tạo hoàn tất. currentUserDocId: $_currentUserDocId');
    }
  }

  // ✅ SỬA: Đổi tên và public để có thể reload
  Future<void> _loadCurrentUserDocId() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      print('⚠️ [FollowViewModel] Chưa đăng nhập Firebase Auth');
      return;
    }

    try {
      print('🔍 [FollowViewModel] Đang tìm Document ID cho UID: ${authUser.uid}');
      final userModel = await _userRequest.getUserByUid(authUser.uid);
      
      if (userModel != null) {
        _currentUserDocId = userModel.id;
        print('✅ [FollowViewModel] Đã lấy Document ID: $_currentUserDocId');
      } else {
        print('⚠️ [FollowViewModel] Không tìm thấy user trong Firestore');
      }
    } catch (e) {
      print('❌ [FollowViewModel] Lỗi khi lấy Document ID: $e');
    }
  }

  // ✅ Giữ nguyên - nhưng không cần cache vì đã load trong init
  Future<String?> _getCurrentUserDocId() async {
    if (_currentUserDocId != null) return _currentUserDocId;
    
    // Nếu chưa có, load lại
    await _loadCurrentUserDocId();
    return _currentUserDocId;
  }

  Stream<List<UserModel>> get followersStream => _followRequest
      .getFollowers(userId)
      .asyncMap((userIds) => _getUsersDetails(userIds));

  Stream<List<UserModel>> get followingStream => _followRequest
      .getFollowing(userId)
      .asyncMap((userIds) => _getUsersDetails(userIds));

  Future<List<UserModel>> _getUsersDetails(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    List<UserModel> users = [];
    for (var id in userIds) {
      try {
        final user = await _userRequest.getUserData(id);
        if (user != null) {
          users.add(user);
        }
      } catch (e) {
        print('⚠️ [FollowViewModel] Lỗi khi lấy thông tin user $id: $e');
      }
    }
    return users;
  }

  Future<bool> isFollowing(String targetUserId) async {
    final currentDocId = await _getCurrentUserDocId();
    if (currentDocId == null) {
      print('⚠️ [FollowViewModel] isFollowing: currentDocId = null');
      return false;
    }
    if (currentDocId == targetUserId) return false;
    
    return _followRequest.isFollowing(currentDocId, targetUserId);
  }

  Future<void> followUser(String targetUserId) async {
    final currentDocId = await _getCurrentUserDocId();
    if (currentDocId == null) {
      print('⚠️ [FollowViewModel] followUser: currentDocId = null, không thể follow');
      return;
    }
    
    print('🔄 [FollowViewModel] Follow user: $currentDocId -> $targetUserId');
    await _followRequest.followUser(currentDocId, targetUserId);
    notifyListeners();
  }

  Future<void> unfollowUser(String targetUserId) async {
    final currentDocId = await _getCurrentUserDocId();
    if (currentDocId == null) {
      print('⚠️ [FollowViewModel] unfollowUser: currentDocId = null, không thể unfollow');
      return;
    }

    print('🔄 [FollowViewModel] Unfollow user: $currentDocId -> $targetUserId');
    await _followRequest.unfollowUser(currentDocId, targetUserId);
    notifyListeners();
  }
}