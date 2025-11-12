
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/services/video_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_story.dart';
import 'package:mangxahoi/request/story_request.dart';
import 'package:mangxahoi/request/user_request.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PostRequest _postRequest = PostRequest();
  final StoryRequest _storyRequest = StoryRequest();
  final UserRequest _userRequest = UserRequest();

  List<PostModel> posts = [];
  bool isLoading = false;
  bool _isFetchingMore = false;
  bool hasMore = true;
  DocumentSnapshot? _lastDocument;

  Map<String, List<StoryModel>> _stories = {};
  UnmodifiableMapView<String, List<StoryModel>> get stories => UnmodifiableMapView(_stories);
  List<StreamSubscription> _storySubscriptions = [];

  // ✅ Biến để tránh init nhiều lần
  bool _isInitialized = false;
  bool _storyListenersInitialized = false;

  HomeViewModel() {
    _init();
  }

  // ✅ Hàm init tự động (KHÔNG gọi _initStoryListeners)
  void _init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    print('🔧 [HomeViewModel] Bắt đầu khởi tạo...');
    
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      try {
        final user = await _userRequest.getUserByUid(firebaseUser.uid)
            .timeout(const Duration(seconds: 5));
        
        if (user != null) {
          print('✅ [HomeViewModel] Đã lấy user: ${user.id}');
          // ✅ KHÔNG gọi _initStoryListeners ở đây
        } else {
          print('⚠️ [HomeViewModel] Không tìm thấy user trong Firestore');
        }
      } catch (e) {
        print('❌ [HomeViewModel] Lỗi khi init: $e');
      }
    } else {
      print('⚠️ [HomeViewModel] Chưa đăng nhập');
    }
  }

  // ✅ Khởi tạo story listeners (CHỈ 1 LẦN)
  void _initStoryListeners(UserModel currentUser) {
    if (_storyListenersInitialized) {
      print('⚠️ [HomeViewModel] Story listeners đã được khởi tạo, bỏ qua');
      return;
    }
    _storyListenersInitialized = true;

    print('🔄 [HomeViewModel] Bắt đầu lắng nghe story...');

    // Hủy các listener cũ
    for (var sub in _storySubscriptions) {
      sub.cancel();
    }
    _storySubscriptions.clear();
    _stories.clear();

    // Tạo danh sách người dùng cần lắng nghe
    final List<String> userIdsToListen = [
      currentUser.id,
      ...currentUser.friends,
    ].toSet().toList();

    print('👥 [HomeViewModel] Đang lắng nghe story của ${userIdsToListen.length} người dùng');

    // Tạo listener cho mỗi người dùng
    for (final userId in userIdsToListen) {
      final subscription = _storyRequest.getStoriesForUser(userId).listen(
        (userStories) {
          if (userStories.isNotEmpty) {
            userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _stories[userId] = userStories;
            print('✅ [HomeViewModel] Nhận được ${userStories.length} story từ user $userId');
          } else {
            _stories.remove(userId);
          }
          notifyListeners();
        },
        onError: (error) {
          print('❌ [HomeViewModel] Lỗi lắng nghe story của user $userId: $error');
        },
      );
      
      _storySubscriptions.add(subscription);
    }

    print('✅ [HomeViewModel] Đã thiết lập ${_storySubscriptions.length} story listeners');
    notifyListeners();
  }

  // ✅ listenToStories (CHỈ CHẠY 1 LẦN)
  void listenToStories(BuildContext context) {
    print('📞 [HomeViewModel] listenToStories được gọi');
    
    if (_storyListenersInitialized) {
      print('⚠️ [HomeViewModel] listenToStories: đã init rồi, bỏ qua');
      return;
    }

    final userService = context.read<UserService>();
    final currentUser = userService.currentUser;

    if (currentUser == null) {
      print('⚠️ [HomeViewModel] listenToStories: currentUser = null');
      return;
    }

    _initStoryListeners(currentUser);
  }

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

  @override
  void dispose() {
    print('🔧 [HomeViewModel] Disposing...');
    for (var sub in _storySubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}