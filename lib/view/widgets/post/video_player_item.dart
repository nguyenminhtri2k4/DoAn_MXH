// lib/view/widgets/post/video_player_item.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/services/video_cache_manager.dart'; // Đảm bảo đường dẫn đúng

// --- LỚP _VideoPlayerItem ---
class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerItem({super.key, required this.videoUrl}); // Sửa Key thành super.key

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

// --- LỚP _VideoPlayerItemState ---
class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isMuted = true; // Mặc định tắt tiếng
  bool _isScrubbing = false;
  Duration _scrubbingPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    // Thêm try-catch để xử lý lỗi tốt hơn
    try {
      _controller = await context
          .read<VideoCacheManager>()
          .getControllerForUrl(widget.videoUrl);

      // Chỉ khởi tạo nếu controller chưa được khởi tạo
      if (_controller != null && !_controller!.value.isInitialized) {
         _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
          if (mounted) {
            _controller!.setVolume(_isMuted ? 0.0 : 1.0);
            _controller!.setLooping(true);
            // Gọi setState để build lại UI sau khi khởi tạo xong
             setState(() {});
          }
        }).catchError((error) { // Bắt lỗi trong future
           if (mounted) {
             setState(() {
                _initializeVideoPlayerFuture = Future.error(error);
             });
           }
            print("Lỗi initialize video controller: $error");
        });
      } else if (_controller != null && _controller!.value.isInitialized) {
        // Nếu controller đã khởi tạo từ cache, đặt future là hoàn thành
         if (mounted) {
           setState(() {
             _initializeVideoPlayerFuture = Future.value(); // Đánh dấu là đã xong
           });
         }
      }

    } catch (e) {
      print("Lỗi lấy video controller từ cache: $e");
       if (mounted) {
         setState(() {
            _initializeVideoPlayerFuture = Future.error(e);
         });
       }
    }
  }


  @override
  void dispose() {
    // Chỉ dispose controller nếu nó được khởi tạo bởi widget này
    // VideoCacheManager sẽ quản lý việc dispose controller dùng chung
    // _controller?.dispose(); // Comment lại hoặc xóa dòng này nếu dùng CacheManager
    super.dispose();
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
    // Kiểm tra controller trước khi dùng FutureBuilder
    if (_controller == null && _initializeVideoPlayerFuture == null) {
      // Trường hợp controller chưa kịp lấy từ cache (rất hiếm)
      return Container(
        height: 250,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        // Luôn kiểm tra controller != null và isInitialized
        final isReady = _controller != null && _controller!.value.isInitialized;

        if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError && isReady) {
          // --- Hiển thị Video Player ---
          return VisibilityDetector(
            key: ValueKey('vis_${widget.videoUrl}'), // Key riêng cho VisibilityDetector
            onVisibilityChanged: (visibilityInfo) {
              if (!mounted || !isReady) return; // Kiểm tra lại
              final visibleFraction = visibilityInfo.visibleFraction;
              try {
                if (visibleFraction >= 0.7) { // Giảm ngưỡng một chút
                  if (!_controller!.value.isPlaying) {
                     _controller!.play();
                  }
                } else {
                  if (_controller!.value.isPlaying) {
                     _controller!.pause();
                  }
                }
              } catch (e) {
                 print("Lỗi khi play/pause video visibility: $e");
              }
            },
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!mounted || !isReady) return;
                      setState(() {
                        _controller!.value.isPlaying
                            ? _controller!.pause()
                            : _controller!.play();
                      });
                    },
                    child: VideoPlayer(_controller!),
                  ),
                  // Chỉ build controls nếu controller đã sẵn sàng
                  _buildControlsOverlay(_controller!),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          // --- Hiển thị Lỗi ---
           return Container(
              height: 250,
              color: Colors.black,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  const Text('Không thể tải video', style: TextStyle(color: Colors.white)),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
                     child: Text(
                       '${snapshot.error}',
                       style: const TextStyle(color: Colors.grey, fontSize: 10),
                       textAlign: TextAlign.center,
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                      ),
                   ),
                ],
              )
          );
        } else {
          // --- Hiển thị Loading ---
          return Container(
            height: 250,
            color: Colors.black,
            child: const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          );
        }
      },
    );
  }

  // --- Widget _buildControlsOverlay ---
  Widget _buildControlsOverlay(VideoPlayerController controller) {
     // Không cần kiểm tra isInitialized ở đây nữa vì đã kiểm tra ở hàm build
    return Stack(
      children: [
        // --- Nút Play/Pause ở giữa ---
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, VideoPlayerValue value, child) {
            // Chỉ hiển thị nút Play khi video không chạy VÀ controller đã sẵn sàng
            final shouldShowPlayButton = !value.isPlaying && value.isInitialized;
            return AnimatedOpacity(
              opacity: shouldShowPlayButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Center(
                child: GestureDetector(
                   // Chỉ cho phép tap khi nút hiển thị
                  onTap: shouldShowPlayButton ? () {
                    if (!mounted || !controller.value.isInitialized) return;
                    // Không cần setState vì ValueListenableBuilder sẽ tự cập nhật
                    controller.play();
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    // Ẩn Icon nếu không nên hiển thị nút
                    child: shouldShowPlayButton
                        ? const Icon(Icons.play_arrow, color: Colors.white, size: 50.0)
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        ),
        // --- Hiển thị thời gian khi tua ---
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
                // Đảm bảo duration không âm
                '${_formatDuration(_scrubbingPosition)} / ${_formatDuration(controller.value.duration > Duration.zero ? controller.value.duration : Duration.zero)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        // --- Thanh điều khiển dưới cùng ---
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
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.0)
                ],
                stops: const [0.0, 0.9] // Gradient mờ dần ở trên cao hơn
              ),
            ),
            child: Row(
              children: [
                // --- Thanh Progress ---
                Expanded(
                  child: SizedBox(
                    height: 24, // Tăng chiều cao vùng chạm
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
                            final newPositionRatio = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                             // Đảm bảo duration không âm
                             final duration = controller.value.duration > Duration.zero ? controller.value.duration : Duration.zero;
                            final newPosition = duration * newPositionRatio;
                            setState(() {
                              _scrubbingPosition = newPosition;
                            });
                          },
                          onHorizontalDragEnd: (details) {
                            if (!controller.value.isInitialized) return;
                            controller.seekTo(_scrubbingPosition);
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) {
                                setState(() {
                                  _isScrubbing = false;
                                });
                              }
                            });
                          },
                          child: Center(
                             child: Padding( // Thêm Padding để thanh progress không sát viền
                               padding: const EdgeInsets.symmetric(horizontal: 4.0),
                               child: VideoProgressIndicator(
                                controller,
                                allowScrubbing: true,
                                padding: EdgeInsets.zero, // Padding đã có ở ngoài
                                colors: const VideoProgressColors(
                                  playedColor: Colors.white,
                                  bufferedColor: Colors.white70,
                                  backgroundColor: Colors.white24,
                                ),
                               ),
                             ),
                           ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // --- Nút Mute/Unmute ---
                GestureDetector(
                  onTap: () {
                    if (!mounted || !controller.value.isInitialized) return;
                    setState(() {
                      _isMuted = !_isMuted;
                      controller.setVolume(_isMuted ? 0.0 : 1.0);
                    });
                  },
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                // --- (Optional) Nút Fullscreen ---
                 // IconButton(
                 //   icon: Icon(Icons.fullscreen, color: Colors.white, size: 28),
                 //   onPressed: () {
                 //     // TODO: Implement fullscreen logic
                 //     // Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenVideoPlayer(controller: controller)));
                 //   },
                 // ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} // Kết thúc _VideoPlayerItemState