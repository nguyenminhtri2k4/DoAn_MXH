import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/group_request.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/request/friend_request_manager.dart';
import 'package:mangxahoi/utils/post_privacy_helper.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchUserResult {
  final UserModel user;
  final String status;

  SearchUserResult({required this.user, required this.status});
}

class SearchViewModel extends ChangeNotifier {
  final UserRequest _userRequest = UserRequest();
  final GroupRequest _groupRequest = GroupRequest();
  final PostRequest _postRequest = PostRequest();
  final FriendRequestManager _requestManager = FriendRequestManager();
  final TextEditingController searchController = TextEditingController();

  List<UserModel> _allUsersCache = [];
  
  List<SearchUserResult> _searchResults = [];
  List<GroupModel> _groupResults = [];
  List<PostModel> _postResults = [];

  List<String> _friendIds = [];
  Set<String> _blockedUserIds = {};
  UserModel? _currentUserModel;

  bool _isLoading = false;
  String? _errorMessage;
  String? _actionError;
  Timer? _debounce;
  bool _isDisposed = false;

  String? _currentUserId;

  List<SearchUserResult> get searchResults => _searchResults;
  List<GroupModel> get groupResults => _groupResults;
  List<PostModel> get postResults => _postResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;
  String? get currentUserId => _currentUserId;

  SearchViewModel() {
    print('🚀 [SearchViewModel] Initializing...');
    _initializeData();
    searchController.addListener(_onSearchChanged);
    _loadAllUsersCache();
  }

