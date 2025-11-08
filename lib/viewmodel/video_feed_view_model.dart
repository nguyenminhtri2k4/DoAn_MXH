import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_post.dart';

class VideoFeedViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PostModel> _videoPosts = [];
  List<PostModel> get videoPosts => _videoPosts;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Cache kết quả kiểm tra để không phải query lại Firestore liên tục cho cùng 1 bài viết
  final Map<String, bool> _videoCheckCache = {};

  // Hàm này nhận vào danh sách tất cả bài viết và lọc ra bài có video
  Future<void> filterVideoPosts(List<PostModel> allPosts) async {
    _isLoading = true;
    // notifyListeners(); // Có thể bật nếu muốn hiện loading mỗi khi làm mới

    List<PostModel> filtered = [];

    for (var post in allPosts) {
      // Nếu bài không có media thì bỏ qua ngay
      if (post.mediaIds.isEmpty) continue;

      // 1. Kiểm tra cache trước
      if (_videoCheckCache.containsKey(post.id)) {
        if (_videoCheckCache[post.id] == true) {
          filtered.add(post);
        }
        continue;
      }

      // 2. Nếu chưa có trong cache, query Firestore để kiểm tra
      bool hasVideo = await _checkIfPostHasVideo(post.mediaIds);

      // 3. Lưu vào cache
      _videoCheckCache[post.id] = hasVideo;

      if (hasVideo) {
        filtered.add(post);
      }
    }

    _videoPosts = filtered;
    _isLoading = false;
    notifyListeners();
  }

  // Kiểm tra kỹ: Query vào collection Media để xem 'type' có phải 'video' không
  Future<bool> _checkIfPostHasVideo(List<String> mediaIds) async {
    if (mediaIds.isEmpty) return false;
    try {
      // Firestore 'whereIn' giới hạn 10 phần tử. Lấy 10 media đầu tiên để kiểm tra.
      final idsToCheck = mediaIds.take(10).toList();
      final querySnapshot = await _firestore
          .collection('Media')
          .where(FieldPath.documentId, whereIn: idsToCheck)
          .get();

      for (var doc in querySnapshot.docs) {
        if (doc.data()['type'] == 'video') {
          return true; // Tìm thấy ít nhất 1 video
        }
      }
      return false;
    } catch (e) {
      debugPrint("Lỗi kiểm tra video: $e");
      return false;
    }
  }

  void clearCache() {
    _videoCheckCache.clear();
  }
}