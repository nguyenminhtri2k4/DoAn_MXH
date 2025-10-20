import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_media.dart';
import 'package:mangxahoi/viewmodel/post_interaction_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'comment_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:mangxahoi/services/video_cache_manager.dart';
import 'package:mangxahoi/view/widgets/share_bottom_sheet.dart';
import 'package:mangxahoi/view/post/edit_post_view.dart';

// Bước 1: Chuyển thành StatefulWidget
class PostWidget extends StatefulWidget {
  final PostModel post;
  final String currentUserDocId;

  const PostWidget({
    super.key,
    required this.post,
    required this.currentUserDocId,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  // Biến state để lưu trữ và cập nhật thông tin post
  late PostModel _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }

  // Cập nhật state nếu widget cha build lại với post mới
  @override
  void didUpdateWidget(covariant PostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post != oldWidget.post) {
      setState(() {
        _currentPost = widget.post;
      });
    }
  }

  // Helper functions for privacy button
  IconData _getVisibilityIcon(String visibility) {
    switch (visibility) {
      case 'private':
        return Icons.lock;
      case 'friends':
        return Icons.group;
      default:
        return Icons.public;
    }
  }

  String _getVisibilityText(String visibility) {
    switch (visibility) {
      case 'private':
        return 'Chỉ mình tôi';
      case 'friends':
        return 'Bạn bè';
      default:
        return 'Công khai';
    }
  }

