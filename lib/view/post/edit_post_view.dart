
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

  bool get _hasVideo => widget.post.mediaIds.isNotEmpty && 
      widget.post.mediaIds.first.contains('video');

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    _existingMediaIds = List.from(widget.post.mediaIds);
    
    // Show bottom sheet sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showEditBottomSheet();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _showEditBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !_isLoading,
      enableDrag: !_isLoading,
      builder: (context) => _buildBottomSheet(),
    ).then((result) {
      // Khi bottom sheet đóng, pop màn hình này
      if (mounted) {
        Navigator.pop(context, result);
      }
    });
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
    if (_contentController.text.trim().isEmpty && 
        _existingMediaIds.isEmpty && 
        _newMediaFiles.isEmpty) {
      NotificationService().showErrorDialog(
        context: context,
        title: 'Lỗi',
        message: 'Bài viết không thể để trống',
      );
      return;
    }

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
        Navigator.pop(context, true); // Đóng bottom sheet
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
    // Màn hình trong suốt, bottom sheet sẽ hiển thị
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }

  Widget _buildBottomSheet() {
    final firestoreListener = context.watch<FirestoreListener>();
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title and buttons
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, size: 28),
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Chỉnh sửa bài viết',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleUpdatePost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isLoading 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ) 
                              : const Text(
                                  'Lưu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Text input
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _contentController,
                        autofocus: true,
                        maxLines: null,
                        minLines: 3,
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Bạn đang nghĩ gì?',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Media grid
                    if (_existingMediaIds.isNotEmpty || _newMediaFiles.isNotEmpty)
                      _buildMediaGrid(firestoreListener),

                    const SizedBox(height: 16),

                    // Add photos button
                    if (!_hasVideo)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _pickImages,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Thêm ảnh',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMediaGrid(FirestoreListener firestoreListener) {
    final totalMedia = _existingMediaIds.length + _newMediaFiles.length;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalMedia,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: totalMedia == 1 ? 1 : (totalMedia == 2 ? 2 : 3),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: totalMedia == 1 ? 16 / 9 : 1,
        ),
        itemBuilder: (context, index) {
          if (index < _existingMediaIds.length) {
            return _buildExistingMediaItem(
              _existingMediaIds[index],
              firestoreListener,
            );
          } else {
            final newImageIndex = index - _existingMediaIds.length;
            return _buildNewMediaItem(_newMediaFiles[newImageIndex], newImageIndex);
          }
        },
      ),
    );
  }

  Widget _buildExistingMediaItem(String mediaId, FirestoreListener firestoreListener) {
    final media = firestoreListener.getMediaById(mediaId);
    if (media == null) return const SizedBox.shrink();
    
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: media.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error_outline, color: Colors.grey),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _removeExistingImage(mediaId),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewMediaItem(XFile file, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(file.path),
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _removeNewImage(index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}