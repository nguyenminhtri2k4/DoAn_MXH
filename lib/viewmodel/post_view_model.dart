
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/request/storage_request.dart';
import 'package:mangxahoi/notification/notification_service.dart';

class PostViewModel extends ChangeNotifier {
  final contentController = TextEditingController();
  final List<XFile> _mediaFiles = [];
  bool _isLoading = false;
  bool _isCheckingVideo = false;
  String? errorMessage;
  bool _canPost = false;

  List<XFile> get mediaFiles => _mediaFiles;
  bool get isLoading => _isLoading;
  bool get isCheckingVideo => _isCheckingVideo;
  bool get canPost => _canPost;
  bool get hasVideo => _mediaFiles.any((file) => file.path.endsWith('.mp4') || file.path.endsWith('.mov'));

  PostViewModel() {
    contentController.addListener(_updateCanPostState);
  }

  @override
  void dispose() {
    contentController.removeListener(_updateCanPostState);
    contentController.dispose();
    super.dispose();
  }

  void _updateCanPostState() {
    final canPostNow = contentController.text.trim().isNotEmpty || _mediaFiles.isNotEmpty;
    if (canPostNow != _canPost) {
      _canPost = canPostNow;
      notifyListeners();
    }
  }

  Future<void> pickImages(BuildContext context) async {
    if (hasVideo) {
      NotificationService().showErrorDialog(context: context, title: 'Không thể chọn ảnh', message: 'Bạn không thể đăng ảnh cùng với video.');
      return;
    }
    if (_mediaFiles.length >= 6) {
      NotificationService().showErrorDialog(context: context, title: 'Đã đạt giới hạn', message: 'Bạn chỉ có thể chọn tối đa 6 ảnh.');
      return;
    }

    final pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 70);

    if (pickedFiles.isNotEmpty) {
      final totalImages = _mediaFiles.length + pickedFiles.length;
      if (totalImages > 6) {
        NotificationService().showErrorDialog(
          context: context,
          title: 'Vượt quá giới hạn',
          message: 'Bạn chỉ có thể chọn tối đa 6 ảnh. Chỉ những ảnh đầu tiên được thêm.',
        );
        final remainingSlots = 6 - _mediaFiles.length;
        _mediaFiles.addAll(pickedFiles.sublist(0, remainingSlots));
      } else {
        _mediaFiles.addAll(pickedFiles);
      }
      _updateCanPostState();
      notifyListeners();
    }
  }

  Future<void> pickVideo(BuildContext context) async {
    if (_mediaFiles.isNotEmpty) {
      NotificationService().showErrorDialog(context: context, title: 'Không thể chọn video', message: 'Bạn chỉ có thể đăng 1 video và không thể đăng cùng với ảnh.');
      return;
    }

    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      _isCheckingVideo = true;
      notifyListeners();

      final controller = VideoPlayerController.file(File(pickedFile.path));
      try {
        await controller.initialize();
        final duration = controller.value.duration;
        await controller.dispose();

        if (duration.inSeconds > 30) {
          NotificationService().showErrorDialog(context: context, title: 'Video quá dài', message: 'Vui lòng chọn video có thời lượng tối đa 30 giây.');
        } else {
          _mediaFiles.add(pickedFile);
          _updateCanPostState();
        }
      } catch (e) {
        NotificationService().showErrorDialog(context: context, title: 'Lỗi Video', message: 'Không thể xử lý video này. Vui lòng thử video khác.');
      } finally {
        _isCheckingVideo = false;
        notifyListeners();
      }
    }
  }

  void removeMedia(int index) {
    _mediaFiles.removeAt(index);
    _updateCanPostState();
    notifyListeners();
  }

  Future<bool> createPost({
    required String authorDocId,
    required String visibility,
    String? groupId,
  }) async {
    if (!_canPost) return false;

    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final List<String> mediaIds = [];
      if (_mediaFiles.isNotEmpty) {
        final storageRequest = StorageRequest();
        for (var file in _mediaFiles) {
          final isVideo = file.path.endsWith('.mp4') || file.path.endsWith('.mov');
          final media = await storageRequest.uploadFile(
            file: File(file.path),
            type: isVideo ? 'video' : 'image',
            uploaderId: authorDocId,
          );
          if (media != null) {
            mediaIds.add(media.id);
          }
        }
      }

      final newPost = PostModel(
        id: '',
        authorId: authorDocId,
        content: contentController.text.trim(),
        mediaIds: mediaIds,
        groupId: groupId,
        visibility: visibility,
        createdAt: DateTime.now(),
      );

      await PostRequest().createPost(newPost);
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi khi đăng bài: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}