import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/request/friend_request_manager.dart';
import 'package:mangxahoi/request/storage_request.dart';

class ProfileViewModel extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _userRequest = UserRequest();
  final _postRequest = PostRequest();
  final _friendManager = FriendRequestManager();

  final ImagePicker _picker = ImagePicker();
  final StorageRequest _storageRequest = StorageRequest();

  bool _isUpdatingImage = false;
  bool get isUpdatingImage => _isUpdatingImage;

  void _setUpdatingImage(bool value) {
    _isUpdatingImage = value;
    notifyListeners();
  }

  UserModel? user;
  UserModel? currentUserData;
  bool isLoading = true;
  Stream<List<PostModel>>? userPostsStream;
  bool isCurrentUserProfile = false;
  String friendshipStatus = 'loading';

  // Thêm biến theo dõi trạng thái chặn
  bool _isBlocked = false;
  bool get isBlocked => _isBlocked;

  // Thêm biến theo dõi trạng thái bị chặn
  bool _isBlockedByOther = false;
  bool get isBlockedByOther => _isBlockedByOther;

  Future<void> loadProfile({String? userId}) async {
    try {
      isLoading = true;
      friendshipStatus = 'loading';
      _isBlocked = false; // Reset trạng thái chặn
      _isBlockedByOther = false; // Reset trạng thái bị chặn
      notifyListeners();

      final currentUserAuth = _auth.currentUser;
      String? targetUserId = userId;

      if (currentUserAuth != null) {
        currentUserData = await _userRequest.getUserByUid(currentUserAuth.uid);
      }

      if (targetUserId == null && currentUserData != null) {
        targetUserId = currentUserData!.id;
      }

      if (targetUserId != null) {
        user = await _userRequest.getUserData(targetUserId);

        if (currentUserData != null && user != null) {
          isCurrentUserProfile = user!.uid == currentUserData!.uid;
          if (!isCurrentUserProfile) {
            friendshipStatus = await _friendManager.getFriendshipStatus(
              currentUserData!.id,
              user!.id,
            );

            // Kiểm tra trạng thái chặn (mình chặn người khác)
            _isBlocked = await _friendManager.isUserBlocked(
              currentUserData!.id,
              user!.id,
            );

            // Kiểm tra trạng thái bị chặn (người khác chặn mình)
            _isBlockedByOther = await _friendManager.isUserBlocked(
              user!.id,
              currentUserData!.id,
            );
          } else {
            friendshipStatus = 'self';
            _isBlocked = false;
            _isBlockedByOther = false;
          }
        } else {
          isCurrentUserProfile = false;
          friendshipStatus = 'none';
          _isBlocked = false;
          _isBlockedByOther = false;
        }
      } else {
        user = null;
        isCurrentUserProfile = false;
        friendshipStatus = 'none';
        _isBlocked = false;
        _isBlockedByOther = false;
      }

      if (user != null) {
        userPostsStream = _postRequest.getPostsByAuthorId(
          user!.id,
          currentUserId: currentUserData?.id,
          friendIds: currentUserData?.friends ?? [],
        );
      }
    } catch (e) {
      print('❌ Lỗi khi tải thông tin cá nhân: $e');
      friendshipStatus = 'none';
      _isBlocked = false;
      _isBlockedByOther = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendFriendRequest() async {
    if (currentUserData == null || user == null) return;
    await _friendManager.sendRequest(currentUserData!.id, user!.id);
    await loadProfile(userId: user!.id);
  }

  Future<void> unfriend() async {
    if (currentUserData == null || user == null) return;
    await _friendManager.unfriend(currentUserData!.id, user!.id);
    await loadProfile(userId: user!.id);
  }

  // Cập nhật method blockUser
  Future<void> blockUser() async {
    if (currentUserData == null || user == null) return;

    try {
      await _friendManager.blockUser(currentUserData!.id, user!.id);
      _isBlocked = true;
      notifyListeners();
      print('✅ Đã chặn người dùng thành công');
    } catch (e) {
      print('❌ Lỗi khi chặn người dùng: $e');
      rethrow;
    }
  }

  // Thêm method unblockUser mới
  Future<void> unblockUser() async {
    if (currentUserData == null || user == null) return;

    try {
      await _friendManager.unblockUser(currentUserData!.id, user!.id);
      _isBlocked = false;
      notifyListeners();
      print('✅ Đã hủy chặn người dùng thành công');
    } catch (e) {
      print('❌ Lỗi khi hủy chặn người dùng: $e');
      rethrow;
    }
  }

  Future<bool> pickAndUpdateAvatar() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return false;

    _setUpdatingImage(true);

    try {
      final File imageFile = File(image.path);
      final String? downloadUrl = await _storageRequest.uploadProfileImage(
        imageFile,
        user!.uid,
        'user_avatars',
      );

      if (downloadUrl != null) {
        user = user!.copyWith(avatar: [downloadUrl]);
        await _userRequest.updateUser(user!);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật avatar: $e');
      return false;
    } finally {
      _setUpdatingImage(false);
    }
  }

  Future<bool> pickAndUpdateBackground() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return false;

    _setUpdatingImage(true);

    try {
      final File imageFile = File(image.path);
      final String? downloadUrl = await _storageRequest.uploadProfileImage(
        imageFile,
        user!.uid,
        'user_backgrounds',
      );

      if (downloadUrl != null) {
        user = user!.copyWith(backgroundImageUrl: downloadUrl);
        await _userRequest.updateUser(user!);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật ảnh nền: $e');
      return false;
    } finally {
      _setUpdatingImage(false);
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

      final updatedUser = user!.copyWith(
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
      final updatedSettings = Map<String, bool>.from(
        user!.notificationSettings,
      );
      updatedSettings[key] = value;

      final updatedUser = user!.copyWith(notificationSettings: updatedSettings);

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
