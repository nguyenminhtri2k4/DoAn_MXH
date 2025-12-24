
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_story.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_story_view.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/request/story_request.dart';
import 'package:mangxahoi/request/chat_request.dart';
import 'package:intl/intl.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewerScreen({
    Key? key,
    required this.stories,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _StoryViewerScreenState createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AudioPlayer _audioPlayer;
  VideoPlayerController? _videoController;
  
  final StoryRequest _storyRequest = StoryRequest();
  final ChatRequest _chatRequest = ChatRequest();
  final TextEditingController _messageController = TextEditingController();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _audioPlayer = AudioPlayer();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNextStory();
      }
    });

    _playStory(widget.stories[_currentIndex]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _audioPlayer.dispose();
    _videoController?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // --- LOGIC PHÁT STORY ---
  void _playStory(StoryModel story) async {
    _animationController.stop();
    _animationController.reset();
    _videoController?.dispose();
    _videoController = null;
    _audioPlayer.stop();

    final currentUserId = context.read<FirestoreListener>().currentUser?.id;
    if (currentUserId != null && story.authorId != currentUserId) {
      _storyRequest.markStoryAsViewed(story.id, currentUserId);
    }

    bool hasAudio = story.audioUrl != null && story.audioUrl!.isNotEmpty;
    bool isVideo = story.mediaType == 'video';

    try {
      if (isVideo) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
        await _videoController!.initialize();
        if (mounted) {
          _animationController.duration = _videoController!.value.duration;
          _videoController!.play();
          if (_videoController!.value.volume > 0) {
            _audioPlayer.setVolume(0);
          } else if (hasAudio) {
            await _audioPlayer.setUrl(story.audioUrl!);
            _audioPlayer.play();
          }
          _animationController.forward();
          setState(() {});
        }
      } else if (hasAudio) {
        await _audioPlayer.setUrl(story.audioUrl!);
        final audioDuration = _audioPlayer.duration;
        if (mounted) {
          _animationController.duration = audioDuration ?? const Duration(seconds: 5);
          _audioPlayer.play();
          _animationController.forward();
          setState(() {});
        }
      } else {
        _animationController.duration = const Duration(seconds: 5);
        _animationController.forward();
        if (mounted) setState(() {});
      }
    } catch (e) {
      _animationController.duration = const Duration(seconds: 5);
      _animationController.forward();
      if (mounted) setState(() {});
    }
  }

  void _goToNextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _currentIndex++;
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPreviousStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  void _pauseStory() {
    _animationController.stop();
    _audioPlayer.pause();
    _videoController?.pause();
  }

  void _resumeStory() {
    _animationController.forward();
    if (_videoController == null || _videoController!.value.volume == 0) {
      _audioPlayer.play();
    }
    _videoController?.play();
  }

  // --- LOGIC NHẮN TIN ---
  Future<void> _handleSendMessage(StoryModel story) async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = context.read<FirestoreListener>().currentUser?.id;
    if (currentUserId == null) return;

    try {
      final chatId = await _chatRequest.getOrCreatePrivateChat(currentUserId, story.authorId);
      final newMessage = MessageModel(
        id: '',
        senderId: currentUserId,
        content: "Phản hồi story: $text",
        createdAt: DateTime.now(),
        mediaIds: [],
        status: 'sent',
        type: 'text',
      );
      await _chatRequest.sendMessage(chatId, newMessage);
      _messageController.clear();
      FocusScope.of(context).unfocus();
      _resumeStory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã gửi phản hồi"), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      debugPrint("Lỗi gửi tin nhắn từ story: $e");
    }
  }

  void _sendReaction(String emoji) {
    final currentUserId = context.read<FirestoreListener>().currentUser?.id;
    if (currentUserId == null) return;
    _storyRequest.reactToStory(widget.stories[_currentIndex].id, currentUserId, emoji);
  }

  // --- BUILD UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.stories.length,
        onPageChanged: (index) {
          _currentIndex = index;
          _playStory(widget.stories[index]);
        },
        itemBuilder: (context, index) => _buildStoryPage(widget.stories[index]),
      ),
    );
  }

  Widget _buildStoryPage(StoryModel story) {
    final currentUser = context.watch<FirestoreListener>().currentUser;
    final isOwner = story.authorId == currentUser?.id;
    final author = context.read<FirestoreListener>().getUserById(story.authorId);

    return GestureDetector(
      onTapDown: (_) => _pauseStory(),
      onTapUp: (details) {
        final width = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < width / 3) _goToPreviousStory();
        else if (details.globalPosition.dx > (width * 2 / 3)) _goToNextStory();
        else _resumeStory();
      },
      onLongPress: () => _pauseStory(),
      onLongPressUp: () => _resumeStory(),
      onVerticalDragEnd: (details) { if (details.primaryVelocity! > 200) Navigator.pop(context); },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildStoryContent(story),
          Positioned.fill(child: _buildGradientOverlay()),
          _buildSegmentedProgressBar(),
          _buildStoryHeader(story, author),
          _buildAudioInfo(story),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16, right: 16,
            child: isOwner ? _buildOwnerFooter(story) : _buildViewerFooter(story),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedProgressBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 8, right: 8,
      child: Row(
        children: List.generate(widget.stories.length, (index) => Expanded(
          child: Container(
            height: 3, margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                double progress = 0.0;
                if (index < _currentIndex) progress = 1.0;
                else if (index == _currentIndex) progress = _animationController.value;
                return FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: progress, child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))));
              },
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildStoryHeader(StoryModel story, UserModel? author) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 25,
      left: 16, right: 8,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: (author?.avatar.isNotEmpty ?? false) ? CachedNetworkImageProvider(author!.avatar.first) : null,
            child: (author?.avatar.isEmpty ?? true) ? const Icon(Icons.person, size: 18) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(author?.name ?? 'Người dùng', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(_formatStoryTime(story.createdAt), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          ])),
          IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    if (story.mediaType == 'image') return CachedNetworkImage(imageUrl: story.mediaUrl, fit: BoxFit.cover, errorWidget: (c, u, e) => const Center(child: Text('Lỗi tải ảnh', style: TextStyle(color: Colors.white))));
    if (story.mediaType == 'video' && _videoController != null && _videoController!.value.isInitialized) return FittedBox(fit: BoxFit.cover, child: SizedBox(width: _videoController!.value.size.width, height: _videoController!.value.size.height, child: VideoPlayer(_videoController!)));
    if (story.mediaType == 'text') return Container(color: story.backgroundColor.isNotEmpty ? Color(int.parse(story.backgroundColor.split('(0x')[1].split(')')[0], radix: 16)) : Colors.blue, padding: const EdgeInsets.all(40), alignment: Alignment.center, child: Text(story.content, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)));
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildGradientOverlay() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.5), Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.6)],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
    );
  }

  // ✅ KHÔI PHỤC GIAO DIỆN ÂM THANH TRƯỚC ĐÓ (ĐĨA QUAY + COVER IMAGE)
  Widget _buildAudioInfo(StoryModel story) {
    if (story.audioName == null || story.audioName!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 160, // Đặt phía trên thanh nhập tin nhắn
      left: 16,
      right: 80,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Đĩa nhạc (hình ảnh quay tròn)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * 2 * 3.14159,
                  child: child,
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: (story.audioCoverUrl != null && story.audioCoverUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(story.audioCoverUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[800],
                ),
                child: (story.audioCoverUrl == null || story.audioCoverUrl!.isEmpty)
                    ? const Icon(Icons.music_note, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            
            // Thông tin bài hát
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    story.audioName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.music_note, size: 12, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        'Original audio',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.audiotrack_rounded, color: Colors.white.withOpacity(0.8), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerFooter(StoryModel story) {
    return GestureDetector(
      onTap: () {
        _pauseStory();
        _showViewers(story.id);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.keyboard_arrow_up, color: Colors.white),
          Text("${story.views.length} người xem", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildViewerFooter(StoryModel story) {
    final emojis = ["❤️", "😂", "😮", "😢", "🔥", "👏"];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis.map((e) => GestureDetector(
            onTap: () => _sendReaction(e),
            child: Text(e, style: const TextStyle(fontSize: 30)),
          )).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                onTap: () => _pauseStory(),
                decoration: InputDecoration(
                  hintText: 'Gửi tin nhắn...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _handleSendMessage(story),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _handleSendMessage(story),
            ),
          ],
        ),
      ],
    );
  }

  void _showViewers(String storyId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StreamBuilder<List<StoryViewModel>>(
          stream: _storyRequest.getStoryViewers(storyId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final viewers = snapshot.data!;
            return Column(
              children: [
                const Padding(padding: EdgeInsets.all(16.0), child: Text("Người xem", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                Expanded(
                  child: ListView.builder(
                    itemCount: viewers.length,
                    itemBuilder: (context, index) {
                      final v = viewers[index];
                      final user = context.read<FirestoreListener>().getUserById(v.viewerId);
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: (user?.avatar.isNotEmpty ?? false) ? CachedNetworkImageProvider(user!.avatar.first) : null),
                        title: Text(user?.name ?? 'Người dùng'),
                        trailing: v.reactionType.isNotEmpty ? Text(v.reactionType, style: const TextStyle(fontSize: 24)) : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => _resumeStory());
  }

  String _formatStoryTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}g';
    return DateFormat('dd/MM').format(time);
  }
}