
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_group.dart';
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
import 'package:mangxahoi/utils/post_privacy_helper.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PostRequest _postRequest = PostRequest();
  final StoryRequest _storyRequest = StoryRequest();
  final UserRequest _userRequest = UserRequest();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PostModel> posts = [];
  bool isLoading = false;
  bool _isFetchingMore = false;
  bool hasMore = true;
  DocumentSnapshot? _lastDocument;

  Map<String, GroupModel> _groupsCache = {};
  Set<String> _blockedUserIds = {};

  Map<String, List<StoryModel>> _stories = {};
  UnmodifiableMapView<String, List<StoryModel>> get stories => UnmodifiableMapView(_stories);
  List<StreamSubscription> _storySubscriptions = [];

  bool _isInitialized = false;
  bool _storyListenersInitialized = false;
  bool _isDisposed = false;

  HomeViewModel() {
    _init();
  }

  @override
  void dispose() {
    print('🔧 [HomeViewModel] Disposing...');
    _isDisposed = true;
    for (var sub in _storySubscriptions) {
      sub.cancel();
    }
    _storySubscriptions.clear();
    _groupsCache.clear();
    _stories.clear();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void _init() async {
    if (_isInitialized || _isDisposed) return;
    _isInitialized = true;

    print('🔧 [HomeViewModel] Bắt đầu khởi tạo...');
    
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      try {
        final user = await _userRequest.getUserByUid(firebaseUser.uid)
            .timeout(const Duration(seconds: 5));
        
        if (_isDisposed) return;
        
        if (user != null) {
          print('✅ [HomeViewModel] Đã lấy user: ${user.id}');
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

  void _initStoryListeners(UserModel currentUser) {
    if (_storyListenersInitialized || _isDisposed) {
      print('⚠️ [HomeViewModel] Story listeners đã được khởi tạo hoặc disposed, bỏ qua');
      return;
    }
    _storyListenersInitialized = true;

    print('🔄 [HomeViewModel] Bắt đầu lắng nghe story...');

    for (var sub in _storySubscriptions) {
      sub.cancel();
    }
    _storySubscriptions.clear();
    _stories.clear();

    final List<String> userIdsToListen = [
      currentUser.id,
      ...currentUser.friends,
    ].toSet().toList();

    print('👥 [HomeViewModel] Đang lắng nghe story của ${userIdsToListen.length} người dùng');

    for (final userId in userIdsToListen) {
      final subscription = _storyRequest.getStoriesForUser(userId).listen(
        (userStories) {
          if (_isDisposed) return;
          
          if (userStories.isNotEmpty) {
            userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _stories[userId] = userStories;
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

  void listenToStories(BuildContext context) {
    print('📞 [HomeViewModel] listenToStories được gọi');
    
    if (_storyListenersInitialized || _isDisposed) {
      print('⚠️ [HomeViewModel] listenToStories: đã init hoặc disposed, bỏ qua');
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

  Future<GroupModel?> _getGroupInfo(String groupId) async {
    if (_groupsCache.containsKey(groupId)) {
      return _groupsCache[groupId];
    }
    try {
      final doc = await _firestore.collection('Group').doc(groupId).get();
      if (doc.exists) {
        final group = GroupModel.fromMap(doc.id, doc.data()!);
        _groupsCache[groupId] = group;
        return group;
      }
    } catch (e) {
      print('❌ Lỗi khi lấy thông tin nhóm $groupId: $e');
    }
    return null;
  }
  
  Future<void> _fetchBlockedIds(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('Blocked')
          .where('blockerId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'active')
          .get();

      _blockedUserIds = snapshot.docs
          .map((doc) => doc.data()['blockedId'] as String)
          .toSet();
          
      print('[HomeViewModel] Đã nạp ${_blockedUserIds.length} ID người dùng bị chặn.');

    } catch (e) {
      print("❌ Lỗi khi nạp danh sách chặn: $e");
      _blockedUserIds = {};
    }
  }

  // lib/viewmodel/home_view_model.dart

    List<PostModel> _filterPostsByPrivacy(
      List<PostModel> allPosts,
      UserModel currentUser,
      Map<String, GroupModel> groupsMap,
    ) {
      // Đầu tiên gọi helper cũ để lọc theo các tiêu chí cơ bản (chặn, privacy cá nhân)
      List<PostModel> filtered = PostPrivacyHelper.filterPosts(
        posts: allPosts,
        currentUser: currentUser,
        groupsMap: groupsMap,
        blockedUserIds: _blockedUserIds,
      );

      // Sau đó lọc thêm điều kiện về Nhóm riêng tư
      return filtered.where((post) {
        // Nếu bài đăng không thuộc nhóm nào, cho phép hiển thị (dựa trên visibility cá nhân)
        if (post.groupId == null || post.groupId!.isEmpty) return true;

        final group = groupsMap[post.groupId];
        if (group == null) return false; // Không tìm thấy thông tin nhóm thì ẩn để an toàn

        // Kiểm tra cài đặt nhóm có phải là riêng tư không
        // Giả sử trong settings của GroupModel có field 'privacy'
        bool isPrivateGroup = group.settings['privacy'] == 'private';

        if (isPrivateGroup) {
          // Nếu là nhóm riêng tư, chỉ cho phép thành viên hoặc quản lý xem
          bool isMember = group.members.contains(currentUser.id);
          bool isManager = group.managers.contains(currentUser.id);
          bool isOwner = group.ownerId == currentUser.id;

          return isMember || isManager || isOwner;
        }

        return true; // Nhóm công khai (public) thì hiển thị bình thường
      }).toList();
    }

  void _preloadVideosForPosts(BuildContext context, List<PostModel> newPosts) {
    if (_isDisposed) return;
    
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
    if (_isDisposed) return;
    
    _lastDocument = null;
    hasMore = true;
    posts.clear();
    _blockedUserIds.clear();
    
    await fetchInitialPosts(context);
  }

  Future<void> fetchInitialPosts(BuildContext context) async {
    if (isLoading || _isDisposed) return;
    
    isLoading = true;
    notifyListeners();

    try {
      final userService = context.read<UserService>();
      if (userService.currentUser == null) {
        throw Exception("User not logged in");
      }
      final currentUser = userService.currentUser!;
      
      await _fetchBlockedIds(currentUser.id);

      if (_isDisposed) return;

      final newPosts = await _postRequest.getPostsPaginated(
        currentUserId: currentUser.id,
        friendIds: currentUser.friends,
        limit: 10,
      );

      if (_isDisposed) return;

      if (newPosts.isNotEmpty) {
        final groupsMap = context.read<FirestoreListener>().groupsMap;
        
        final filteredPosts = _filterPostsByPrivacy(
          newPosts, 
          currentUser, 
          groupsMap,
        );

        _lastDocument = await _firestore.collection('Post').doc(newPosts.last.id).get();
        posts = filteredPosts;
        hasMore = newPosts.length == 10;
        
        _preloadVideosForPosts(context, filteredPosts);
      } else {
        hasMore = false;
      }
    } catch (e) {
      print('❌ Lỗi khi tải bài viết ban đầu: $e');
    } finally {
      if (!_isDisposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchMorePosts(BuildContext context) async {
    if (_isFetchingMore || !hasMore || _isDisposed) return;
    
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

      if (_isDisposed) return;

      if (newPosts.isNotEmpty) {
        final groupsMap = context.read<FirestoreListener>().groupsMap;

        final filteredPosts = _filterPostsByPrivacy(
          newPosts, 
          currentUser, 
          groupsMap,
        );

        _lastDocument = await _firestore.collection('Post').doc(newPosts.last.id).get();
        posts.addAll(filteredPosts);
        hasMore = newPosts.length == 10;
        
        _preloadVideosForPosts(context, filteredPosts);
      } else {
        hasMore = false;
      }
    } catch (e) {
      print('❌ Lỗi khi tải thêm bài viết: $e');
    } finally {
      if (!_isDisposed) {
        _isFetchingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> signOut(BuildContext context) async {
    if (_isDisposed) return;
    
    try {
      context.read<VideoCacheManager>().pauseAllVideos();
      await _auth.signOut();
      
      if (context.mounted && !_isDisposed) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      print('❌ Lỗi khi đăng xuất: $e');
    }
  }
}