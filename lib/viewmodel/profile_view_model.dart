
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/request/friend_request_manager.dart'; // Thêm import

class ProfileViewModel extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _userRequest = UserRequest();
  final _postRequest = PostRequest();
  final _friendManager = FriendRequestManager(); // Thêm FriendRequestManager

  UserModel? user;
  UserModel? _currentUserData; // Thêm biến lưu data user hiện tại
  bool isLoading = true;
  Stream<List<PostModel>>? userPostsStream;
  bool isCurrentUserProfile = false;
  String friendshipStatus = 'loading'; // Trạng thái: loading, none, friends, pending_sent, pending_received

  Future<void> loadProfile({String? userId}) async {
    try {
      isLoading = true;
      friendshipStatus = 'loading';
      notifyListeners();

      final currentUserAuth = _auth.currentUser;
      String? targetUserId = userId;

      // Lấy thông tin người dùng đang đăng nhập
      if (currentUserAuth != null) {
        _currentUserData = await _userRequest.getUserByUid(currentUserAuth.uid);
      }

      // Nếu không có userId, mặc định là xem trang của người dùng hiện tại
      if (targetUserId == null && _currentUserData != null) {
        targetUserId = _currentUserData!.id;
      }

      if (targetUserId != null) {
        user = await _userRequest.getUserData(targetUserId);
        
        if (_currentUserData != null && user != null) {
          isCurrentUserProfile = user!.uid == _currentUserData!.uid;
          if (!isCurrentUserProfile) {
            // Lấy trạng thái bạn bè nếu không phải trang của mình
            friendshipStatus = await _friendManager.getFriendshipStatus(_currentUserData!.id, user!.id);
          } else {
            friendshipStatus = 'self';
          }
        } else {
          isCurrentUserProfile = false;
          friendshipStatus = 'none';
        }
      } else {
        user = null;
        isCurrentUserProfile = false;
        friendshipStatus = 'none';
      }
      
      if (user != null) {
        userPostsStream = _postRequest.getPostsByAuthorId(user!.id);
      }

    } catch (e) {
      print('❌ Lỗi khi tải thông tin cá nhân: $e');
      friendshipStatus = 'none';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ==================== THÊM CÁC HÀM HÀNH ĐỘNG ====================
  Future<void> sendFriendRequest() async {
    if (_currentUserData == null || user == null) return;
    await _friendManager.sendRequest(_currentUserData!.id, user!.id);
    await loadProfile(userId: user!.id); // Tải lại để cập nhật trạng thái
  }

  Future<void> unfriend() async {
    if (_currentUserData == null || user == null) return;
    await _friendManager.unfriend(_currentUserData!.id, user!.id);
    await loadProfile(userId: user!.id);
  }
  
  Future<void> blockUser() async {
    if (_currentUserData == null || user == null) return;
    await _friendManager.blockUser(_currentUserData!.id, user!.id);
    await loadProfile(userId: user!.id);
  }
  // =================================================================

  UserModel _copyUserWith({
    String? name,
    String? bio,
    String? phone,
    String? gender,
    String? relationship,
    String? liveAt,
    String? comeFrom,
    DateTime? dateOfBirth,
    List<String>? avatar,
    Map<String, bool>? notificationSettings,
  }) {
    // ... (Giữ nguyên không thay đổi)
        return UserModel(
      id: user!.id,
      uid: user!.uid,
      name: name ?? user!.name,
      email: user!.email,
      password: user!.password,
      phone: phone ?? user!.phone,
      bio: bio ?? user!.bio,
      gender: gender ?? user!.gender,
      liveAt: liveAt ?? user!.liveAt,
      comeFrom: comeFrom ?? user!.comeFrom,
      role: user!.role,
      relationship: relationship ?? user!.relationship,
      statusAccount: user!.statusAccount,
      followerCount: user!.followerCount,
      followingCount: user!.followingCount,
      createAt: user!.createAt,
      dateOfBirth: dateOfBirth ?? user!.dateOfBirth,
      lastActive: user!.lastActive,
      avatar: avatar ?? user!.avatar,
      friends: user!.friends,
      groups: user!.groups,
      posterList: user!.posterList,
      notificationSettings: notificationSettings ?? user!.notificationSettings,
    );
  }

  Future<void> updateAvatar(String newAvatarUrl) async {
    if (user == null || newAvatarUrl.trim().isEmpty) return;

    try {
      final updatedUser = _copyUserWith(
        avatar: [newAvatarUrl.trim()],
      );
      await _userRequest.updateUser(updatedUser);
      user = updatedUser;
      print('✅ Cập nhật avatar thành công');
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi khi cập nhật avatar: $e');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? phone,
    String? gender,
    String? relationship,
    String? liveAt,
    String? comeFrom,
    DateTime? dateOfBirth,
  }) async {
    if (user == null) return;

    try {
      isLoading = true;
      notifyListeners();

      final updatedUser = _copyUserWith(
        name: name,
        bio: bio,
        phone: phone,
        gender: gender,
        relationship: relationship,
        liveAt: liveAt,
        comeFrom: comeFrom,
        dateOfBirth: dateOfBirth,
      );

      await _userRequest.updateUser(updatedUser);
      user = updatedUser;
      
      print('✅ Cập nhật hồ sơ thành công');
    } catch (e) {
      print('❌ Lỗi khi cập nhật hồ sơ: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNotificationSetting(String key, bool value) async {
    if (user == null) return;
    try {
      final updatedSettings = Map<String, bool>.from(user!.notificationSettings);
      updatedSettings[key] = value;
      final updatedUser = _copyUserWith(notificationSettings: updatedSettings);
      user = updatedUser;
      notifyListeners();
      await _userRequest.updateUser(updatedUser);
      print('✅ Cập nhật cài đặt thông báo $key: $value');
    } catch (e) {
      print('❌ Lỗi khi cập nhật cài đặt thông báo: $e');
      await loadProfile();
    }
  }
}