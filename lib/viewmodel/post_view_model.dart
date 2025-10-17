
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/request/storage_request.dart';

class PostViewModel extends ChangeNotifier {
  final PostRequest _postRequest = PostRequest();
  final StorageRequest _storageRequest = StorageRequest();
  
  final TextEditingController contentController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  final List<File> _selectedImages = [];
  File? _selectedVideo;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<File> get selectedImages => _selectedImages;
  File? get selectedVideo => _selectedVideo;

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    _selectedVideo = null;
    final images = await _storageRequest.pickImages();
    if (images.isNotEmpty) {
      _selectedImages.addAll(images);
      notifyListeners();
    }
  }
  
  Future<void> pickVideo() async {
    _selectedImages.clear();
    final video = await _storageRequest.pickVideo();
    if (video != null) {
      _selectedVideo = video;
      notifyListeners();
    }
  }

  void removeImage(int index) {
    _selectedImages.removeAt(index);
    notifyListeners();
  }
  
  void removeVideo() {
    _selectedVideo = null;
    notifyListeners();
  }

  Future<bool> createPost({
    required String authorDocId,
    required String visibility,
    String? groupId,
  }) async {
    if (contentController.text.trim().isEmpty && _selectedImages.isEmpty && _selectedVideo == null) {
      _errorMessage = 'Nội dung, hình ảnh hoặc video không được để trống';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<String> mediaIds = [];
      List<File> filesToUpload = [];

      if (_selectedVideo != null) {
        filesToUpload.add(_selectedVideo!);
      } else {
        filesToUpload.addAll(_selectedImages);
      }
      
      if (filesToUpload.isNotEmpty) {
        // Gọi hàm mới để lấy về danh sách ID
        mediaIds = await _storageRequest.uploadFilesAndCreateMedia(filesToUpload, authorDocId);
      }

      final newPost = PostModel(
        id: '',
        authorId: authorDocId,
        content: contentController.text.trim(),
        mediaIds: mediaIds, // Lưu danh sách Media ID vào bài đăng
        createdAt: DateTime.now(),
        visibility: visibility,
        groupId: groupId,
      );

      await _postRequest.createPost(newPost);
      
      contentController.clear();
      _selectedImages.clear();
      _selectedVideo = null;
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi hệ thống: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}