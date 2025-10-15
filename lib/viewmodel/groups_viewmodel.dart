// lib/viewmodel/groups_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/request/group_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/request/user_request.dart';

class GroupsViewModel extends ChangeNotifier {
  final GroupRequest _groupRequest = GroupRequest();
  final UserRequest _userRequest = UserRequest();
  final _auth = FirebaseAuth.instance;

  Stream<List<GroupModel>>? _groupsStream;
  Stream<List<GroupModel>>? get groupsStream => _groupsStream;

  GroupsViewModel() {
    _init();
  }

  void _init() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final user = await _userRequest.getUserByUid(firebaseUser.uid);
      if (user != null) {
        _groupsStream = _groupRequest.getGroupsByUserId(user.id);
        notifyListeners();
      }
    }
  }
}