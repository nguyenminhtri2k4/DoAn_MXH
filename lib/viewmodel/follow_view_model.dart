import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/follow_request.dart';
import 'package:mangxahoi/request/user_request.dart';

class FollowViewModel extends ChangeNotifier {
  final String userId;
  final FollowRequest _followRequest = FollowRequest();
  final UserRequest _userRequest = UserRequest();

  FollowViewModel({required this.userId});

  Stream<List<UserModel>> get followersStream => _followRequest
      .getFollowers(userId)
      .asyncMap((userIds) => _getUsersDetails(userIds));

  Stream<List<UserModel>> get followingStream => _followRequest
      .getFollowing(userId)
      .asyncMap((userIds) => _getUsersDetails(userIds));

  Future<List<UserModel>> _getUsersDetails(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    List<UserModel> users = [];
    for (var id in userIds) {
      final user = await _userRequest.getUserData(id);
      if (user != null) {
        users.add(user);
      }
    }
    return users;
  }
}