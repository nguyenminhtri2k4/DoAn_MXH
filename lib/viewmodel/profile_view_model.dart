
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mangxahoi/model/model_user.dart';
// import 'package:mangxahoi/model/model_post.dart';
// import 'package:mangxahoi/request/user_request.dart';
// import 'package:mangxahoi/request/post_request.dart';
// import 'package:mangxahoi/request/friend_request_manager.dart';
// import 'package:mangxahoi/request/storage_request.dart';
// import 'package:mangxahoi/request/group_request.dart';
// import 'package:mangxahoi/model/model_group.dart';

// class ProfileViewModel extends ChangeNotifier {
//   final _auth = FirebaseAuth.instance;
//   final _userRequest = UserRequest();
//   final _postRequest = PostRequest();
//   final _friendManager = FriendRequestManager();
//   final _groupRequest = GroupRequest();

//   final ImagePicker _picker = ImagePicker();
//   final StorageRequest _storageRequest = StorageRequest();

//   bool _isUpdatingImage = false;
//   bool get isUpdatingImage => _isUpdatingImage;
//   bool _isDisposed = false;

//   void _setUpdatingImage(bool value) {
//     _isUpdatingImage = value;
//     notifyListeners();
//   }

//   UserModel? user;
//   UserModel? currentUserData;
//   bool isLoading = true;
//   bool isCurrentUserProfile = false;
//   String friendshipStatus = 'loading';

//   bool _isBlocked = false;
//   bool get isBlocked => _isBlocked;

//   bool _isBlockedByOther = false;
//   bool get isBlockedByOther => _isBlockedByOther;

//   // ✅ CÁCH MỚI: Dùng nullable streams như GroupsViewModel
//   Stream<List<PostModel>>? _userPostsStream;
//   Stream<List<UserModel>>? _friendsStream;
//   Stream<List<GroupModel>>? _groupsStream;

//   // ✅ Expose streams với broadcast
//   Stream<List<PostModel>>? get userPostsStream => 
//       _userPostsStream?.asBroadcastStream();
//   Stream<List<UserModel>>? get friendsStream => 
//       _friendsStream?.asBroadcastStream();
//   Stream<List<GroupModel>>? get groupsStream => 
//       _groupsStream?.asBroadcastStream();

//   @override
//   void dispose() {
//     print('🔧 [ProfileViewModel] Disposing...');
//     _isDisposed = true;
//     super.dispose();
//   }

//   @override
//   void notifyListeners() {
//     if (!_isDisposed) {
//       super.notifyListeners();
//     }
//   }

//   Future<void> loadProfile({String? userId}) async {
//     if (_isDisposed) return;
    
//     try {
//       isLoading = true;
//       friendshipStatus = 'loading';
//       _isBlocked = false;
//       _isBlockedByOther = false;
      
//       // ✅ Reset streams về null để force rebuild
//       _userPostsStream = null;
//       _friendsStream = null;
//       _groupsStream = null;
      
//       notifyListeners();

//       final currentUserAuth = _auth.currentUser;
//       String? targetUserId = userId;

//       if (currentUserData == null && currentUserAuth != null) {
//         currentUserData = await _userRequest.getUserByUid(currentUserAuth.uid);
//       }

//       if (_isDisposed) return;

//       if (targetUserId == null && currentUserData != null) {
//         targetUserId = currentUserData!.id;
//       }

//       if (targetUserId != null) {
//         user = await _userRequest.getUserData(targetUserId);

//         if (_isDisposed) return;

//         if (currentUserData != null && user != null) {
//           isCurrentUserProfile = user!.uid == currentUserData!.uid;
//           if (!isCurrentUserProfile) {
//             friendshipStatus = await _friendManager.getFriendshipStatus(
//               currentUserData!.id,
//               user!.id,
//             );

//             if (_isDisposed) return;

//             _isBlocked = await _friendManager.isUserBlocked(
//               currentUserData!.id,
//               user!.id,
//             );

//             if (_isDisposed) return;

