
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_story.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:mangxahoi/model/model_user.dart';
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
    super.dispose();
  }

  void _playStory(StoryModel story) async {
    _animationController.stop();
    _animationController.reset();
    _videoController?.dispose();
    _videoController = null;
    _audioPlayer.stop();

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
      print("Lỗi khi phát story: $e");
      _animationController.duration = const Duration(seconds: 5);
      _animationController.forward();
      if (mounted) setState(() {});
    }
  }

  void _goToNextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _currentIndex++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPreviousStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.stories.length,
        onPageChanged: (index) {
          _currentIndex = index;
          _playStory(widget.stories[index]);
        },
        itemBuilder: (context, index) {
          final story = widget.stories[index];
          return _buildStoryPage(story);
        },
      ),
    );
  }

  Widget _buildStoryPage(StoryModel story) {
    final firestoreListener = context.read<FirestoreListener>();
    final author = firestoreListener.getUserById(story.authorId);

    return GestureDetector(
      onTapDown: (_) => _pauseStory(),
      onTapUp: (details) {
        final width = MediaQuery.of(context).size.width;
        final tapPosition = details.globalPosition.dx;

        if (tapPosition < width / 3) {
          _goToPreviousStory();
        } else if (tapPosition > (width * 2 / 3)) {
          _goToNextStory();
        } else {
          _resumeStory();
        }
      },
      onLongPress: () => _pauseStory(),
      onLongPressUp: () => _resumeStory(),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 200) {
          Navigator.pop(context);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Nội dung chính
          _buildStoryContent(story),

          // 2. Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. Thanh thời gian
          Positioned(
            top: 40,
            left: 8,
            right: 8,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return LinearPercentIndicator(
                  percent: _animationController.value,
                  lineHeight: 2.0,
                  progressColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.5),
                  padding: EdgeInsets.zero,
                );
              },
            ),
          ),

          // 4. Thông tin tác giả
          _buildStoryOverlay(story, author),

          // 5. Thông tin âm thanh
          _buildAudioInfo(story),

          // 6. Nút đóng
          Positioned(
            top: 45,
            right: 8,
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 5, color: Colors.black87)],
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    if (story.mediaType == 'image') {
      return CachedNetworkImage(
        imageUrl: story.mediaUrl,
        fit: BoxFit.cover,
        errorWidget: (c, u, e) => const Center(
          child: Text(
            'Lỗi tải ảnh',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    if (story.mediaType == 'video' && _videoController != null && _videoController!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    
    if (story.mediaType == 'text') {
      return Container(
        color: story.backgroundColor.isNotEmpty 
            ? Color(int.parse(story.backgroundColor.split('(0x')[1].split(')')[0], radix: 16)) 
            : Colors.blue,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              story.content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
              ),
            ),
          ),
        ),
      );
    }
    
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildStoryOverlay(StoryModel story, UserModel? author) {
    return Positioned(
      top: 55,
      left: 16,
      right: 16,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: (author?.avatar.isNotEmpty ?? false)
                ? CachedNetworkImageProvider(author!.avatar.first)
                : null,
            child: (author?.avatar.isEmpty ?? true)
                ? const Icon(Icons.person, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  author?.name ?? 'Người dùng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [Shadow(blurRadius: 5, color: Colors.black87)],
                  ),
                ),
                Text(
                  _formatStoryTime(story.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    shadows: const [Shadow(blurRadius: 5, color: Colors.black87)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioInfo(StoryModel story) {
    if (story.audioName == null || story.audioName!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 100,
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
            // Hình ảnh bài hát (quay tròn)
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
            
            // Tên bài hát
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
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black87),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Original audio',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          shadows: const [
                            Shadow(blurRadius: 4, color: Colors.black87),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Icon âm thanh
            Icon(
              Icons.audiotrack_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatStoryTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }
}