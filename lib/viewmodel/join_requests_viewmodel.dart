import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_join_request.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/group_request.dart';
import 'package:mangxahoi/request/user_request.dart';

class JoinRequestsViewModel extends ChangeNotifier {
  final String groupId;
  final GroupRequest _groupRequest = GroupRequest();
  final UserRequest _userRequest = UserRequest();

  Stream<List<JoinRequestModel>> get requestsStream => 
      _groupRequest.getPendingJoinRequests(groupId);

  JoinRequestsViewModel({required this.groupId});

  // Cache thông tin user để hiển thị avatar/tên
  final Map<String, UserModel> _userCache = {};

  Future<UserModel?> getUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }
    final user = await _userRequest.getUserData(userId);
    if (user != null) {
      _userCache[userId] = user;
      notifyListeners();
    }
    return user;
  }

  Future<void> approveRequest(String requestId, String userId) async {
    try {
      await _groupRequest.approveJoinRequest(groupId, requestId, userId);
    } catch (e) {
      print('Lỗi approve: $e');
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _groupRequest.rejectJoinRequest(groupId, requestId);
    } catch (e) {
      print('Lỗi reject: $e');
    }
  }
}