//             _isBlockedByOther = await _friendManager.isUserBlocked(
//               user!.id,
//               currentUserData!.id,
//             );
//           } else {
//             friendshipStatus = 'self';
//             _isBlocked = false;
//             _isBlockedByOther = false;
//           }
//         } else {
//           isCurrentUserProfile = false;
//           friendshipStatus = 'none';
//           _isBlocked = false;
//           _isBlockedByOther = false;
//         }
//       } else {
//         user = null;
//         isCurrentUserProfile = false;
//         friendshipStatus = 'none';
//         _isBlocked = false;
//         _isBlockedByOther = false;
//       }

//       if (_isDisposed) return;

//       if (user != null && !isBlocked && !isBlockedByOther) {
//         // ✅ Setup streams trực tiếp (như GroupsViewModel)
//         _setupStreams();
//       }
//     } catch (e) {
//       print('❌ Lỗi khi tải thông tin cá nhân: $e');
//       friendshipStatus = 'none';
//       _isBlocked = false;
//       _isBlockedByOther = false;
//     } finally {
//       if (!_isDisposed) {
//         isLoading = false;
//         notifyListeners();
//       }
//     }
//   }

//   // ✅ Setup tất cả streams một lúc
//   void _setupStreams() {
//     if (_isDisposed || user == null) return;
    
//     print('🔧 [ProfileVM] Setting up streams for user: ${user!.id}');
    
//     // 1. Posts stream
//     _userPostsStream = _postRequest.getPostsByAuthorId(
//       user!.id,
//       currentUserId: currentUserData?.id,
//       friendIds: currentUserData?.friends ?? [],
//     );
//     print('✅ [ProfileVM] Posts stream initialized');
    
//     // 2. Friends stream
//     final friendIds = user!.friends.take(9).toList();
//     if (friendIds.isNotEmpty) {
//       _friendsStream = _userRequest.getUsersByIdsStream(friendIds);
//       print('✅ [ProfileVM] Friends stream initialized for ${friendIds.length} friends');
//     } else {
//       _friendsStream = Stream.value([]);
//       print('✅ [ProfileVM] No friends - empty stream');
//     }
    
//     // 3. Groups stream
//     print('🔍 [ProfileVM] ========== DEBUG GROUPS ==========');
//     print('🔍 [ProfileVM] User ID: ${user!.id}');
//     print('🔍 [ProfileVM] User Name: ${user!.name}');
//     print('🔍 [ProfileVM] User.groups field: ${user!.groups}');
//     print('🔍 [ProfileVM] User.groups.length: ${user!.groups.length}');
    
//     _groupsStream = _groupRequest
//         .getGroupsByUserId(user!.id)
//         .map((allGroups) {
//           print('📦 [ProfileVM] Raw stream emitted ${allGroups.length} groups');
          
//           final postGroups = allGroups.where((g) => g.type == 'post').toList();
//           print('📦 [ProfileVM] Filtered to ${postGroups.length} post groups');
          
//           if (postGroups.isNotEmpty) {
//             print('📦 [ProfileVM] Group names: ${postGroups.map((g) => g.name).join(", ")}');
//             print('📦 [ProfileVM] Group IDs: ${postGroups.map((g) => g.id).join(", ")}');
//           } else {
//             print('⚠️ [ProfileVM] No post groups found after filter');
//             print('⚠️ [ProfileVM] All group types: ${allGroups.map((g) => "${g.name} (${g.type})").join(", ")}');
//           }
          
//           return postGroups.take(3).toList();
//         })
//         .handleError((error) {
//           print('❌ [ProfileVM] Groups stream error: $error');
//           return <GroupModel>[];
//         });
    
//     print('✅ [ProfileVM] Groups stream initialized');
//     print('🔍 [ProfileVM] ========== END DEBUG ==========');
    
//     // ✅ QUAN TRỌNG: Trigger rebuild để StreamBuilder nhận streams mới
//     notifyListeners();
//   }

//   Future<void> sendFriendRequest() async {
//     if (currentUserData == null || user == null || _isDisposed) return;
//     await _friendManager.sendRequest(currentUserData!.id, user!.id);
//     if (!_isDisposed) {
//       await loadProfile(userId: user!.id);
//     }
//   }

//   Future<void> unfriend() async {
//     if (currentUserData == null || user == null || _isDisposed) return;
//     await _friendManager.unfriend(currentUserData!.id, user!.id);
//     if (!_isDisposed) {
//       await loadProfile(userId: user!.id);
//     }
//   }

//   Future<void> blockUser() async {
//     if (currentUserData == null || user == null || _isDisposed) return;

