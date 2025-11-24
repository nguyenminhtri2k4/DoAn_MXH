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
import 'package:rxdart/rxdart.dart';

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
    if (_isDisposed) return;
    _isUpdatingImage = value;
    _safeNotifyListeners();
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

  String? _currentStreamUserId;
  StreamSubscription<UserModel?>? _userSubscription;
  StreamSubscription<List<UserModel>>? _friendsSubscription;

  final BehaviorSubject<List<PostModel>> _userPostsSubject =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<List<UserModel>> _friendsSubject =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<List<GroupModel>> _groupsSubject =
      BehaviorSubject.seeded([]);

  Stream<List<PostModel>> get userPostsStream => _userPostsSubject.stream;
  Stream<List<UserModel>> get friendsStream => _friendsSubject.stream;
  Stream<List<GroupModel>> get groupsStream => _groupsSubject.stream;

  int _streamsVersion = 0;
  int get streamsVersion => _streamsVersion;

  Timer? _loadProfileTimer;

  @override
  void dispose() {
    print('[ProfileVM] Disposing...');
    _isDisposed = true;
    _loadProfileTimer?.cancel();
    _userSubscription?.cancel();
    _friendsSubscription?.cancel();
    _userPostsSubject.close();
    _friendsSubject.close();
    _groupsSubject.close();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      try {
        notifyListeners();
      } catch (e) {
        print('[ProfileVM] Error notifying: $e');
      }
    }
  }

  Future<void> loadProfile({String? userId}) async {
    if (_isDisposed) return;

    _loadProfileTimer?.cancel();
    final completer = Completer<void>();
    _loadProfileTimer = Timer(const Duration(milliseconds: 300), () async {
      await _loadProfileInternal(userId: userId);
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<void> _loadProfileInternal({String? userId}) async {
    if (_isDisposed) return;

    try {
      isLoading = true;
      friendshipStatus = 'loading';
      _isBlocked = false;
      _isBlockedByOther = false;

      final currentUserAuth = _auth.currentUser;
      String? targetUserId = userId;

      // LẤY CURRENT USER
      if (currentUserData == null && currentUserAuth != null) {
        currentUserData = await _userRequest.getUserByUid(currentUserAuth.uid);
      }
      if (_isDisposed) return;

      if (targetUserId == null && currentUserData != null) {
        targetUserId = currentUserData!.id;
      }

      _safeNotifyListeners();

      if (targetUserId != null) {
        // HỦY LẮNG NGHE CŨ
        await _userSubscription?.cancel();
        await _friendsSubscription?.cancel();

        // LẮNG NGHE USER REAL-TIME
        _userSubscription = _userRequest
            .getUserDataStream(targetUserId)
            .listen(
              (updatedUser) async {
                if (_isDisposed || updatedUser == null) return;

                user = updatedUser;

                // CẬP NHẬT TRẠNG THÁI
                if (currentUserData != null && user != null) {
                  isCurrentUserProfile = user!.uid == currentUserData!.uid;

                  if (!isCurrentUserProfile) {
                    friendshipStatus = await _friendManager.getFriendshipStatus(
                      currentUserData!.id,
                      user!.id,
                    );
                    _isBlocked = await _friendManager.isUserBlocked(
                      currentUserData!.id,
                      user!.id,
                    );
                    _isBlockedByOther = await _friendManager.isUserBlocked(
                      user!.id,
                      currentUserData!.id,
                    );
                  } else {
                    friendshipStatus = 'self';
                    _isBlocked = false;
                    _isBlockedByOther = false;
                  }
                }

                // CẬP NHẬT BÀI VIẾT, BẠN BÈ, NHÓM
                if (user != null && !isBlocked && !isBlockedByOther) {
                  _setupStreams();
                } else {
                  _groupsSubject.add([]);
                  _friendsSubject.add([]);
                }

                isLoading = false;
                _safeNotifyListeners();
              },
              onError: (e) {
                print('[ProfileVM] User stream error: $e');
                friendshipStatus = 'none';
                isLoading = false;
                _safeNotifyListeners();
              },
            );
      } else {
        user = null;
        isCurrentUserProfile = false;
        friendshipStatus = 'none';
        _isBlocked = false;
        _isBlockedByOther = false;
        isLoading = false;
        _safeNotifyListeners();
      }
    } catch (e) {
      print('[ProfileVM] Load error: $e');
      friendshipStatus = 'none';
      isLoading = false;
      _safeNotifyListeners();
    }
  }

  void _setupStreams() {
    if (_isDisposed || user == null) return;

    print('[ProfileVM] Setting up streams for: ${user!.id}');
    _currentStreamUserId = user!.id;

    // === BÀI VIẾT (real-time) ===
    _postRequest
        .getPostsByAuthorId(
          user!.id,
          currentUserId: currentUserData?.id,
          friendIds: currentUserData?.friends ?? [],
        )
        .listen((posts) {
          _userPostsSubject.add(posts);
        });

    // === BẠN BÈ (real-time) ===
    if (user!.friends.isEmpty) {
      _friendsSubject.add([]);
    } else {
      final friendIds = user!.friends.take(9).toList();
      _friendsSubscription?.cancel();
      _friendsSubscription = _userRequest
          .getUsersByIdsStream(friendIds)
          .listen(
            (friends) {
              _friendsSubject.add(friends);
            },
            onError: (e) {
              print('[ProfileVM] Friends stream error: $e');
              _friendsSubject.add([]);
            },
          );
    }
    // === NHÓM (real-time stream) ===
    if (user!.groups.isEmpty) {
      _groupsSubject.add([]);
    } else {
      // ✅ DÙNG STREAM real-time
      _groupRequest
          .getGroupsByUserId(user!.id)
          .map((allGroups) => allGroups.where((g) => g.type == 'post').toList())
          .listen(
            (postGroups) {
              _groupsSubject.add(postGroups);
            },
            onError: (e) {
              print('[ProfileVM] Groups stream error: $e');
              _groupsSubject.add([]);
            },
          );
    }

    _streamsVersion++;
    _safeNotifyListeners();
  }

  Future<List<GroupModel>> _loadGroupsOnce(List<String> groupIds) async {
    try {
      final List<GroupModel> postGroups = [];
      for (final groupId in groupIds) {
        final group = await _groupRequest.getGroupById(groupId);
        if (group != null && group.type == 'post') {
          postGroups.add(group);
        }
      }
      return postGroups;
    } catch (e) {
      print('[ProfileVM] _loadGroupsOnce error: $e');
      return [];
    }
  }

  // ==================== FRIEND ACTIONS ====================
  Future<void> sendFriendRequest() async => await _friendAction(
    () => _friendManager.sendRequest(currentUserData!.id, user!.id),
  );
  Future<void> unfriend() async => await _friendAction(
    () => _friendManager.unfriend(currentUserData!.id, user!.id),
  );
  Future<void> blockUser() async => await _friendAction(() async {
    await _friendManager.blockUser(currentUserData!.id, user!.id);
    _isBlocked = true;
  });
  Future<void> unblockUser() async => await _friendAction(() async {
    await _friendManager.unblockUser(currentUserData!.id, user!.id);
    _isBlocked = false;
  });

  Future<void> _friendAction(Future<void> Function() action) async {
    if (currentUserData == null || user == null || _isDisposed) return;
    try {
      await action();
      if (!_isDisposed) await loadProfile(userId: user!.id);
    } catch (e) {
      print('[ProfileVM] Friend action error: $e');
      rethrow;
    }
  }

  // ==================== IMAGE UPDATES ====================
  Future<bool> pickAndUpdateAvatar() async => await _updateImage(
    'user_avatars',
    (url) => user!.copyWith(avatar: [url]),
  );
  Future<bool> pickAndUpdateBackground() async => await _updateImage(
    'user_backgrounds',
    (url) => user!.copyWith(backgroundImageUrl: url),
  );

  Future<bool> _updateImage(
    String folder,
    UserModel Function(String) updater,
  ) async {
    if (_isDisposed) return false;
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null || _isDisposed) return false;

    _setUpdatingImage(true);
    try {
      final file = File(image.path);
      final url = await _storageRequest.uploadProfileImage(
        file,
        user!.uid,
        folder,
      );
      if (url == null || _isDisposed) return false;

      user = updater(url);
      await _userRequest.updateUser(user!);
      _safeNotifyListeners();
      return true;
    } catch (e) {
      print('[ProfileVM] Image update error: $e');
      return false;
    } finally {
      if (!_isDisposed) _setUpdatingImage(false);
    }
  }

  // ==================== PROFILE UPDATE ====================
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
      _safeNotifyListeners();

      final updated = user!.copyWith(
        name: name,
        bio: bio,
        phone: phone,
        gender: gender,
        relationship: relationship,
        liveAt: liveAt,
        comeFrom: comeFrom,
        dateOfBirth: dateOfBirth,
      );
      await _userRequest.updateUser(updated);
      user = updated;
    } catch (e) {
      print('[ProfileVM] Update error: $e');
      rethrow;
    } finally {
      if (!_isDisposed) {
        isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> updateNotificationSetting(String key, bool value) async {
    if (user == null || _isDisposed) return;
    try {
      final settings = Map<String, bool>.from(user!.notificationSettings)
        ..[key] = value;
      user = user!.copyWith(notificationSettings: settings);
      _safeNotifyListeners();
      await _userRequest.updateUser(user!);
    } catch (e) {
      print('[ProfileVM] Notification error: $e');
      if (!_isDisposed) await loadProfile();
    }
  }
}
