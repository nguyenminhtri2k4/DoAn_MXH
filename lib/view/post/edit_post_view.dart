import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/request/storage_request.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mangxahoi/notification/notification_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:provider/provider.dart';

class EditPostView extends StatefulWidget {
  final PostModel post;

  const EditPostView({super.key, required this.post});

  @override
  _EditPostViewState createState() => _EditPostViewState();
}

class _EditPostViewState extends State<EditPostView> {
  late TextEditingController _contentController;
  final List<XFile> _newMediaFiles = [];
  late List<String> _existingMediaIds;
  bool _isLoading = false;

  bool get _hasVideo => widget.post.mediaIds.isNotEmpty && widget.post.mediaIds.first.contains('video');

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    _existingMediaIds = List.from(widget.post.mediaIds);
  }

  Future<void> _pickImages() async {
    final int currentMediaCount = _existingMediaIds.length + _newMediaFiles.length;
    final int remainingSlots = 6 - currentMediaCount;

    if (remainingSlots <= 0) {
      NotificationService().showErrorDialog(
        context: context,
        title: 'Đã đạt giới hạn',
        message: 'Bạn chỉ có thể đăng tối đa 6 ảnh.',
      );
      return;
    }
    
    final pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newMediaFiles.addAll(pickedFiles.take(remainingSlots));
      });
    }
  }

  Future<void> _handleUpdatePost() async {
    setState(() => _isLoading = true);
    
    try {
      List<String> updatedMediaIds = List.from(_existingMediaIds);
      if (_newMediaFiles.isNotEmpty) {
        final storageRequest = StorageRequest();
        final uploadedIds = await storageRequest.uploadFilesAndCreateMedia(
          _newMediaFiles.map((xf) => File(xf.path)).toList(),
          widget.post.authorId,
        );
        updatedMediaIds.addAll(uploadedIds);
      }

      final updatedPost = PostModel(
        id: widget.post.id,
        authorId: widget.post.authorId,
        content: _contentController.text,
        mediaIds: updatedMediaIds,
        groupId: widget.post.groupId,
        commentsCount: widget.post.commentsCount,
        likesCount: widget.post.likesCount,
        shareCount: widget.post.shareCount,
        status: widget.post.status,
        visibility: widget.post.visibility,
        createdAt: widget.post.createdAt,
        updatedAt: DateTime.now(),
        originalPostId: widget.post.originalPostId,
        originalAuthorId: widget.post.originalAuthorId,
      );

      await PostRequest().updatePost(updatedPost);
      
      if (mounted) {
        Navigator.pop(context, true); // Trả về true để báo hiệu đã cập nhật thành công
      }

    } catch (e) {
      if (mounted) {
        NotificationService().showErrorDialog(
          context: context, 
          title: 'Lỗi', 
          message: 'Không thể cập nhật bài viết: $e'
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _removeNewImage(int index) {
    setState(() {
      _newMediaFiles.removeAt(index);
    });
  }

  void _removeExistingImage(String mediaId) {
    setState(() {
      _existingMediaIds.remove(mediaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreListener = context.watch<FirestoreListener>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chỉnh sửa bài viết'),
        elevation: 1,
        backgroundColor: AppColors.backgroundLight,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleUpdatePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Text('Lưu'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _contentController,
                  autofocus: true,
                  maxLines: null,
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Bạn đang nghĩ gì?',
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_existingMediaIds.isNotEmpty || _newMediaFiles.isNotEmpty)
              _buildMediaGrid(firestoreListener),
            
            if (!_hasVideo) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Thêm ảnh'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(FirestoreListener firestoreListener) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _existingMediaIds.length + _newMediaFiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        if (index < _existingMediaIds.length) {
          // Hiển thị ảnh đã tồn tại
          final mediaId = _existingMediaIds[index];
          final media = firestoreListener.getMediaById(mediaId);
          if (media == null) return const SizedBox.shrink();
          
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: media.url,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeExistingImage(mediaId),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Hiển thị ảnh mới chọn
          final newImageIndex = index - _existingMediaIds.length;
          final newImageFile = _newMediaFiles[newImageIndex];
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(newImageFile.path),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeNewImage(newImageIndex),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}