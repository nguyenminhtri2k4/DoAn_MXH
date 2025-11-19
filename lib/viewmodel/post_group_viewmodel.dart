import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/group_request.dart';

class PostGroupViewModel extends ChangeNotifier {
  final PostRequest _postRequest = PostRequest();
  final UserRequest _userRequest = UserRequest();
  final GroupRequest _groupRequest = GroupRequest();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool get isGroupDeleted => group.status.toLowerCase() == 'deleted';

  final GroupModel group;
  UserModel? currentUserData;
  Stream<List<PostModel>>? postsStream;
  bool isLoading = true;
  bool hasAccess = false;
  bool isMember = false;
  bool _isDisposed = false;

  PostGroupViewModel({required this.group}) {
    _initialize();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void _initialize() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        currentUserData = await _userRequest.getUserByUid(firebaseUser.uid);

        if (currentUserData != null) {
          isMember = group.members.contains(currentUserData!.id);
          hasAccess = _checkAccess();

          if (hasAccess) {
            postsStream =
                _postRequest.getPostsByGroupId(group.id).asBroadcastStream();
            print(
              '✅ [PostGroupViewModel] User có quyền xem nhóm ${group.name}',
            );
          } else {
            print(
              '🔒 [PostGroupViewModel] User không có quyền xem nhóm ${group.name}',
            );
          }
        }
      }
    } catch (e) {
      print('❌ [PostGroupViewModel] Lỗi khi khởi tạo: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _checkAccess() {
    if (currentUserData == null) return false;
    if (group.status != 'private') return true;
    return group.members.contains(currentUserData!.id);
  }

  bool get isPrivateGroup => group.status == 'private';
  bool get isOwner =>
      currentUserData != null && group.ownerId == currentUserData!.id;
  bool get isManager =>
      currentUserData != null && group.managers.contains(currentUserData!.id);

  /// ✅ Phương thức rời nhóm với logic đầy đủ
  Future<LeaveGroupResult> leaveGroup() async {
    if (currentUserData == null) {
      return LeaveGroupResult(
        success: false,
        message: 'Không thể xác định thông tin người dùng',
      );
    }

    try {
      print('🔄 [PostGroupViewModel] Starting leave group process...');
      print('   User ID: ${currentUserData!.id}');
      print('   Group ID: ${group.id}');
      print('   Is Owner: $isOwner');
      print('   Is Manager: $isManager');

      // ✅ KIỂM TRA 1: Chủ nhóm không được rời
      if (isOwner) {
        print('❌ [PostGroupViewModel] Owner cannot leave group');
        return LeaveGroupResult(
          success: false,
          message:
              'Chủ nhóm không thể rời khỏi nhóm. Vui lòng chuyển quyền chủ nhóm trước.',
        );
      }

      // ✅ KIỂM TRA 2: Nếu là Manager
      if (isManager) {
        print(
          '🔄 [PostGroupViewModel] User is manager, removing from managers list...',
        );
        await _groupRequest.removeMemberFromGroup(
          group.id,
          currentUserData!.id,
        );

        print('✅ [PostGroupViewModel] Manager removed successfully');
        return LeaveGroupResult(
          success: true,
          message: 'Bạn đã rời khỏi nhóm thành công',
        );
      }

      // ✅ KIỂM TRA 3: Thành viên thường
      print('🔄 [PostGroupViewModel] User is regular member, removing...');
      await _groupRequest.removeMemberFromGroup(group.id, currentUserData!.id);

      print('✅ [PostGroupViewModel] Member removed successfully');
      return LeaveGroupResult(
        success: true,
        message: 'Bạn đã rời khỏi nhóm thành công',
      );
    } catch (e) {
      print('❌ [PostGroupViewModel] Error leaving group: $e');
      return LeaveGroupResult(
        success: false,
        message: 'Có lỗi xảy ra khi rời nhóm: ${e.toString()}',
      );
    }
  }
}

/// Class để trả về kết quả của việc rời nhóm
class LeaveGroupResult {
  final bool success;
  final String message;

  LeaveGroupResult({required this.success, required this.message});
}
