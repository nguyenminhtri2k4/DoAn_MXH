// lib/viewmodel/home_view_model.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/services/user_service.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PostRequest _postRequest = PostRequest();
  
  // Không cần UserService ở đây nữa nếu chỉ dùng cho việc lấy dữ liệu 1 lần
  // Dữ liệu người dùng sẽ được lấy từ Provider trong View

  Stream<List<PostModel>>? postsStream;

  HomeViewModel() {
    _loadPosts();
  }

  void _loadPosts() {
    postsStream = _postRequest.getPosts();
    notifyListeners(); // Thông báo để StreamBuilder cập nhật
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      print('❌ Lỗi khi đăng xuất: $e');
    }
  }
}