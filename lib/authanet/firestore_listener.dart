import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_media.dart';

class FirestoreListener extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, UserModel> _usersByDocId = {};
  Map<String, UserModel> _usersByAuthUid = {};
  Map<String, GroupModel> _groupsByDocId = {};
  Map<String, MediaModel> _mediaByDocId = {};

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  FirestoreListener() {
    _startListening();
  }

  void _startListening() {
    // Lắng nghe User
    _firestore.collection('User').snapshots().listen((snapshot) {
      try {
        _usersByDocId = {};
        _usersByAuthUid = {};
        for (var doc in snapshot.docs) {
          final user = UserModel.fromFirestore(doc);
          _usersByDocId[doc.id] = user;
          if (user.uid.isNotEmpty) {
            _usersByAuthUid[user.uid] = user;
          }
        }
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Lỗi khi lắng nghe dữ liệu người dùng: $e';
        notifyListeners();
      }
    });

    // Lắng nghe Group
    _firestore.collection('Group').snapshots().listen((snapshot) {
      try {
        _groupsByDocId = {
          for (var doc in snapshot.docs) doc.id: GroupModel.fromMap(doc.id, doc.data())
        };
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Lỗi khi lắng nghe dữ liệu nhóm: $e';
        notifyListeners();
      }
    });

    // Lắng nghe Media
    _firestore.collection('Media').snapshots().listen((snapshot) {
      try {
        _mediaByDocId = {
          for (var doc in snapshot.docs) doc.id: MediaModel.fromFirestore(doc)
        };
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Lỗi khi lắng nghe dữ liệu media: $e';
        notifyListeners();
      }
    });
  }

  UserModel? getUserById(String docId) => _usersByDocId[docId];
  UserModel? getUserByAuthUid(String authUid) => _usersByAuthUid[authUid];
  GroupModel? getGroupById(String docId) => _groupsByDocId[docId];
  MediaModel? getMediaById(String docId) => _mediaByDocId[docId];

  // Hàm cập nhật local state cho BẠN BÈ (đã có)
  void updateLocalFriendship(String user1Id, String user2Id, bool areFriends) {
    if (_usersByDocId.containsKey(user1Id)) {
      final user1 = _usersByDocId[user1Id]!;
      if (areFriends) {
        if (!user1.friends.contains(user2Id)) {
          user1.friends.add(user2Id);
        }
      } else {
        user1.friends.remove(user2Id);
      }
    }
    if (_usersByDocId.containsKey(user2Id)) {
      final user2 = _usersByDocId[user2Id]!;
      if (areFriends) {
        if (!user2.friends.contains(user1Id)) {
          user2.friends.add(user1Id);
        }
      } else {
        user2.friends.remove(user1Id);
      }
    }
    notifyListeners();
  }

  // --- HÀM MỚI ĐỂ SỬA LỖI LOCKET ---
  // Hàm này cập nhật local state cho BẠN BÈ LOCKET
  void updateLocalLocketFriend(String currentUserId, String friendId, bool isLocketFriend) {
    if (_usersByDocId.containsKey(currentUserId)) {
      final user = _usersByDocId[currentUserId]!;
      if (isLocketFriend) {
        if (!user.locketFriends.contains(friendId)) {
          user.locketFriends.add(friendId);
        }
      } else {
        user.locketFriends.remove(friendId);
      }
      // Thông báo cho tất cả các widget đang watch (locket_view, locket_manage_friends_view)
      notifyListeners();
    }
  }
}