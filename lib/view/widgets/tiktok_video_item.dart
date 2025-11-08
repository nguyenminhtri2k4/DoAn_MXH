import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/viewmodel/post_interaction_view_model.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/reaction_request.dart';
import 'package:mangxahoi/view/widgets/comment_sheet.dart';

class TikTokVideoItem extends StatefulWidget {
  final PostModel post;
  final String currentUserDocId;
  final bool isFocused;

  const TikTokVideoItem({
    super.key,
    required this.post,
    required this.currentUserDocId,
    required this.isFocused,
  });

  @override
  State<TikTokVideoItem> createState() => _TikTokVideoItemState();
}

class _TikTokVideoItemState extends State<TikTokVideoItem> with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  AnimationController? _discAnimationController; // Chuyển thành nullable

  bool _isLiked = false;
  int _likesCount = 0;
  final ReactionRequest _reactionRequest = ReactionRequest();

  UserModel? _author;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    // Khởi tạo animation controller
    _discAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _initializeVideo();
    _checkIfLiked();
    _fetchAuthorData();
  }

  @override
  void didUpdateWidget(covariant TikTokVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null && _controller!.value.isInitialized) {
      if (oldWidget.isFocused != widget.isFocused) {
        if (widget.isFocused) {
          _controller!.play();
          _discAnimationController?.repeat(); // Quay đĩa nhạc khi video chạy
        } else {
          _controller!.pause();
          _discAnimationController?.stop(); // Dừng đĩa nhạc khi video dừng
        }
      }
    }
  }

  Future<void> _fetchAuthorData() async {
    try {
      final author = await UserRequest().getUserData(widget.post.authorId);
      if (mounted && author != null) {
        setState(() {
          _author = author;
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy thông tin tác giả: $e");
    }
  }

  Future<void> _checkIfLiked() async {
    try {
      final isLiked = await _reactionRequest.hasUserLikedPost(widget.post.id, widget.currentUserDocId);
      if (mounted) {
        setState(() => _isLiked = isLiked);
      }
    } catch (e) {
      debugPrint("Lỗi kiểm tra like: $e");
    }
  }

  Future<String?> _fetchVideoUrl(String mediaId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('Media').doc(mediaId).get();
      if (docSnapshot.exists) return docSnapshot.data()?['url'] as String?;
    } catch (e) { debugPrint("Lỗi lấy URL video: $e"); }
    return null;
  }

  Future<void> _initializeVideo() async {
    if (widget.post.mediaIds.isEmpty) {
        if (mounted) setState(() => _hasError = true);
        return;
    }
    final String mediaId = widget.post.mediaIds.first;
    final String? videoUrl = await _fetchVideoUrl(mediaId);

    if (videoUrl == null || videoUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      if (widget.isFocused) {
         _controller!.play();
      } else {
         _discAnimationController?.stop(); // Dừng quay nếu không focus ban đầu
      }
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _discAnimationController?.dispose(); // Kiểm tra null trước khi dispose
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostInteractionViewModel(widget.post.id),
      child: Consumer<PostInteractionViewModel>(
        builder: (context, interactionVM, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildVideoPlayer(),
              _buildGradientOverlay(),
              _buildPostInfo(),
              _buildRightSideButtons(context, interactionVM),
            ],
          );
        }
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_hasError) return const Center(child: Icon(Icons.error_outline, color: Colors.white, size: 40));
    if (!_isInitialized || _controller == null) return const Center(child: CircularProgressIndicator(color: Colors.white));

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller!.value.isPlaying) {
             _controller!.pause();
             _discAnimationController?.stop();
          } else {
             _controller!.play();
             _discAnimationController?.repeat();
          }
        });
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      bottom: 0, left: 0, right: 0, height: 300,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
      ),
    );
  }

  Widget _buildPostInfo() {
    return Positioned(
      left: 12,
      bottom: 20,
      right: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile', arguments: widget.post.authorId),
            child: Text(
              "@${_author?.name ?? 'Người dùng'}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.post.content.isNotEmpty) ...[
             Text(
              widget.post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              const Icon(Icons.music_note, size: 15, color: Colors.white),
              const SizedBox(width: 8),
              SizedBox(
                width: 150,
                child: Text(
                  'Âm thanh gốc - ${_author?.name ?? 'Unknown'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightSideButtons(BuildContext context, PostInteractionViewModel interactionVM) {
    return Positioned(
      right: 8,
      bottom: 50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProfileAvatar(),
          const SizedBox(height: 25),
          _buildIconButton(
            icon: Icons.favorite_rounded,
            iconColor: _isLiked ? Colors.red : Colors.white,
            label: "$_likesCount",
            onTap: () async {
              setState(() {
                _isLiked = !_isLiked;
                _likesCount += _isLiked ? 1 : -1;
              });
              await interactionVM.toggleLike(widget.currentUserDocId);
            },
          ),
          const SizedBox(height: 20),
          _buildIconButton(
            icon: Icons.comment_rounded,
            label: "${widget.post.commentsCount}",
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.75,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (_, controller) => CommentSheet(
                    postId: widget.post.id,
                    // ĐÃ SỬA: Truyền currentUserDocId thay vì postOwnerId
                    currentUserDocId: widget.currentUserDocId,
                  ),
                ),
              );
            },
          ),
           const SizedBox(height: 20),
           _buildIconButton(
            icon: Icons.share_rounded,
            label: "Chia sẻ",
            iconSize: 32,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng chia sẻ đang phát triển")));
            },
          ),
          const SizedBox(height: 40),
          _buildMusicDisc(),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile', arguments: widget.post.authorId),
      child: SizedBox(
        height: 60,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: (_author?.avatar.isNotEmpty == true)
                      ? NetworkImage(_author!.avatar.first)
                      : null,
                  child: (_author?.avatar.isEmpty ?? true)
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            if (widget.post.authorId != widget.currentUserDocId)
              Positioned(
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    double iconSize = 38,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 4, color: Colors.black26)]),
        ),
      ],
    );
  }

  Widget _buildMusicDisc() {
    // Kiểm tra null trước khi dùng animation
    if (_discAnimationController == null) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey.shade800, width: 8),
          ),
           child: const Icon(Icons.music_note, size: 14, color: Colors.white),
        );
    }

    return RotationTransition(
      turns: _discAnimationController!,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade800, width: 8),
        ),
        child: CircleAvatar(
          radius: 14,
          backgroundColor: Colors.grey.shade800,
          backgroundImage: (_author?.avatar.isNotEmpty == true)
              ? NetworkImage(_author!.avatar.first)
              : null,
          child: (_author?.avatar.isEmpty ?? true)
              ? const Icon(Icons.music_note, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}