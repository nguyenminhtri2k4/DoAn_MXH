import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart';

class ProfileViewModel extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _userRequest = UserRequest();

  UserModel? user;
  bool isLoading = false;

  Future<void> loadProfile() async {
    try {
      isLoading = true;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userData = await _userRequest.getUserByUid(currentUser.uid);
      user = userData;

    } catch (e) {
      print('❌ Lỗi khi tải thông tin cá nhân: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 🔧 Method helper để tạo bản copy của user với các thay đổi
  UserModel _copyUserWith({
    String? name,
    String? bio,
    String? phone,
    String? gender,
    String? relationship,
    String? liveAt,
    String? comeFrom,
    Map<String, bool>? notificationSettings,
  }) {
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
      dateOfBirth: user!.dateOfBirth,
      lastActive: user!.lastActive,
      avatar: user!.avatar,
      friends: user!.friends,
      groups: user!.groups,
      posterList: user!.posterList,
      notificationSettings: notificationSettings ?? user!.notificationSettings,
    );
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? phone,
    String? gender,
    String? relationship,
    String? liveAt,
    String? comeFrom,
  }) async {
    if (user == null) return;

    try {
      isLoading = true;
      notifyListeners();

      // Tạo user mới với thông tin đã cập nhật
      final updatedUser = _copyUserWith(
        name: name,
        bio: bio,
        phone: phone,
        gender: gender,
        relationship: relationship,
        liveAt: liveAt,
        comeFrom: comeFrom,
      );

      // Gọi API cập nhật
      await _userRequest.updateUser(updatedUser);
      
      // Cập nhật local state
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

  /// 🔔 Cập nhật cài đặt thông báo
  Future<void> updateNotificationSetting(String key, bool value) async {
    if (user == null) return;

    try {
      // Cập nhật map notification settings
      final updatedSettings = Map<String, bool>.from(user!.notificationSettings);
      updatedSettings[key] = value;

      // Tạo user mới với settings đã cập nhật
      final updatedUser = _copyUserWith(notificationSettings: updatedSettings);

      // Cập nhật local state ngay lập tức để UI mượt mà
      user = updatedUser;
      notifyListeners();

      // Gọi API cập nhật
      await _userRequest.updateUser(updatedUser);
      
      print('✅ Cập nhật cài đặt thông báo $key: $value');
    } catch (e) {
      print('❌ Lỗi khi cập nhật cài đặt thông báo: $e');
      // Reload lại profile nếu có lỗi
      await loadProfile();
    }
  }
}