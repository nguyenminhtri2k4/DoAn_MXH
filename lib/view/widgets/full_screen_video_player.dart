import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoPlayer({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true; // Chỉ quản lý ẩn/hiện thanh dưới
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
        _startHideControlsTimer(); // Bắt đầu ẩn thanh dưới sau 3 giây
      });
  }

  void _startHideControlsTimer() {
    _cancelHideControlsTimer();
    _hideControlsTimer = Timer(Duration(seconds: 3), () {
      // Chỉ ẩn thanh dưới nếu video đang chạy và widget còn tồn tại
      if (_controller.value.isPlaying && mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _cancelHideControlsTimer() {
    _hideControlsTimer?.cancel();
  }

  // Hàm này giờ chỉ toggle thanh dưới
  void _toggleControls() {
     if (!mounted) return;
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideControlsTimer();
      } else {
        _cancelHideControlsTimer();
      }
    });
  }


  @override
  void dispose() {
    _cancelHideControlsTimer();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls, // Nhấn để ẩn/hiện thanh dưới
        child: Center(
          child: _controller.value.isInitialized
              ? Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    // Video player
                    FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),

                    // --- SỬA Ở ĐÂY: Nút Back LUÔN hiển thị ---
                    // Đặt Positioned ở ngoài AnimatedOpacity
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                          // Giảm độ mờ nền để dễ nhìn hơn
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.4), // Tăng độ mờ một chút
                            padding: EdgeInsets.all(8),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    // ---------------------------------------------

                    // Thanh dưới cùng (vẫn ẩn/hiện)
                    AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 50 + MediaQuery.of(context).padding.bottom,
                          color: Colors.black.withOpacity(0.4),
                          // Không có nút hay thanh tua gì ở đây cả
                        ),
                      ),
                    ),
                  ],
                )
              : CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}