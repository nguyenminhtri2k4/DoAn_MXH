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
  bool hasAccess = false; // Kiểm tra quyền truy cập
  bool isMember = false; // Kiểm tra xem có phải thành viên không
  bool _isDisposed = false; // Thêm flag để track dispose

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
        
        // Kiểm tra quyền truy cập
        if (currentUserData != null) {
          // Kiểm tra có phải thành viên không
          isMember = group.members.contains(currentUserData!.id);
          
          // hasAccess: kiểm tra quyền xem bài viết
          hasAccess = _checkAccess();
          
          if (hasAccess) {
            // Chỉ load bài viết nếu có quyền truy cập
            // Dùng asBroadcastStream để tránh lỗi "already been listened to"
            postsStream = _postRequest.getPostsByGroupId(group.id).asBroadcastStream();
            print('✅ [PostGroupViewModel] User có quyền xem nhóm ${group.name}');
          } else {
            print('🔒 [PostGroupViewModel] User không có quyền xem nhóm ${group.name}');
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

  /// Kiểm tra xem user có quyền xem bài viết trong nhóm không
  bool _checkAccess() {
    if (currentUserData == null) return false;
    
    // Nếu nhóm công khai (status != 'private'), ai cũng xem được bài viết
    if (group.status != 'private') {
      return true;
    }
    
    // Nếu nhóm riêng tư, chỉ thành viên mới xem được
    return group.members.contains(currentUserData!.id);
  }

  /// Getter để UI kiểm tra
  bool get isPrivateGroup => group.status == 'private';
  
  /// Kiểm tra xem user có phải là chủ nhóm không
  bool get isOwner => currentUserData != null && group.ownerId == currentUserData!.id;
  
  /// Kiểm tra xem user có phải là quản lý không
  bool get isManager => currentUserData != null && group.managers.contains(currentUserData!.id);
}