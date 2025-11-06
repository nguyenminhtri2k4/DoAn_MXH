
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/follow_request.dart';
import 'package:mangxahoi/request/user_request.dart';

class FollowViewModel extends ChangeNotifier {
  final String userId; // Đây là Document ID của người đang được xem
  final FollowRequest _followRequest = FollowRequest();
  final UserRequest _userRequest = UserRequest();

  // Cache Document ID của người dùng hiện tại để không phải fetch lại liên tục
  String? _currentUserDocId;

  FollowViewModel({required this.userId});

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
      final user = await _userRequest.getUserData(id);
      if (user != null) {
        users.add(user);
      }
    }
    return users;
  }

  // --- HÀM MỚI ĐỂ LẤY ĐÚNG ID (DOCUMENT ID) ---
  
  Future<String?> _getCurrentUserDocId() async {
    // Nếu đã có ID trong cache thì trả về luôn
    if (_currentUserDocId != null) return _currentUserDocId;

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return null;

    try {
      // Lấy thông tin User từ Firestore dựa trên UID để tìm ra Document ID thực sự
      final userModel = await _userRequest.getUserByUid(authUser.uid);
      if (userModel != null) {
        _currentUserDocId = userModel.id; // Lưu lại Document ID
        return _currentUserDocId;
      }
    } catch (e) {
      debugPrint("Lỗi khi lấy Document ID người dùng hiện tại: $e");
    }
    return null;
  }

  // --- CÁC HÀM XỬ LÝ FOLLOW (ĐÃ CẬP NHẬT DÙNG DOC ID) ---

  Future<bool> isFollowing(String targetUserId) async {
    final currentDocId = await _getCurrentUserDocId();
    if (currentDocId == null) return false;
    if (currentDocId == targetUserId) return false;
    
    return _followRequest.isFollowing(currentDocId, targetUserId);
  }

  Future<void> followUser(String targetUserId) async {
    final currentDocId = await _getCurrentUserDocId();
    if (currentDocId == null) return;
    
    await _followRequest.followUser(currentDocId, targetUserId);
    notifyListeners();
  }

  Future<void> unfollowUser(String targetUserId) async {
    final currentDocId = await _getCurrentUserDocId();
    if (currentDocId == null) return;

    await _followRequest.unfollowUser(currentDocId, targetUserId);
    notifyListeners();
  }
}