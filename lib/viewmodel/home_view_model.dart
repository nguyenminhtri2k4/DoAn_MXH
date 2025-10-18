
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/services/video_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PostRequest _postRequest = PostRequest();
  
  List<PostModel> posts = [];
  bool isLoading = false;
  bool _isFetchingMore = false;
  bool hasMore = true;
  DocumentSnapshot? _lastDocument;

  // Xóa lời gọi hàm fetchInitialPosts() khỏi constructor
  HomeViewModel();

  void _preloadVideosForPosts(BuildContext context, List<PostModel> newPosts) {
    // Sử dụng try-catch để an toàn hơn khi truy cập Provider
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
      print("Lỗi khi truy cập provider để preload video: $e");
    }
  }

  Future<void> fetchInitialPosts(BuildContext context) async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      final newPosts = await _postRequest.getPostsPaginated(limit: 10);
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
    // Không cần notifyListeners() ở đây để tránh giao diện nhảy lên khi đang tải ở cuối
    
    try {
      final newPosts = await _postRequest.getPostsPaginated(limit: 10, startAfter: _lastDocument);
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

  Future<void> signOut(BuildContext context) async {
    try {
      context.read<VideoCacheManager>().dispose();
      await _auth.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      print('❌ Lỗi khi đăng xuất: $e');
    }
  }
}