
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
    // Sử dụng context.read thay vì watch để tránh rebuild không cần thiết
    final listener = context.read<FirestoreListener>();
    final mediaId = post.mediaIds.first;
    final media = listener.getMediaById(mediaId);

    if (media == null) {
      // Hiển thị placeholder trong khi listener đang tải dữ liệu
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
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(true);

    _controller.addListener(() {
      if (!mounted) return;
      if (_isPlaying != _controller.value.isPlaying) {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction < 0.5 && _controller.value.isPlaying) {
          _controller.pause();
        }
      },
      child: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    AnimatedOpacity(
                      opacity: _isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 60.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              height: 250,
              color: Colors.black,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
    );
  }
}