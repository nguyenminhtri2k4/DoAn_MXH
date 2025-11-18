import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/request/user_request.dart';

class TrashViewModel extends ChangeNotifier {
  final PostRequest _postRequest = PostRequest();
  final UserRequest _userRequest = UserRequest();
  final _auth = FirebaseAuth.instance;

  Stream<List<PostModel>>? _deletedPostsStream;
  Stream<List<PostModel>>? get deletedPostsStream => _deletedPostsStream;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  String? _currentUserId;

  TrashViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final user = await _userRequest.getUserByUid(firebaseUser.uid);
      if (user != null) {
        _currentUserId = user.id;
        _deletedPostsStream = _postRequest.getDeletedPosts(_currentUserId!);
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> restorePost(String postId) async {
    try {
      await _postRequest.restorePost(postId);
    } catch (e) {
      print("Lỗi khi khôi phục bài viết: $e");
    }
  }

  Future<void> deletePostPermanently(String postId) async {
    try {
      await _postRequest.deletePostPermanently(postId);
    } catch (e) {
      print("Lỗi khi xóa vĩnh viễn bài viết: $e");
    }
  }
}