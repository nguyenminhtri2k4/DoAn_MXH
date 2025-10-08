import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart';

class PostViewModel extends ChangeNotifier {
  final PostRequest _postRequest = PostRequest();
  
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

  // Hàm tạo bài viết đã được cập nhật
  Future<bool> createPost({required String authorDocId, required String visibility}) async {
    if (authorDocId.isEmpty) {
      _errorMessage = 'Không xác định được người dùng';
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
        id: '',
        authorId: authorDocId, // Sử dụng Document ID
        content: contentController.text.trim(),
        createdAt: DateTime.now(),
        visibility: visibility,
      );

      final postId = await _postRequest.createPost(newPost);
      
      if (postId.isNotEmpty) {
        contentController.clear();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Tạo bài viết thất bại, không nhận được ID');
      }

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi hệ thống: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}