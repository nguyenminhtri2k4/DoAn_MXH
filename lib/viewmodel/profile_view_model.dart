
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

  Future<void> loadProfile({String? userId}) async {
    try {
      isLoading = true;
      friendshipStatus = 'loading';
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
            friendshipStatus = await _friendManager.getFriendshipStatus(currentUserData!.id, user!.id);
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
        userPostsStream = _postRequest.getPostsByAuthorId(
          user!.id,
          currentUserId: currentUserData?.id,
          friendIds: currentUserData?.friends ?? [],
        );
      }

    } catch (e) {
      print('❌ Lỗi khi tải thông tin cá nhân: $e');
      friendshipStatus = 'none';
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
  
  Future<void> blockUser() async {
    if (currentUserData == null || user == null) return;
    await _friendManager.blockUser(currentUserData!.id, user!.id);
    await loadProfile(userId: user!.id);
  }

  // <--- SỬA HÀM NÀY: Trả về Future<bool> --->
  Future<bool> pickAndUpdateAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return false;

    _setUpdatingImage(true);
    
    try {
      final File imageFile = File(image.path);
      final String? downloadUrl = await _storageRequest.uploadProfileImage(imageFile, user!.uid, 'user_avatars');
      
      if (downloadUrl != null) {
        user = user!.copyWith(avatar: [downloadUrl]); 
        await _userRequest.updateUser(user!);
        notifyListeners();
        return true; // <--- Báo thành công
      } else {
        return false; // <--- Báo thất bại
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật avatar: $e');
      return false; // <--- Báo thất bại
    } finally {
      _setUpdatingImage(false);
    }
  }

  // <--- SỬA HÀM NÀY: Trả về Future<bool> --->
  Future<bool> pickAndUpdateBackground() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return false;

    _setUpdatingImage(true);

    try {
      final File imageFile = File(image.path);
      final String? downloadUrl = await _storageRequest.uploadProfileImage(imageFile, user!.uid, 'user_backgrounds');
      
      if (downloadUrl != null) {
        user = user!.copyWith(backgroundImageUrl: downloadUrl);
        await _userRequest.updateUser(user!);
        notifyListeners();
        return true; // <--- Báo thành công
      } else {
        return false; // <--- Báo thất bại
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật ảnh nền: $e');
      return false; // <--- Báo thất bại
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
      final updatedSettings = Map<String, bool>.from(user!.notificationSettings);
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