  @override
  Widget build(BuildContext context) {
    final listener = context.watch<FirestoreListener>();
    final author = listener.getUserById(_currentPost.authorId);

    final isSharedPost = _currentPost.originalPostId != null &&
        _currentPost.originalPostId!.isNotEmpty;

    if (_currentPost.status == 'deleted') {
      return const SizedBox.shrink();
    }

    return ChangeNotifierProvider(
      key: ValueKey(_currentPost.id),
      create: (_) => PostInteractionViewModel(_currentPost.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(context, author),
                  const SizedBox(height: 12),
                  if (_currentPost.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(_currentPost.content,
                          style: const TextStyle(fontSize: 16)),
                    ),
                ],
              ),
            ),
            if (isSharedPost) _buildOriginalPostContent(context),
            if (!isSharedPost && _currentPost.mediaIds.isNotEmpty)
              _buildPostMedia(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildPostStats(),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Builder(builder: (BuildContext innerContext) {
                return _buildActionButtons(innerContext);
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.black87),
                title: const Text('Chỉnh sửa bài viết'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPostView(post: _currentPost),
                    ),
                  );
                  if (result == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bài viết đã được cập nhật')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa bài viết',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: const Text(
                            'Bạn có chắc chắn muốn xóa bài viết này không?'),
                        actions: [
                          TextButton(
                            child: const Text('Hủy'),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                          TextButton(
                            child: const Text('Xóa',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              PostRequest().deletePostSoft(_currentPost.id);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Bước 2: Sửa hàm _showPrivacyPicker
  void _showPrivacyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Không cần StatefulBuilder nữa vì bottom sheet sẽ đóng ngay
        Widget buildPrivacyOption({
          required String value,
          required IconData icon,
          required String title,
          required String subtitle,
        }) {
          final bool isSelected = _currentPost.visibility == value;
          return ListTile(
            onTap: () => _updatePrivacy(context, value), // Chỉ cần gọi hàm update
            leading: Icon(icon, color: Colors.grey[700]),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ai có thể xem bài viết này?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              buildPrivacyOption(
                value: 'public',
                icon: Icons.public,
                title: 'Công khai',
                subtitle: 'Bất kỳ ai ở trong hoặc ngoài mạng xã hội.',
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              buildPrivacyOption(
                value: 'friends',
                icon: Icons.group,
                title: 'Bạn bè',
                subtitle: 'Chỉ bạn bè của bạn có thể xem.',
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              buildPrivacyOption(
                value: 'private',
                icon: Icons.lock,
                title: 'Chỉ mình tôi',
                subtitle: 'Bài viết này sẽ không hiển thị với ai khác.',
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Bước 3: Sửa hàm _updatePrivacy
  void _updatePrivacy(BuildContext context, String newVisibility) {
    // 1. Cập nhật giao diện ngay lập tức
    setState(() {
      _currentPost = _currentPost.copyWith(visibility: newVisibility, updatedAt: DateTime.now());
    });

    // 2. Gửi yêu cầu cập nhật lên server
    PostRequest().updatePost(_currentPost);

    // 3. Đóng bottom sheet
    Navigator.pop(context);
  }

  Widget _buildPrivacyButton(BuildContext context) {
    return InkWell(
      onTap: () => _showPrivacyPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(_getVisibilityIcon(_currentPost.visibility),
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              _getVisibilityText(_currentPost.visibility),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const Icon(Icons.arrow_drop_down,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context, UserModel? author) {
    if (author == null) return const SizedBox.shrink();

    final String timestamp =
        '${_currentPost.createdAt.hour.toString().padLeft(2, '0')}:${_currentPost.createdAt.minute.toString().padLeft(2, '0')} · ${_currentPost.createdAt.day}/${_currentPost.createdAt.month}/${_currentPost.createdAt.year}';
    final isOwner = widget.currentUserDocId == _currentPost.authorId;

    return Row(
      children: [
        GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, '/profile', arguments: author.id),
          child: CircleAvatar(
            radius: 20,
            backgroundImage:
                (author.avatar.isNotEmpty) ? NetworkImage(author.avatar.first) : null,
            child:
                (author.avatar.isEmpty) ? const Icon(Icons.person, size: 20) : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(author.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                timestamp,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        if (isOwner) ...[
          _buildPrivacyButton(context),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showPostOptions(context),
          ),
        ]
      ],
    );
  }

  Widget _buildSharedPostHeader(BuildContext context, UserModel? sharer) {
    if (sharer == null) return const SizedBox.shrink();

    final timestamp =
        '${_currentPost.createdAt.hour.toString().padLeft(2, '0')}:${_currentPost.createdAt.minute.toString().padLeft(2, '0')} · ${_currentPost.createdAt.day}/${_currentPost.createdAt.month}/${_currentPost.createdAt.year}';
    final isOwner = widget.currentUserDocId == _currentPost.authorId;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage:
              (sharer.avatar.isNotEmpty) ? NetworkImage(sharer.avatar.first) : null,
          child:
              (sharer.avatar.isEmpty) ? const Icon(Icons.person, size: 20) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                  children: [
                    TextSpan(
                      text: sharer.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' đã chia sẻ một bài viết.'),
                  ],
                ),
              ),
              Text(
                timestamp,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        if (isOwner) ...[
          _buildPrivacyButton(context),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showPostOptions(context),
          ),
        ]
      ],
    );
  }

  Widget _buildOriginalPostContent(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Post')
          .doc(_currentPost.originalPostId!)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final originalPostData =
            snapshot.data!.data() as Map<String, dynamic>;
        final originalPost =
            PostModel.fromMap(snapshot.data!.id, originalPostData);
        final listener = context.read<FirestoreListener>();
        final originalAuthor = listener.getUserById(originalPost.authorId);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildPostHeader(context, originalAuthor),
              ),
              if (originalPost.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                  child: Text(originalPost.content,
                      style: const TextStyle(fontSize: 16)),
                ),
              if (originalPost.mediaIds.isNotEmpty)
                _buildOriginalPostMedia(context, originalPost),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOriginalPostMedia(BuildContext context, PostModel originalPost) {
    final listener = context.read<FirestoreListener>();
    final mediaId = originalPost.mediaIds.first;
    final media = listener.getMediaById(mediaId);

    if (media == null) return const SizedBox.shrink();

    if (media.type == 'video') {
      return _VideoPlayerItem(videoUrl: media.url);
    }

    return CachedNetworkImage(
      imageUrl: media.url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        height: 250,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        height: 250,
        color: Colors.grey[200],
        child:
            const Center(child: Icon(Icons.error_outline, color: Colors.red)),
      ),
    );
  }

  Widget _buildPostMedia(BuildContext context) {
    final listener = context.read<FirestoreListener>();
    final mediaId = _currentPost.mediaIds.first;
    final media = listener.getMediaById(mediaId);

    if (media == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Container(
          height: 250,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (media.type == 'video') {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: _VideoPlayerItem(videoUrl: media.url),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: CachedNetworkImage(
        imageUrl: media.url,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          height: 250,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 250,
          color: Colors.grey[200],
          child: const Center(
              child: Icon(Icons.error_outline, color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildPostStats() {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Post')
            .doc(_currentPost.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final postData = snapshot.data!.data() as Map<String, dynamic>?;
          final likes = postData?['likesCount'] ?? 0;
          final comments = postData?['commentsCount'] ?? 0;

          if (likes == 0 && comments == 0) return const SizedBox(height: 8);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(likes > 0 ? '$likes lượt thích' : '',
                    style: const TextStyle(color: AppColors.textSecondary)),
                Text(comments > 0 ? '$comments bình luận' : '',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        });
  }

  Widget _buildActionButtons(BuildContext context) {
    final viewModel = Provider.of<PostInteractionViewModel>(context, listen: false);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Post')
          .doc(_currentPost.id)
          .collection('reactions')
          .doc(widget.currentUserDocId)
          .snapshots(),
      builder: (context, snapshot) {
        final isLiked = snapshot.hasData && snapshot.data!.exists;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => viewModel.toggleLike(widget.currentUserDocId),
                icon: Icon(
                  isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: isLiked ? AppColors.primary : AppColors.textSecondary,
                ),
                label: Text('Thích',
                    style: TextStyle(
                        color: isLiked
                            ? AppColors.primary
                            : AppColors.textSecondary)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CommentSheet(
                      postId: _currentPost.id,
                      currentUserDocId: widget.currentUserDocId,
                    ),
                  );
                },
                icon: const Icon(Icons.comment_outlined,
                    color: AppColors.textSecondary),
                label: const Text('Bình luận',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ShareBottomSheet(
                      post: _currentPost,
                    ),
                  );
                },
                icon: const Icon(Icons.share_outlined,
                    color: AppColors.textSecondary),
                label: const Text('Chia sẻ',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ... _VideoPlayerItem không thay đổi ...
class _VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerItem({required this.videoUrl});

  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  late Future<VideoPlayerController> _controllerFuture;
  bool _isMuted = false;
  bool _isScrubbing = false;
  Duration _scrubbingPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controllerFuture = context
        .read<VideoCacheManager>()
        .getControllerForUrl(widget.videoUrl)
        .then((controller) {
      if (mounted) {
        controller.setVolume(_isMuted ? 0 : 1);
      }
      return controller;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VideoPlayerController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final controller = snapshot.data!;
          return VisibilityDetector(
            key: Key(widget.videoUrl),
            onVisibilityChanged: (visibilityInfo) {
              final visibleFraction = visibilityInfo.visibleFraction;
              if (mounted) {
                if (visibleFraction > 0.8) {
                  controller.play();
                  controller.setLooping(true);
                } else {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  }
                }
              }
            },
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        controller.value.isPlaying
                            ? controller.pause()
                            : controller.play();
                      });
                    },
                    child: VideoPlayer(controller),
                  ),
                  _buildControlsOverlay(controller),
                ],
              ),
            ),
          );
        }
        return Container(
          height: 250,
          color: Colors.black,
          child: const Center(
              child: CircularProgressIndicator(color: Colors.white)),
        );
      },
    );
  }

  Widget _buildControlsOverlay(VideoPlayerController controller) {
    return Stack(
      children: [
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, VideoPlayerValue value, child) {
            return AnimatedOpacity(
              opacity: value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      controller.play();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 60.0),
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isScrubbing ? 1.0 : 0.0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_formatDuration(_scrubbingPosition)} / ${_formatDuration(controller.value.duration)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (details) {
                          if (!controller.value.isInitialized) return;
                          setState(() {
                            _isScrubbing = true;
                          });
                        },
                        onHorizontalDragUpdate: (details) {
                          if (!controller.value.isInitialized) return;
                          final newPosition =
                              details.localPosition.dx / constraints.maxWidth;
                          final duration = controller.value.duration;
                          setState(() {
                            _scrubbingPosition =
                                duration * newPosition.clamp(0.0, 1.0);
                          });
                        },
                        onHorizontalDragEnd: (details) {
                          if (!controller.value.isInitialized) return;
                          controller.seekTo(_scrubbingPosition);
                          Future.delayed(const Duration(milliseconds: 200),
                              () {
                            if (mounted) {
                              setState(() {
                                _isScrubbing = false;
                              });
                            }
                          });
                        },
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          colors: const VideoProgressColors(
                            playedColor: Colors.white,
                            bufferedColor: Colors.white54,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMuted = !_isMuted;
                      controller.setVolume(_isMuted ? 0 : 1);
                    });
                  },
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}