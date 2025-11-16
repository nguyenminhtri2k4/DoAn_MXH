
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
import 'package:mangxahoi/request/group_request.dart';
import 'package:mangxahoi/model/model_group.dart';

class ProfileViewModel extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _userRequest = UserRequest();
  final _postRequest = PostRequest();
  final _friendManager = FriendRequestManager();
  final _groupRequest = GroupRequest();

  final ImagePicker _picker = ImagePicker();
  final StorageRequest _storageRequest = StorageRequest();

  bool _isUpdatingImage = false;
  bool get isUpdatingImage => _isUpdatingImage;
  bool _isDisposed = false;

  void _setUpdatingImage(bool value) {
    _isUpdatingImage = value;
    notifyListeners();
  }

  UserModel? user;
  UserModel? currentUserData;
  bool isLoading = true;
  bool isCurrentUserProfile = false;
  String friendshipStatus = 'loading';

  bool _isBlocked = false;
  bool get isBlocked => _isBlocked;

  bool _isBlockedByOther = false;
  bool get isBlockedByOther => _isBlockedByOther;

  // ✅ QUAN TRỌNG: Sử dụng StreamController để tạo broadcast streams
  final StreamController<List<PostModel>> _userPostsController = 
      StreamController<List<PostModel>>.broadcast();
  final StreamController<List<UserModel>> _friendsController = 
      StreamController<List<UserModel>>.broadcast();
  final StreamController<List<GroupModel>> _groupsController = 
      StreamController<List<GroupModel>>.broadcast();

  // ✅ Expose streams từ controllers
  Stream<List<PostModel>> get userPostsStream => _userPostsController.stream;
  Stream<List<UserModel>> get friendsStream => _friendsController.stream;
  Stream<List<GroupModel>> get groupsStream => _groupsController.stream;

  // Track subscriptions để cancel khi dispose hoặc reload
  StreamSubscription? _postsSubscription;
  StreamSubscription? _friendsSubscription;
  StreamSubscription? _groupsSubscription;

  @override
  void dispose() {
    print('🔧 [ProfileViewModel] Disposing...');
    _isDisposed = true;
    
    // Cancel all subscriptions
    _postsSubscription?.cancel();
    _friendsSubscription?.cancel();
    _groupsSubscription?.cancel();
    
    // Close all controllers
    _userPostsController.close();
    _friendsController.close();
    _groupsController.close();
    
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> loadProfile({String? userId}) async {
    if (_isDisposed) return;
    
    try {
      isLoading = true;
      friendshipStatus = 'loading';
      _isBlocked = false;
      _isBlockedByOther = false;
      notifyListeners();

      final currentUserAuth = _auth.currentUser;
      String? targetUserId = userId;

      // Chỉ lấy currentUserData 1 LẦN nếu nó chưa có
      if (currentUserData == null && currentUserAuth != null) {
        currentUserData = await _userRequest.getUserByUid(currentUserAuth.uid);
      }

      if (_isDisposed) return;

      if (targetUserId == null && currentUserData != null) {
        targetUserId = currentUserData!.id;
      }

      if (targetUserId != null) {
        user = await _userRequest.getUserData(targetUserId);

        if (_isDisposed) return;

        if (currentUserData != null && user != null) {
          isCurrentUserProfile = user!.uid == currentUserData!.uid;
          if (!isCurrentUserProfile) {
            friendshipStatus = await _friendManager.getFriendshipStatus(
              currentUserData!.id,
              user!.id,
            );

            if (_isDisposed) return;

            _isBlocked = await _friendManager.isUserBlocked(
              currentUserData!.id,
              user!.id,
            );

            if (_isDisposed) return;

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

      if (_isDisposed) return;

      if (user != null) {
        // ✅ Setup streams - cancel old subscriptions first
        _setupPostsStream();
        _setupFriendsStream();
        _setupGroupsStream();
      }
    } catch (e) {
      print('❌ Lỗi khi tải thông tin cá nhân: $e');
      friendshipStatus = 'none';
      _isBlocked = false;
      _isBlockedByOther = false;
    } finally {
      if (!_isDisposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // ✅ Setup posts stream
  void _setupPostsStream() {
    if (_isDisposed || user == null) return;
    
    // Cancel old subscription
    _postsSubscription?.cancel();
    
    _postsSubscription = _postRequest.getPostsByAuthorId(
      user!.id,
      currentUserId: currentUserData?.id,
      friendIds: currentUserData?.friends ?? [],
    ).listen(
      (posts) {
        if (!_isDisposed && !_userPostsController.isClosed) {
          _userPostsController.add(posts);
        }
      },
      onError: (error) {
        print('❌ [ProfileViewModel] Error in posts stream: $error');
        if (!_isDisposed && !_userPostsController.isClosed) {
          _userPostsController.addError(error);
        }
      },
    );
  }

  // ✅ Setup friends stream
  void _setupFriendsStream() {
    if (_isDisposed || user == null) return;
    
    // Cancel old subscription
    _friendsSubscription?.cancel();
    
    final friendIds = user!.friends.take(9).toList();
    
    if (friendIds.isEmpty) {
      if (!_isDisposed && !_friendsController.isClosed) {
        _friendsController.add([]);
      }
      return;
    }
    
    _friendsSubscription = _userRequest.getUsersByIdsStream(friendIds).listen(
      (friends) {
        if (!_isDisposed && !_friendsController.isClosed) {
          _friendsController.add(friends);
        }
      },
      onError: (error) {
        print('❌ [ProfileViewModel] Error in friends stream: $error');
        if (!_isDisposed && !_friendsController.isClosed) {
          _friendsController.addError(error);
        }
      },
    );
  }

  // ✅ Setup groups stream
  void _setupGroupsStream() {
    if (_isDisposed || user == null) return;
    
    // Cancel old subscription
    _groupsSubscription?.cancel();
    
    print('🔍 [ProfileVM] ========== DEBUG GROUPS ==========');
    print('🔍 [ProfileVM] User ID: ${user!.id}');
    print('🔍 [ProfileVM] User Name: ${user!.name}');
    print('🔍 [ProfileVM] User.groups field: ${user!.groups}');
    print('🔍 [ProfileVM] User.groups.length: ${user!.groups.length}');
    
    _groupsSubscription = _groupRequest
        .getGroupsByUserId(user!.id)
        .map((allGroups) {
          if (_isDisposed) return <GroupModel>[];
          
          print('📦 [ProfileVM] Stream emitted ${allGroups.length} groups');
          
          final postGroups = allGroups.where((g) => g.type == 'post').toList();
          print('📦 [ProfileVM] Filtered to ${postGroups.length} post groups');
          
          if (postGroups.isNotEmpty) {
            print('📦 [ProfileVM] Group names: ${postGroups.map((g) => g.name).toList()}');
          } else {
            print('⚠️ [ProfileVM] No post groups found');
          }
          
          return postGroups.take(3).toList();
        })
        .listen(
      (groups) {
        if (!_isDisposed && !_groupsController.isClosed) {
          _groupsController.add(groups);
        }
      },
      onError: (error) {
        print('❌ [ProfileVM] Stream error: $error');
        if (!_isDisposed && !_groupsController.isClosed) {
          _groupsController.addError(error);
        }
      },
    );
    
    print('🔍 [ProfileVM] ========== END DEBUG ==========');
  }

  Future<void> sendFriendRequest() async {
    if (currentUserData == null || user == null || _isDisposed) return;
    await _friendManager.sendRequest(currentUserData!.id, user!.id);
    if (!_isDisposed) {
      await loadProfile(userId: user!.id);
    }
  }

  Future<void> unfriend() async {
    if (currentUserData == null || user == null || _isDisposed) return;
    await _friendManager.unfriend(currentUserData!.id, user!.id);
    if (!_isDisposed) {
      await loadProfile(userId: user!.id);
    }
  }

  Future<void> blockUser() async {
    if (currentUserData == null || user == null || _isDisposed) return;

    try {
      await _friendManager.blockUser(currentUserData!.id, user!.id);
      if (!_isDisposed) {
        _isBlocked = true;
        await loadProfile(userId: user!.id);
        print('✅ Đã chặn người dùng thành công');
      }
    } catch (e) {
      print('❌ Lỗi khi chặn người dùng: $e');
      rethrow;
    }
  }

  Future<void> unblockUser() async {
    if (currentUserData == null || user == null || _isDisposed) return;

    try {
      await _friendManager.unblockUser(currentUserData!.id, user!.id);
      if (!_isDisposed) {
        _isBlocked = false;
        await loadProfile(userId: user!.id);
        print('✅ Đã hủy chặn người dùng thành công');
      }
    } catch (e) {
      print('❌ Lỗi khi hủy chặn người dùng: $e');
      rethrow;
    }
  }

  Future<bool> pickAndUpdateAvatar() async {
    if (_isDisposed) return false;
    
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null || _isDisposed) return false;

    _setUpdatingImage(true);

    try {
      final File imageFile = File(image.path);
      final String? downloadUrl = await _storageRequest.uploadProfileImage(
        imageFile,
        user!.uid,
        'user_avatars',
      );

      if (_isDisposed) return false;

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
      if (!_isDisposed) {
        _setUpdatingImage(false);
      }
    }
  }

  Future<bool> pickAndUpdateBackground() async {
    if (_isDisposed) return false;
    
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null || _isDisposed) return false;

    _setUpdatingImage(true);

    try {
      final File imageFile = File(image.path);
      final String? downloadUrl = await _storageRequest.uploadProfileImage(
        imageFile,
        user!.uid,
        'user_backgrounds',
      );

      if (_isDisposed) return false;

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
      if (!_isDisposed) {
        _setUpdatingImage(false);
      }
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
    if (user == null || _isDisposed) return;

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
      
      if (_isDisposed) return;
      
      user = updatedUser;

      print('✅ Cập nhật hồ sơ thành công');
    } catch (e) {
      print('❌ Lỗi khi cập nhật hồ sơ: $e');
      rethrow;
    } finally {
      if (!_isDisposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> updateNotificationSetting(String key, bool value) async {
    if (user == null || _isDisposed) return;
    
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
      if (!_isDisposed) {
        await loadProfile();
      }
    }
  }
}