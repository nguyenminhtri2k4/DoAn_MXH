import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/post_request.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRequest _userRequest = UserRequest();
  final PostRequest _postRequest = PostRequest();

  UserModel? currentUserData;
  Stream<List<PostModel>>? postsStream;
  bool isLoading = true;

  HomeViewModel() {
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        currentUserData = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      final user = await _userRequest.getUserByUid(firebaseUser.uid);
      currentUserData = user;

      if (currentUserData != null) {
        _loadPosts();
      }
    } catch (e) {
      print('❌ Lỗi khi tải thông tin người dùng: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _loadPosts() {
    postsStream = _postRequest.getPosts();
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('❌ Lỗi khi đăng xuất: $e');
    }
  }
}