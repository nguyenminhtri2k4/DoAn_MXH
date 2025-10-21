
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/services/video_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/services/user_service.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PostRequest _postRequest = PostRequest();
  
  List<PostModel> posts = [];
  bool isLoading = false;
  bool _isFetchingMore = false;
  bool hasMore = true;
  DocumentSnapshot? _lastDocument;

  HomeViewModel();

  void _preloadVideosForPosts(BuildContext context, List<PostModel> newPosts) {
    try {
      final videoCacheManager = context.read<VideoCacheManager>();
      final firestoreListener = context.read<FirestoreListener>();
      
      final videoUrls = newPosts
          .where((post) => post.mediaIds.isNotEmpty)
          .map((post) {
            final media = firestoreListener.getMediaById(post.mediaIds.first);
            return (media != null && media.type == 'video') ? media.url : null;
          })
          .where((url) => url != null)
          .cast<String>()
          .toList();

      if (videoUrls.isNotEmpty) {
        videoCacheManager.preloadVideos(videoUrls);
      }
    } catch (e) {
      if (e is ProviderNotFoundException || e.toString().contains('VideoCacheManager was used after being disposed')) {
         print("⚠️ VideoCacheManager không khả dụng hoặc đã bị dispose, bỏ qua preload video.");
      } else {
        print("Lỗi khi truy cập provider để preload video: $e");
      }
    }
  }

  Future<void> refreshPosts(BuildContext context) async {
    _lastDocument = null;
    hasMore = true;
    posts.clear();
    await fetchInitialPosts(context);
  }

  Future<void> fetchInitialPosts(BuildContext context) async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      final userService = context.read<UserService>();
      if (userService.currentUser == null) {
        throw Exception("User not logged in");
      }
      final currentUser = userService.currentUser!;

      final newPosts = await _postRequest.getPostsPaginated(
        currentUserId: currentUser.id,
        friendIds: currentUser.friends,
        limit: 10,
      );

      if (newPosts.isNotEmpty) {
        _lastDocument = await FirebaseFirestore.instance.collection('Post').doc(newPosts.last.id).get();
        posts = newPosts;
        hasMore = newPosts.length == 10;
        
        _preloadVideosForPosts(context, newPosts);
      } else {
        hasMore = false;
      }
    } catch (e) {
      print('❌ Lỗi khi tải bài viết ban đầu: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMorePosts(BuildContext context) async {
    if (_isFetchingMore || !hasMore) return;
    _isFetchingMore = true;
    
    try {
      final userService = context.read<UserService>();
      if (userService.currentUser == null) {
        throw Exception("User not logged in");
      }
      final currentUser = userService.currentUser!;

      final newPosts = await _postRequest.getPostsPaginated(
        currentUserId: currentUser.id,
        friendIds: currentUser.friends,
        limit: 10, 
        startAfter: _lastDocument,
      );

      if (newPosts.isNotEmpty) {
        _lastDocument = await FirebaseFirestore.instance.collection('Post').doc(newPosts.last.id).get();
        posts.addAll(newPosts);
        hasMore = newPosts.length == 10;
        
        _preloadVideosForPosts(context, newPosts);
      } else {
        hasMore = false;
      }
    } catch (e) {
      print('❌ Lỗi khi tải thêm bài viết: $e');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // ==================== SỬA LỖI TẠI ĐÂY ====================
  Future<void> signOut(BuildContext context) async {
    try {
      // Dừng tất cả các video trước khi đăng xuất
      context.read<VideoCacheManager>().pauseAllVideos();

      await _auth.signOut();
      
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      print('❌ Lỗi khi đăng xuất: $e');
    }
  }
}