//     try {
//       await _friendManager.blockUser(currentUserData!.id, user!.id);
//       if (!_isDisposed) {
//         _isBlocked = true;
//         await loadProfile(userId: user!.id);
//         print('✅ Đã chặn người dùng thành công');
//       }
//     } catch (e) {
//       print('❌ Lỗi khi chặn người dùng: $e');
//       rethrow;
//     }
//   }

//   Future<void> unblockUser() async {
//     if (currentUserData == null || user == null || _isDisposed) return;

//     try {
//       await _friendManager.unblockUser(currentUserData!.id, user!.id);
//       if (!_isDisposed) {
//         _isBlocked = false;
//         await loadProfile(userId: user!.id);
//         print('✅ Đã hủy chặn người dùng thành công');
//       }
//     } catch (e) {
//       print('❌ Lỗi khi hủy chặn người dùng: $e');
//       rethrow;
//     }
//   }

//   Future<bool> pickAndUpdateAvatar() async {
//     if (_isDisposed) return false;
    
//     final XFile? image = await _picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 80,
//     );
//     if (image == null || _isDisposed) return false;

//     _setUpdatingImage(true);

//     try {
//       final File imageFile = File(image.path);
//       final String? downloadUrl = await _storageRequest.uploadProfileImage(
//         imageFile,
//         user!.uid,
//         'user_avatars',
//       );

//       if (_isDisposed) return false;

//       if (downloadUrl != null) {
//         user = user!.copyWith(avatar: [downloadUrl]);
//         await _userRequest.updateUser(user!);
//         notifyListeners();
//         return true;
//       } else {
//         return false;
//       }
//     } catch (e) {
//       print('❌ Lỗi khi cập nhật avatar: $e');
//       return false;
//     } finally {
//       if (!_isDisposed) {
//         _setUpdatingImage(false);
//       }
//     }
//   }

//   Future<bool> pickAndUpdateBackground() async {
//     if (_isDisposed) return false;
    
//     final XFile? image = await _picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 80,
//     );
//     if (image == null || _isDisposed) return false;

//     _setUpdatingImage(true);

//     try {
//       final File imageFile = File(image.path);
//       final String? downloadUrl = await _storageRequest.uploadProfileImage(
//         imageFile,
//         user!.uid,
//         'user_backgrounds',
//       );

//       if (_isDisposed) return false;

//       if (downloadUrl != null) {
//         user = user!.copyWith(backgroundImageUrl: downloadUrl);
//         await _userRequest.updateUser(user!);
//         notifyListeners();
//         return true;
//       } else {
//         return false;
//       }
//     } catch (e) {
//       print('❌ Lỗi khi cập nhật ảnh nền: $e');
//       return false;
//     } finally {
//       if (!_isDisposed) {
//         _setUpdatingImage(false);
//       }
//     }
//   }

//   Future<void> updateProfile({
//     String? name,
//     String? bio,
//     String? phone,
//     String? gender,
//     String? relationship,
//     String? liveAt,
//     String? comeFrom,
//     DateTime? dateOfBirth,
//   }) async {
//     if (user == null || _isDisposed) return;

//     try {
//       isLoading = true;
//       notifyListeners();

//       final updatedUser = user!.copyWith(
//         name: name,
//         bio: bio,
//         phone: phone,
//         gender: gender,
//         relationship: relationship,
//         liveAt: liveAt,
//         comeFrom: comeFrom,
//         dateOfBirth: dateOfBirth,
//       );

//       await _userRequest.updateUser(updatedUser);
      
//       if (_isDisposed) return;
      
//       user = updatedUser;

//       print('✅ Cập nhật hồ sơ thành công');
//     } catch (e) {
//       print('❌ Lỗi khi cập nhật hồ sơ: $e');
//       rethrow;
//     } finally {
//       if (!_isDisposed) {
//         isLoading = false;
//         notifyListeners();
//       }
//     }
//   }

//   Future<void> updateNotificationSetting(String key, bool value) async {
//     if (user == null || _isDisposed) return;
    
//     try {
//       final updatedSettings = Map<String, bool>.from(
//         user!.notificationSettings,
//       );
//       updatedSettings[key] = value;

//       final updatedUser = user!.copyWith(notificationSettings: updatedSettings);

