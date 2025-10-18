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
import 'comment_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:mangxahoi/services/video_cache_manager.dart';

class PostWidget extends StatelessWidget {
  final PostModel post;
  final String currentUserDocId;

  const PostWidget({
    super.key,
    required this.post,
    required this.currentUserDocId,
  });

  @override
  Widget build(BuildContext context) {
    final listener = context.watch<FirestoreListener>();
    final author = listener.getUserById(post.authorId);
    final group = post.groupId != null && post.groupId!.isNotEmpty
        ? listener.getGroupById(post.groupId!)
        : null;

    return ChangeNotifierProvider(
      key: ValueKey(post.id),
      create: (_) => PostInteractionViewModel(post.id),
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
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(context, author, group),
                  const SizedBox(height: 12),
                  if (post.content.isNotEmpty)
                    Text(post.content, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            
            if (post.mediaIds.isNotEmpty)
              _buildPostMedia(context),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildPostStats(),
            ),
            
            const Divider(height: 1, indent: 16, endIndent: 16),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Builder(
                builder: (BuildContext innerContext) {
                  return _buildActionButtons(innerContext);
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context, UserModel? author, GroupModel? group) {
    if (author == null) return const SizedBox.shrink();

    final String timestamp = '${post.createdAt.hour.toString().padLeft(2, '0')}:${post.createdAt.minute.toString().padLeft(2, '0')} · ${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}';

    if (group != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (group.type == 'post') {
                Navigator.pushNamed(context, '/post_group', arguments: group);
              }
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.groups, size: 20, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (group.type == 'post') {
                      Navigator.pushNamed(context, '/post_group', arguments: group);
                    }
                  },
                  child: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile', arguments: author.id),
                      child: Text(
                        author.name,
                        style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Text(' · ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                     Text(timestamp, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile', arguments: author.id),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: (author.avatar.isNotEmpty) ? NetworkImage(author.avatar.first) : null,
            child: (author.avatar.isEmpty) ? const Icon(Icons.person, size: 20) : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(author.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                timestamp,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostMedia(BuildContext context) {
    final listener = context.read<FirestoreListener>();
    final mediaId = post.mediaIds.first;
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
          child: const Center(child: Icon(Icons.error_outline, color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildPostStats() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('Post').doc(post.id).snapshots(),
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
              Text(likes > 0 ? '$likes lượt thích' : '', style: const TextStyle(color: AppColors.textSecondary)),
              Text(comments > 0 ? '$comments bình luận' : '', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final viewModel = Provider.of<PostInteractionViewModel>(context, listen: false);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Post')
          .doc(post.id)
          .collection('reactions')
          .doc(currentUserDocId)
          .snapshots(),
      builder: (context, snapshot) {
        final isLiked = snapshot.hasData && snapshot.data!.exists;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => viewModel.toggleLike(currentUserDocId),
                icon: Icon(
                  isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: isLiked ? AppColors.primary : AppColors.textSecondary,
                ),
                label: Text('Thích', style: TextStyle(color: isLiked ? AppColors.primary : AppColors.textSecondary)),
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
                      postId: post.id,
                      currentUserDocId: currentUserDocId,
                    ),
                  );
                },
                icon: const Icon(Icons.comment_outlined, color: AppColors.textSecondary),
                label: const Text('Bình luận', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
                label: const Text('Chia sẻ', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerItem({required this.videoUrl});

  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  late Future<VideoPlayerController> _controllerFuture;
  bool _isMuted = true;
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
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VideoPlayerController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
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
        // Nút Play/Pause
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
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 60.0),
                  ),
                ),
              ),
            );
          },
        ),

        // === SỬA ĐỔI: HIỂN THỊ THỜI GIAN KHI TUA ===
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
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        // ===========================================

        // Thanh tiến trình và nút âm lượng
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                          setState(() { _isScrubbing = true; });
                        },
                        onHorizontalDragUpdate: (details) {
                          if (!controller.value.isInitialized) return;
                          final newPosition = details.localPosition.dx / constraints.maxWidth;
                          final duration = controller.value.duration;
                          setState(() {
                            _scrubbingPosition = duration * newPosition.clamp(0.0, 1.0);
                          });
                        },
                        onHorizontalDragEnd: (details) {
                          if (!controller.value.isInitialized) return;
                          controller.seekTo(_scrubbingPosition);
                          // Đặt isScrubbing về false sau một khoảng trễ nhỏ để người dùng thấy vị trí cuối cùng
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (mounted) {
                               setState(() { _isScrubbing = false; });
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