
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/request/group_request.dart';

class CreateGroupViewModel extends ChangeNotifier {
  final UserRequest _userRequest = UserRequest();
  final GroupRequest _groupRequest = GroupRequest();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<UserModel> _friends = [];
  List<UserModel> get friends => _friends;

  final List<UserModel> _selectedFriends = [];
  List<UserModel> get selectedFriends => _selectedFriends;

  final TextEditingController groupNameController = TextEditingController();
  String _groupType = 'post';
  String get groupType => _groupType;

  CreateGroupViewModel() {
    _fetchFriends();
    groupNameController.addListener(() {
      notifyListeners();
    });
  }

  Future<void> _fetchFriends() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final user = await _userRequest.getUserByUid(currentUser.uid);
      if (user != null) {
        final friendIds = user.friends;
        final List<UserModel> friendsList = [];
        for (var friendId in friendIds) {
          final friend = await _userRequest.getUserData(friendId);
          if (friend != null) {
            friendsList.add(friend);
          }
        }
        _friends = friendsList;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  void toggleFriendSelection(UserModel friend) {
    if (_selectedFriends.contains(friend)) {
      _selectedFriends.remove(friend);
    } else {
      _selectedFriends.add(friend);
    }
    notifyListeners();
  }

  void setGroupType(String type) {
    _groupType = type;
    notifyListeners();
  }

  Future<bool> createGroup() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    final user = await _userRequest.getUserByUid(currentUser.uid);
    if (user == null) return false;

    if (groupNameController.text.isEmpty || _selectedFriends.isEmpty) {
      return false;
    }

    final members = [user, ..._selectedFriends];

    try {
      await _groupRequest.createGroup(
        groupNameController.text,
        members,
        user.id,
        _groupType,
      );
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}