//       user = updatedUser;
//       notifyListeners();
//       await _userRequest.updateUser(updatedUser);
//       print('✅ Cập nhật cài đặt thông báo $key: $value');
//     } catch (e) {
//       print('❌ Lỗi khi cập nhật cài đặt thông báo: $e');
//       if (!_isDisposed) {
//         await loadProfile();
//       }
//     }
//   }
// }
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

  // ✅ Streams
  Stream<List<PostModel>>? _userPostsStream;
  Stream<List<UserModel>>? _friendsStream;
  Stream<List<GroupModel>>? _groupsStream;

  Stream<List<PostModel>>? get userPostsStream => 
      _userPostsStream?.asBroadcastStream();
  Stream<List<UserModel>>? get friendsStream => 
      _friendsStream?.asBroadcastStream();
  Stream<List<GroupModel>>? get groupsStream => 
      _groupsStream?.asBroadcastStream();

  @override
  void dispose() {
    print('🔧 [ProfileViewModel] Disposing...');
    _isDisposed = true;
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
      
      // Reset streams
      _userPostsStream = null;
      _friendsStream = null;
      _groupsStream = null;
      
      notifyListeners();

      final currentUserAuth = _auth.currentUser;
      String? targetUserId = userId;

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

      if (user != null && !isBlocked && !isBlockedByOther) {
        _setupStreams();
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

  // ✅ FIX: Setup streams với switchMap để tự động cập nhật
  void _setupStreams() {
    if (_isDisposed || user == null) return;
    
    print('🔧 [ProfileVM] Setting up streams for user: ${user!.id}');
    
    // 1. Posts stream - KHÔNG ĐỔI
    _userPostsStream = _postRequest.getPostsByAuthorId(
      user!.id,
      currentUserId: currentUserData?.id,
      friendIds: currentUserData?.friends ?? [],
    );
    print('✅ [ProfileVM] Posts stream initialized');
    
    // 2. ✅ FIX: Friends stream - Dùng Stream liên tục từ user document
    if (user!.friends.isNotEmpty) {
      // Lấy stream của user để cập nhật realtime khi friends list thay đổi
      _friendsStream = _userRequest
          .getUserDataStream(user!.id) // Stream theo dõi user document
          .asyncMap((updatedUser) async {
            if (updatedUser == null || updatedUser.friends.isEmpty) {
              return <UserModel>[];
            }
            // Lấy tối đa 9 bạn bè để hiển thị
            final friendIds = updatedUser.friends.take(9).toList();
            final friends = await _userRequest.getUsersByIds(friendIds);
            print('✅ [ProfileVM] Loaded ${friends.length} friends');
            return friends;
          })
          .handleError((error) {
            print('❌ [ProfileVM] Friends stream error: $error');
            return <UserModel>[];
          });
      print('✅ [ProfileVM] Friends stream initialized for ${user!.friends.length} friends');
    } else {
      _friendsStream = Stream.value([]);
      print('✅ [ProfileVM] No friends - empty stream');
    }
    
    // 3. ✅ FIX: Groups stream - Dùng stream liên tục
    print('🔍 [ProfileVM] ========== DEBUG GROUPS ==========');
    print('🔍 [ProfileVM] User ID: ${user!.id}');
    print('🔍 [ProfileVM] User.groups field: ${user!.groups}');
    print('🔍 [ProfileVM] User.groups.length: ${user!.groups.length}');
    
    _groupsStream = _groupRequest
        .getGroupsByUserId(user!.id)
        .map((allGroups) {
          print('📦 [ProfileVM] Stream emitted ${allGroups.length} groups');
          
          final postGroups = allGroups.where((g) => g.type == 'post').toList();
          print('📦 [ProfileVM] Filtered to ${postGroups.length} post groups');
          
          if (postGroups.isNotEmpty) {
            print('📦 [ProfileVM] First 3 groups: ${postGroups.take(3).map((g) => g.name).join(", ")}');
          }
          
          return postGroups.take(3).toList();
        })
        .handleError((error) {
          print('❌ [ProfileVM] Groups stream error: $error');
          return <GroupModel>[];
        });
    
    print('✅ [ProfileVM] Groups stream initialized');
    print('🔍 [ProfileVM] ========== END DEBUG ==========');
    
    notifyListeners();
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