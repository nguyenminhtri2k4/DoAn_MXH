
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheManager extends ChangeNotifier {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  final Map<String, VideoPlayerController> _controllers = {};
  final List<String> _loadingUrls = [];

  Future<VideoPlayerController> getControllerForUrl(String url) async {
    if (_controllers.containsKey(url)) {
      return _controllers[url]!;
    }

    if (_loadingUrls.contains(url)) {
      await Future.delayed(const Duration(milliseconds: 100));
      return getControllerForUrl(url);
    }

    _loadingUrls.add(url);

    final fileInfo = await _cacheManager.getFileFromCache(url);
    VideoPlayerController controller;

    if (fileInfo != null) {
      controller = VideoPlayerController.file(fileInfo.file);
    } else {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
      // Không cần gọi _cacheManager.downloadFile(url) ở đây
      // vì video_player sẽ tự xử lý việc tải
    }
    
    await controller.initialize();
    _controllers[url] = controller;
    _loadingUrls.remove(url);
    return controller;
  }

  void preloadVideos(List<String> urls) {
    for (final url in urls) {
      if (!_controllers.containsKey(url) && !_loadingUrls.contains(url)) {
        getControllerForUrl(url); 
      }
    }
  }

  // ==================== THÊM MỚI TẠI ĐÂY ====================
  /// Tạm dừng tất cả các video đang phát.
  void pauseAllVideos() {
    for (final controller in _controllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
    print('▶️ Tất cả video đã được tạm dừng.');
  }
  // ==========================================================

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}