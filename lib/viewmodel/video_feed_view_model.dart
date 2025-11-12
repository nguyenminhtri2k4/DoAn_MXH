
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart'; // ✅ THÊM
import 'package:mangxahoi/request/user_request.dart'; // ✅ THÊM

class VideoFeedViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PostRequest _postRequest = PostRequest(); // ✅ THÊM
  final UserRequest _userRequest = UserRequest(); // ✅ THÊM
  final FirebaseAuth _auth = FirebaseAuth.instance; // ✅ THÊM

  List<PostModel> _videoPosts = [];
  List<PostModel> get videoPosts => _videoPosts;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // ✅ THÊM: Cache currentUserId
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  final Map<String, bool> _videoCheckCache = {};

  // ✅ THÊM: Constructor tự động init
  VideoFeedViewModel() {
    _init();
  }

  // ✅ THÊM: Hàm init tự động (giống GroupsViewModel)
  void _init() async {
    print("🔧 [VideoFeedVM] Bắt đầu khởi tạo...");
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        print("⚠️ [VideoFeedVM] Chưa đăng nhập Firebase Auth");
        _isLoading = false;
        notifyListeners();
        return;
      }

      print("🔍 [VideoFeedVM] Đang tìm user với UID: ${firebaseUser.uid}");
      final user = await _userRequest.getUserByUid(firebaseUser.uid);
      
      if (user != null) {
        _currentUserId = user.id;
        print("✅ [VideoFeedVM] Đã lấy currentUserId: $_currentUserId");
        
        // ✅ Tự động tải video posts
        await _loadVideoPosts();
      } else {
        print("⚠️ [VideoFeedVM] Không tìm thấy user trong Firestore");
        _isLoading = false;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      print("❌ [VideoFeedVM] Lỗi khi init: $e");
      print("❌ [VideoFeedVM] StackTrace: $stackTrace");
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ THÊM: Hàm tải posts và filter video tự động
  Future<void> _loadVideoPosts() async {
    if (_currentUserId == null) return;

    print("🔄 [VideoFeedVM] Bắt đầu tải video posts...");

    try {
      // Lấy tất cả posts (bạn có thể tùy chỉnh logic này)
      final allPosts = await _postRequest.getPostsPaginated(
        currentUserId: _currentUserId!,
        friendIds: [], // Có thể thêm friends nếu cần
        limit: 50, // Tải nhiều posts để filter
      );

      print("📥 [VideoFeedVM] Đã tải ${allPosts.length} posts, bắt đầu filter video...");
      await _filterVideoPostsInternal(allPosts);
    } catch (e, stackTrace) {
      print("❌ [VideoFeedVM] Lỗi khi tải posts: $e");
      print("❌ [VideoFeedVM] StackTrace: $stackTrace");
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ ĐỔI TÊN: filterVideoPosts → _filterVideoPostsInternal (private)
  Future<void> _filterVideoPostsInternal(List<PostModel> allPosts) async {
    List<PostModel> filtered = [];

    for (var post in allPosts) {
      if (post.mediaIds.isEmpty) continue;

      // 1. Kiểm tra cache trước
      if (_videoCheckCache.containsKey(post.id)) {
        if (_videoCheckCache[post.id] == true) {
          filtered.add(post);
        }
        continue;
      }

      // 2. Nếu chưa có trong cache, query Firestore
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
    print("✅ [VideoFeedVM] Đã filter được ${_videoPosts.length} video posts");
  }

  // ✅ THÊM: Public method để refresh thủ công
  Future<void> refreshVideoPosts() async {
    if (_currentUserId == null) {
      print("⚠️ [VideoFeedVM] refreshVideoPosts: currentUserId = null");
      return;
    }

    _isLoading = true;
    notifyListeners();
    await _loadVideoPosts();
  }

  // ✅ THÊM: Public method để filter từ danh sách posts có sẵn (cho HomeViewModel)
  Future<void> filterFromExistingPosts(List<PostModel> allPosts) async {
    _isLoading = true;
    notifyListeners();
    await _filterVideoPostsInternal(allPosts);
  }

  Future<bool> _checkIfPostHasVideo(List<String> mediaIds) async {
    if (mediaIds.isEmpty) return false;
    try {
      final idsToCheck = mediaIds.take(10).toList();
      final querySnapshot = await _firestore
          .collection('Media')
          .where(FieldPath.documentId, whereIn: idsToCheck)
          .get();

      for (var doc in querySnapshot.docs) {
        if (doc.data()['type'] == 'video') {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("❌ [VideoFeedVM] Lỗi kiểm tra video: $e");
      return false;
    }
  }

  void clearCache() {
    _videoCheckCache.clear();
    print("🗑️ [VideoFeedVM] Đã xóa cache");
  }

  // ✅ THÊM: Check xem đã init xong chưa
  bool get isInitialized => _currentUserId != null && !_isLoading;
}