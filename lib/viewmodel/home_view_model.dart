
import 'dart:async'; // Thêm
import 'dart:collection'; // Thêm
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/services/video_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/model/model_user.dart'; // Thêm

// --- IMPORT MỚI CHO STORY ---
import 'package:mangxahoi/model/model_story.dart';
import 'package:mangxahoi/request/story_request.dart';
// -----------------------------

class HomeViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PostRequest _postRequest = PostRequest();
  
  // --- THÊM STORY REQUEST ---
  final StoryRequest _storyRequest = StoryRequest();
  // -------------------------

  List<PostModel> posts = [];
  bool isLoading = false;
  bool _isFetchingMore = false;
  bool hasMore = true;
  DocumentSnapshot? _lastDocument;

  // --- THÊM BIẾN QUẢN LÝ STORY ---
  Map<String, List<StoryModel>> _stories = {};
  /// Dùng UnmodifiableMapView để ngăn UI sửa đổi trực tiếp
  UnmodifiableMapView<String, List<StoryModel>> get stories => UnmodifiableMapView(_stories);
  List<StreamSubscription> _storySubscriptions = [];
  // ------------------------------

  // Giữ constructor rỗng của bạn
  HomeViewModel();

  // Hàm _preloadVideosForPosts của bạn
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

  // Hàm refreshPosts của bạn
  Future<void> refreshPosts(BuildContext context) async {
    _lastDocument = null;
    hasMore = true;
    posts.clear();
    await fetchInitialPosts(context);
    // Tải lại story khi refresh
    listenToStories(context); 
  }

  // --- HÀM  ĐỂ LẮNG NGHE STORY ---
  
  void listenToStories(BuildContext context) {
    final userService = context.read<UserService>();
    final currentUser = userService.currentUser;

    if (currentUser == null) return;

    // Hủy các listener cũ
    for (var sub in _storySubscriptions) {
      sub.cancel();
    }
    _storySubscriptions.clear();
    _stories.clear();
    print('🔄 Bắt đầu lắng nghe story...');

    // ✅ TẠO DANH SÁCH NGƯỜI DÙNG CẦN LẮNG NGHE (CHÍNH MÌNH + BẠN BÈ)
    final List<String> userIdsToListen = [
      currentUser.id, // Chính mình
      ...currentUser.friends, // Tất cả bạn bè
    ].toSet().toList(); // Loại bỏ trùng lặp

    print('👥 Đang lắng nghe story của ${userIdsToListen.length} người dùng');

    // ✅ TẠO LISTENER CHO MỖI NGƯỜI DÙNG
    for (final userId in userIdsToListen) {
      final subscription = _storyRequest.getStoriesForUser(userId).listen(
        (userStories) {
          if (userStories.isNotEmpty) {
            // Sắp xếp story theo thời gian mới nhất
            userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _stories[userId] = userStories;
            print('✅ Nhận được ${userStories.length} story từ user $userId');
          } else {
            _stories.remove(userId);
            print('⚠️ Không còn story nào từ user $userId');
          }
          notifyListeners();
        },
        onError: (error) {
          print('❌ Lỗi lắng nghe story của user $userId: $error');
        },
      );
      
      _storySubscriptions.add(subscription);
    }

    print('✅ Đã thiết lập ${_storySubscriptions.length} story listeners');
    notifyListeners();
  }
  // ---------------------------------

  // Hàm fetchInitialPosts của bạn
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

  // Hàm fetchMorePosts của bạn
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

  // Hàm signOut của bạn
  Future<void> signOut(BuildContext context) async {
    try {
      context.read<VideoCacheManager>().pauseAllVideos();
      await _auth.signOut();
      
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      print('❌ Lỗi khi đăng xuất: $e');
    }
  }

  // --- THÊM HÀM DISPOSE ĐỂ HỦY LISTENER ---
  @override
  void dispose() {
    for (var sub in _storySubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
  // ------------------------------------
}