  @override
  void dispose() {
    print('🧹 [SearchViewModel] Disposing...');
    _isDisposed = true;

    _debounce?.cancel();
    _debounce = null;

    searchController.removeListener(_onSearchChanged);
    searchController.dispose();

    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ [SearchViewModel] Error notifying listeners: $e');
      }
    }
  }

  void _initializeData() async {
    if (_isDisposed) return;

    try {
      print('🔍 [SearchViewModel] Getting current user...');
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null && !_isDisposed) {
        final uid = firebaseUser.uid;
        print('📧 [SearchViewModel] Firebase user UID: $uid');
        
        final user = await _userRequest.getUserByUid(uid);

        if (!_isDisposed && user != null) {
          _currentUserId = user.id;
          _currentUserModel = user;
          print('✅ [SearchViewModel] Current user ID: $_currentUserId');

          await _fetchPrivacyData(uid);
        } else {
          print('⚠️ [SearchViewModel] User not found in Firestore');
        }
      } else {
        print('⚠️ [SearchViewModel] No Firebase user logged in');
      }
    } catch (e) {
      print('❌ [SearchViewModel] Error initializing data: $e');
    }
  }

  Future<void> _fetchPrivacyData(String uid) async {
    if (_isDisposed) return;
    try {
      print('🔒 [SearchViewModel] Fetching privacy data (Friends & Blocked)...');

      final q1 = await FirebaseFirestore.instance
          .collection('Friend')
          .where('user1', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      final q2 = await FirebaseFirestore.instance
          .collection('Friend')
          .where('user2', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      final friends1 = q1.docs.map((d) => d['user2'] as String).toList();
      final friends2 = q2.docs.map((d) => d['user1'] as String).toList();
      
      _friendIds = [...friends1, ...friends2].toSet().toList();
      print('   👥 Friends count: ${_friendIds.length}');

      final blockQuery = await FirebaseFirestore.instance
          .collection('Block')
          .where('blockerId', isEqualTo: uid)
          .get();
      
      _blockedUserIds = blockQuery.docs.map((d) => d['blockedId'] as String).toSet();
      print('   🚫 Blocked count: ${_blockedUserIds.length}');

    } catch (e) {
      print('⚠️ [SearchViewModel] Error fetching privacy data: $e');
    }
  }

  Future<void> _loadAllUsersCache() async {
    if (_isDisposed) return;

    _isLoading = true;
    _safeNotifyListeners();

    try {
      print('📥 [SearchViewModel] Loading users cache...');
      _allUsersCache = await _userRequest.getAllUsersForCache(limit: 1000);

      if (_isDisposed) return;
      _errorMessage = null;
    } catch (e) {
      print('❌ [SearchViewModel] Error loading user cache: $e');
      if (!_isDisposed) {
        _errorMessage = 'Lỗi tải dữ liệu cơ sở. Vui lòng thử lại sau.';
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  void _onSearchChanged() {
    if (_isDisposed) return;

    final query = searchController.text.trim();

    _debounce?.cancel();
    _debounce = null;

    if (query.isEmpty) {
      _searchResults = [];
      _groupResults = [];
      _postResults = [];
      _errorMessage = null;
      _safeNotifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        print('⏱️ [SearchViewModel] Debounce triggered, starting search...');
        _searchAll(query);
      }
    });
  }

  void _searchAll(String query) async {
    if (_isDisposed) return;

    if (query.isEmpty) {
      _searchResults = [];
      _groupResults = [];
      _postResults = [];
      _errorMessage = null;
      _safeNotifyListeners();
      return;
    }

    if (_currentUserId == null) {
      _errorMessage = 'Vui lòng đăng nhập để tìm kiếm';
      _safeNotifyListeners();
      return;
    }

    print('🔍 [SearchViewModel] Starting search for: "$query"');
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      print('📡 [SearchViewModel] Searching Users, Groups & Posts in parallel...');

      final results = await Future.wait([
        _searchUsersLocal(query),
        _searchGroups(query),
        _searchPosts(query),
      ]);

      if (_isDisposed) return;

      _searchResults = results[0] as List<SearchUserResult>;
      _groupResults = results[1] as List<GroupModel>;
      _postResults = results[2] as List<PostModel>;

      print('📊 [SearchViewModel] Search completed:');
      print('   👥 Users: ${_searchResults.length}');
      print('   👥 Groups: ${_groupResults.length}');
      print('   📝 Posts: ${_postResults.length}');

      if (_searchResults.isEmpty && _groupResults.isEmpty && _postResults.isEmpty) {
        _errorMessage = 'Không tìm thấy kết quả nào khớp với "$query".';
      } else {
        _errorMessage = null;
      }
    } catch (e) {
      print('❌ [SearchViewModel] Search error: $e');
      if (!_isDisposed) {
        _errorMessage = 'Có lỗi xảy ra khi tìm kiếm.';
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<List<SearchUserResult>> _searchUsersLocal(String query) async {
    if (_isDisposed) return [];
    try {
      final lowerCaseQuery = query.toLowerCase();
      final filteredUsers = _allUsersCache.where((user) {
        return user.name.toLowerCase().contains(lowerCaseQuery) ||
            user.email.toLowerCase().contains(lowerCaseQuery) ||
            user.phone.contains(lowerCaseQuery);
      }).toList();

      List<SearchUserResult> resultsWithStatus = [];
      for (var user in filteredUsers) {
        if (_isDisposed) return [];
        final status = await _requestManager.getFriendshipStatus(
          _currentUserId!,
          user.id,
        );
        resultsWithStatus.add(SearchUserResult(user: user, status: status));
      }
      return resultsWithStatus;
    } catch (e) {
      print('❌ User search error: $e');
      return [];
    }
  }

  Future<List<GroupModel>> _searchGroups(String query) async {
    if (_isDisposed) return [];
    try {
      final allGroups = await _groupRequest.searchGroups(query);
      return allGroups.where((group) => group.type == 'post').toList();
    } catch (e) {
      print('❌ Group search error: $e');
      return [];
    }
  }

  Future<List<PostModel>> _searchPosts(String query) async {
    if (_isDisposed || _currentUserId == null || _currentUserModel == null) return [];

    try {
      print('📝 [SearchViewModel] Searching posts...');
      
      final allRecentPosts = await _postRequest.getPostsForSearch(limit: 500);

      if (_isDisposed) return [];

      final queryLower = query.toLowerCase();
      final contentMatches = allRecentPosts.where((post) {
        return post.content.toLowerCase().contains(queryLower);
      }).toList();

      if (contentMatches.isEmpty) {
        return [];
      }

      print('   Found ${contentMatches.length} posts matching content. Checking privacy...');

      final groupIds = contentMatches
          .where((p) => p.groupId != null && p.groupId!.isNotEmpty)
          .map((p) => p.groupId!)
          .toSet();

      Map<String, GroupModel> groupsMap = {};
      
      for (var gid in groupIds) {
        if (_isDisposed) return [];
        try {
          final group = await _groupRequest.getGroupById(gid);
          if (group != null) {
            groupsMap[gid] = group;
          }
        } catch (_) {}
      }

      final visiblePosts = PostPrivacyHelper.filterPosts(
        posts: contentMatches,
        currentUser: _currentUserModel!,
        groupsMap: groupsMap,
        blockedUserIds: _blockedUserIds,
      );

      final finalPosts = visiblePosts.where((post) {
        if (post.visibility == 'friends') {
          final isFriend = _friendIds.contains(post.authorId);
          final isMe = post.authorId == _currentUserId;
          return isFriend || isMe;
        }
        return true;
      }).toList();

      print('✅ [SearchViewModel] Found ${finalPosts.length} visible posts');
      return finalPosts;

    } catch (e) {
      print('❌ [SearchViewModel] Post search error: $e');
      return [];
    }
  }

  Future<bool> sendFriendRequest(String toUserId) async {
    if (_currentUserId == null || _isDisposed) return false;
    _actionError = null;
    try {
      await _requestManager.sendRequest(_currentUserId!, toUserId);
      if (_isDisposed) return false;
      final index = _searchResults.indexWhere((r) => r.user.id == toUserId);
      if (index != -1) {
        _searchResults[index] = SearchUserResult(
          user: _searchResults[index].user,
          status: 'pending_sent',
        );
        _safeNotifyListeners();
      }
      return true;
    } catch (e) {
      if (!_isDisposed) {
        _actionError = e.toString().replaceAll("Exception: ", "");
        _safeNotifyListeners();
      }
      return false;
    }
  }

  Future<String> joinGroup(String groupId) async {
    if (_currentUserId == null || _isDisposed) {
      _actionError = 'Vui lòng đăng nhập để tham gia nhóm';
      _safeNotifyListeners();
      return 'error';
    }
    try {
      await _groupRequest.joinGroup(groupId, _currentUserId!);
      if (_isDisposed) return 'error';

      final index = _groupResults.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        final group = _groupResults[index];
        if (group.status != 'private') {
           _groupResults[index] = GroupModel(
            id: group.id,
            ownerId: group.ownerId,
            name: group.name,
            description: group.description,
            coverImage: group.coverImage,
            managers: group.managers,
            members: [...group.members, _currentUserId!],
            settings: group.settings,
            status: group.status,
            type: group.type,
            createdAt: group.createdAt,
          );
          _safeNotifyListeners();
        }
      }
      return 'success';
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('REQUEST_SENT:')) {
        String cleanMsg = errorMsg.replaceAll('Exception: ', '').replaceAll('REQUEST_SENT:', '').trim();
        if (!_isDisposed) {
          _actionError = cleanMsg;
          _safeNotifyListeners();
        }
        return 'pending';
      }
      if (!_isDisposed) {
        _actionError = errorMsg.replaceAll('Exception: ', '');
        _safeNotifyListeners();
      }
      return 'error';
    }
  }

  void clearSearch() {
    print('🧹 [SearchViewModel] Clearing search results');
    _searchResults = [];
    _groupResults = [];
    _postResults = [];
    _errorMessage = null;
    _safeNotifyListeners();
  }

  Future<void> debugSearchGroups(String query) async {
    print('\n🐛 [SearchViewModel] === DEBUG SEARCH GROUPS ===');
    print('Query: "$query"');
    print('Current User ID: $_currentUserId');

    try {
      final groups = await _groupRequest.searchGroups(query);
      print('Total groups found: ${groups.length}');

      for (var group in groups) {
        print('---');
        print('ID: ${group.id}');
        print('Name: ${group.name}');
        print('Type: ${group.type}');
        print('Status: ${group.status}');
        print('Members: ${group.members.length}');
      }

      final postGroups = groups.where((g) => g.type == 'post').toList();
      print('\nPost groups (filtered): ${postGroups.length}');
      print('=== END DEBUG ===\n');
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }
}