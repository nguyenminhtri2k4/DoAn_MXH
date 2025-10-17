import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/request/user_request.dart';

class PostGroupViewModel extends ChangeNotifier {
  final PostRequest _postRequest = PostRequest();
  final UserRequest _userRequest = UserRequest();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GroupModel group;
  UserModel? currentUserData;
  Stream<List<PostModel>>? postsStream;
  bool isLoading = true;

  PostGroupViewModel({required this.group}) {
    _initialize();
  }

  void _initialize() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      currentUserData = await _userRequest.getUserByUid(firebaseUser.uid);
    }
    postsStream = _postRequest.getPostsByGroupId(group.id);
    isLoading = false;
    notifyListeners();
  }
}