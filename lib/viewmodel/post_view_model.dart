// lib/viewmodel/post_view_model.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart';

class PostViewModel extends ChangeNotifier {
  final PostRequest _postRequest = PostRequest();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController contentController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  /// Xử lý logic tạo bài viết
  Future<bool> createPost(String visibility) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'Bạn chưa đăng nhập';
      notifyListeners();
      return false;
    }

    if (contentController.text.trim().isEmpty) {
      _errorMessage = 'Nội dung bài viết không được để trống';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPost = PostModel(
        id: '', // Sẽ được gán bởi Firestore
        authorId: user.uid, // Lấy Auth UID của người dùng
        content: contentController.text.trim(),
        createdAt: DateTime.now(),
        visibility: visibility,
        // Các trường mặc định khác sẽ dùng giá trị mặc định trong PostModel
      );

      final postId = await _postRequest.createPost(newPost);
      
      if (postId.isNotEmpty) {
        contentController.clear();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Tạo bài viết thất bại, không nhận được ID';
        _isLoading = false;
        notifyListeners();
        return false;
      }

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi hệ thống: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}