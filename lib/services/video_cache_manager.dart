// lib/services/video_cache_manager.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoCacheManager extends ChangeNotifier {
  final Map<String, VideoPlayerController> _cache = {};
  final int _cacheSize = 10; // Giữ 10 video trong bộ nhớ cache

  // Lấy hoặc tạo và khởi tạo một controller
  Future<VideoPlayerController> getControllerForUrl(String url) async {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    // Nếu cache đầy, loại bỏ controller cũ nhất không được sử dụng
    if (_cache.length >= _cacheSize) {
      final oldestUrl = _cache.keys.first;
      final controllerToRemove = _cache.remove(oldestUrl);
      await controllerToRemove?.dispose();
      print('♻️ Disposed video (cache full): $oldestUrl');
    }

    // Tạo controller mới và bắt đầu khởi tạo
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _cache[url] = controller;

    // Bắt đầu initialize và trả về future, widget sẽ xử lý phần còn lại
    await controller.initialize();
    print('✅ Initialized and cached video: $url');
    return controller;
  }

  // Tải trước một danh sách video
  void preloadVideos(List<String> urls) {
    for (final url in urls) {
      if (!_cache.containsKey(url)) {
        // Gọi getControllerForUrl nhưng không await để nó chạy ngầm
        getControllerForUrl(url);
      }
    }
  }

  // Dọn dẹp các controller không còn trong danh sách hiển thị
  Future<void> cleanUp(List<String> visibleUrls) async {
    final urlsToRemove = <String>[];
    for (final url in _cache.keys) {
      if (!visibleUrls.contains(url)) {
        urlsToRemove.add(url);
      }
    }

    for (final url in urlsToRemove) {
      final controller = _cache.remove(url);
      await controller?.dispose();
      print('♻️ Disposed video (no longer visible): $url');
    }
  }

  @override
  void dispose() {
    print('Disposing all video controllers...');
    for (var controller in _cache.values) {
      controller.dispose();
    }
    _cache.clear();
    super.dispose();
  }
}