// lib/viewmodel/blocked_list_view_model.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/request/friend_request_manager.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/model/model_user.dart';

class BlockedListViewModel extends ChangeNotifier {
  final FriendRequestManager _friendManager = FriendRequestManager();
  final UserRequest _userRequest = UserRequest();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentUserDocId;
  bool _isLoading = true;
  Stream<List<String>>? _blockedUsersStream;

  bool get isLoading => _isLoading;
  Stream<List<String>>? get blockedUsersStream => _blockedUsersStream;

  BlockedListViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final UserModel? currentUser = await _userRequest.getUserByUid(firebaseUser.uid);
      if (currentUser != null) {
        _currentUserDocId = currentUser.id;
        _blockedUsersStream = _friendManager.getBlockedUsers(_currentUserDocId!);
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> unblockUser(String blockedUserId) async {
    if (_currentUserDocId == null) return;
    try {
      await _friendManager.unblockUser(_currentUserDocId!, blockedUserId);
      // StreamBuilder sẽ tự động cập nhật UI
    } catch (e) {
      print("Lỗi khi bỏ chặn: $e");
    }
  }
}