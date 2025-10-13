// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:mangxahoi/model/model_user.dart';
// import 'package:mangxahoi/model/model_post.dart';
// import 'package:mangxahoi/request/user_request.dart';
// import 'package:mangxahoi/request/post_request.dart';

// class ProfileViewModel extends ChangeNotifier {
//   final _auth = FirebaseAuth.instance;
//   final _userRequest = UserRequest();
//   final _postRequest = PostRequest();

//   UserModel? user;
//   bool isLoading = true;
//   Stream<List<PostModel>>? userPostsStream;

//   Future<void> loadProfile() async {
//     try {
//       isLoading = true;
//       notifyListeners();

//       final currentUser = _auth.currentUser;
//       if (currentUser == null) return;

//       final userData = await _userRequest.getUserByUid(currentUser.uid);
//       user = userData;

//       if (user != null) {
//         userPostsStream = _postRequest.getPostsByAuthorId(user!.id);
//       }

//     } catch (e) {
//       print('❌ Lỗi khi tải thông tin cá nhân: $e');
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }

//   // CẬP NHẬT HÀM NÀY
//   UserModel _copyUserWith({
//     String? name,
//     String? bio,
//     String? phone,
//     String? gender,
//     String? relationship,
//     String? liveAt,
//     String? comeFrom,
//     DateTime? dateOfBirth, // Thêm ngày sinh
//     List<String>? avatar, // Thêm avatar
//     Map<String, bool>? notificationSettings,
//   }) {
//     return UserModel(
//       id: user!.id,
//       uid: user!.uid,
//       name: name ?? user!.name,
//       email: user!.email,
//       password: user!.password,
//       phone: phone ?? user!.phone,
//       bio: bio ?? user!.bio,
//       gender: gender ?? user!.gender,
//       liveAt: liveAt ?? user!.liveAt,
//       comeFrom: comeFrom ?? user!.comeFrom,
//       role: user!.role,
//       relationship: relationship ?? user!.relationship,
//       statusAccount: user!.statusAccount,
//       followerCount: user!.followerCount,
//       followingCount: user!.followingCount,
//       createAt: user!.createAt,
//       dateOfBirth: dateOfBirth ?? user!.dateOfBirth, // Cập nhật
//       lastActive: user!.lastActive,
//       avatar: avatar ?? user!.avatar, // Cập nhật
//       friends: user!.friends,
//       groups: user!.groups,
//       posterList: user!.posterList,
//       notificationSettings: notificationSettings ?? user!.notificationSettings,
//     );
//   }

//   // CẬP NHẬT HÀM NÀY
//   Future<void> updateProfile({
//     String? name,
//     String? bio,
//     String? phone,
//     String? gender,
//     String? relationship,
//     String? liveAt,
//     String? comeFrom,
//     DateTime? dateOfBirth, // Thêm ngày sinh
//     String? avatarUrl, // Thêm avatar URL
//   }) async {
//     if (user == null) return;

//     try {
//       isLoading = true;
//       notifyListeners();

//       final updatedUser = _copyUserWith(
//         name: name,
//         bio: bio,
//         phone: phone,
//         gender: gender,
//         relationship: relationship,
//         liveAt: liveAt,
//         comeFrom: comeFrom,
//         dateOfBirth: dateOfBirth,
//         // Nếu có URL mới thì tạo list mới, nếu không giữ list cũ
//         avatar: avatarUrl != null && avatarUrl.isNotEmpty ? [avatarUrl] : user!.avatar,
//       );

//       await _userRequest.updateUser(updatedUser);
      
//       user = updatedUser;
      
//       print('✅ Cập nhật hồ sơ thành công');
//     } catch (e) {
//       print('❌ Lỗi khi cập nhật hồ sơ: $e');
//       rethrow;
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> updateNotificationSetting(String key, bool value) async {
//     if (user == null) return;

//     try {
//       final updatedSettings = Map<String, bool>.from(user!.notificationSettings);
//       updatedSettings[key] = value;

//       final updatedUser = _copyUserWith(notificationSettings: updatedSettings);

//       user = updatedUser;
//       notifyListeners();

//       await _userRequest.updateUser(updatedUser);
      
//       print('✅ Cập nhật cài đặt thông báo $key: $value');
//     } catch (e) {
//       print('❌ Lỗi khi cập nhật cài đặt thông báo: $e');
//       await loadProfile();
//     }
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/post_request.dart';

class ProfileViewModel extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _userRequest = UserRequest();
  final _postRequest = PostRequest();

  UserModel? user;
  bool isLoading = true;
  Stream<List<PostModel>>? userPostsStream;

  Future<void> loadProfile() async {
    try {
      isLoading = true;
      notifyListeners();

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userData = await _userRequest.getUserByUid(currentUser.uid);
      user = userData;

      if (user != null) {
        userPostsStream = _postRequest.getPostsByAuthorId(user!.id);
      }

    } catch (e) {
      print('❌ Lỗi khi tải thông tin cá nhân: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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

  // HÀM MỚI CHỈ ĐỂ CẬP NHẬT AVATAR
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

  // HÀM NÀY ĐÃ BỎ `avatarUrl`
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