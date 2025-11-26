import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/group_request.dart';
import 'package:mangxahoi/request/friend_request_manager.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class SearchUserResult {
  final UserModel user;
  final String status;

  SearchUserResult({required this.user, required this.status});
}

class SearchViewModel extends ChangeNotifier {
  final UserRequest _userRequest = UserRequest();
  final GroupRequest _groupRequest = GroupRequest();
  final FriendRequestManager _requestManager = FriendRequestManager();
  final TextEditingController searchController = TextEditingController();

  List<UserModel> _allUsersCache = [];
  List<SearchUserResult> _searchResults = [];
  List<GroupModel> _groupResults = [];

  bool _isLoading = false;
  String? _errorMessage;
  String? _actionError;
  Timer? _debounce;
  bool _isDisposed = false;

  String? _currentUserId;

  List<SearchUserResult> get searchResults => _searchResults;
  List<GroupModel> get groupResults => _groupResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;
  String? get currentUserId => _currentUserId;

  SearchViewModel() {
    print('🚀 [SearchViewModel] Initializing...');
    _getCurrentUserDocId();
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

  /// Lấy currentUserId từ Firebase Auth
  void _getCurrentUserDocId() async {
    if (_isDisposed) return;

    try {
      print('🔍 [SearchViewModel] Getting current user...');
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null && !_isDisposed) {
        print('📧 [SearchViewModel] Firebase user UID: ${firebaseUser.uid}');
        final user = await _userRequest.getUserByUid(firebaseUser.uid);

        if (!_isDisposed && user != null) {
          _currentUserId = user.id;
          print('✅ [SearchViewModel] Current user ID: $_currentUserId');
        } else {
          print('⚠️ [SearchViewModel] User not found in Firestore');
        }
      } else {
        print('⚠️ [SearchViewModel] No Firebase user logged in');
      }
    } catch (e) {
      print('❌ [SearchViewModel] Error getting current user: $e');
    }
  }

  /// Load tất cả user vào cache để tìm kiếm nhanh
  Future<void> _loadAllUsersCache() async {
    if (_isDisposed) return;

    _isLoading = true;
    _safeNotifyListeners();

    try {
      print('📥 [SearchViewModel] Loading users cache...');
      _allUsersCache = await _userRequest.getAllUsersForCache(limit: 1000);

      if (_isDisposed) return;

      _errorMessage = null;
      print(
        '✅ [SearchViewModel] Loaded ${_allUsersCache.length} users into cache',
      );
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

  /// Listener khi searchController thay đổi
  void _onSearchChanged() {
    if (_isDisposed) return;

    final query = searchController.text.trim();
    print('⌨️ [SearchViewModel] Search text changed: "$query"');

    // Cancel debounce cũ
    _debounce?.cancel();
    _debounce = null;

    // Nếu query rỗng → clear results
    if (query.isEmpty) {
      print('🧹 [SearchViewModel] Query empty, clearing results');
      _searchResults = [];
      _groupResults = [];
      _errorMessage = null;
      _safeNotifyListeners();
      return;
    }

    // Debounce 300ms trước khi search
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!_isDisposed) {
        print('⏱️ [SearchViewModel] Debounce triggered, starting search...');
        _searchAll(query);
      }
    });
  }

  /// Tìm kiếm cả user và group
  void _searchAll(String query) async {
    if (_isDisposed) {
      print('⚠️ [SearchViewModel] Disposed, cancelling search');
      return;
    }

    if (query.isEmpty) {
      print('⚠️ [SearchViewModel] Empty query, skipping search');
      _searchResults = [];
      _groupResults = [];
      _errorMessage = null;
      _safeNotifyListeners();
      return;
    }

    if (_currentUserId == null) {
      print('⚠️ [SearchViewModel] Current user ID is null, skipping search');
      _errorMessage = 'Vui lòng đăng nhập để tìm kiếm';
      _safeNotifyListeners();
      return;
    }

    print('🔍 [SearchViewModel] Starting search for: "$query"');
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      print('📡 [SearchViewModel] Searching users and groups in parallel...');

      // Tìm kiếm song song
      final results = await Future.wait([
        _searchUsersLocal(query),
        _searchGroups(query),
      ]);

      if (_isDisposed) {
        print('⚠️ [SearchViewModel] Disposed during search');
        return;
      }

      _searchResults = results[0] as List<SearchUserResult>;
      _groupResults = results[1] as List<GroupModel>;

      print('📊 [SearchViewModel] Search completed:');
      print('   👥 Users found: ${_searchResults.length}');
      print('   👥 Groups found: ${_groupResults.length}');

      if (_searchResults.isEmpty && _groupResults.isEmpty) {
        _errorMessage = 'Không tìm thấy kết quả nào khớp với "$query".';
        print('⚠️ [SearchViewModel] No results found');
      } else {
        _errorMessage = null;
        print('✅ [SearchViewModel] Search successful');
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

  /// Tìm kiếm user từ cache (local search)
  Future<List<SearchUserResult>> _searchUsersLocal(String query) async {
    if (_isDisposed) return [];

    try {
      print('🔍 [SearchViewModel] Searching users locally...');
      final lowerCaseQuery = query.toLowerCase();

      final filteredUsers =
          _allUsersCache.where((user) {
            final userNameLower = user.name.toLowerCase();
            final userEmailLower = user.email.toLowerCase();
            final userPhone = user.phone;

            return userNameLower.contains(lowerCaseQuery) ||
                userEmailLower.contains(lowerCaseQuery) ||
                userPhone.contains(lowerCaseQuery);
          }).toList();

      print(
        '👥 [SearchViewModel] Found ${filteredUsers.length} matching users',
      );

      if (_isDisposed) return [];

      List<SearchUserResult> resultsWithStatus = [];

      for (var user in filteredUsers) {
        if (_isDisposed) return [];

        final status = await _requestManager.getFriendshipStatus(
          _currentUserId!,
          user.id,
        );

        if (_isDisposed) return [];

        resultsWithStatus.add(SearchUserResult(user: user, status: status));
      }

      print(
        '✅ [SearchViewModel] User search complete with ${resultsWithStatus.length} results',
      );
      return resultsWithStatus;
    } catch (e) {
      print('❌ [SearchViewModel] User search error: $e');
      return [];
    }
  }

  /// Tìm kiếm group (CHỈ NHÓM BÀI ĐĂNG)
  Future<List<GroupModel>> _searchGroups(String query) async {
    if (_isDisposed) return [];

    try {
      print('🔍 [SearchViewModel] Searching groups with query: "$query"');

      final allGroups = await _groupRequest.searchGroups(query);

      if (_isDisposed) return [];

      print(
        '📦 [SearchViewModel] Total groups returned from API: ${allGroups.length}',
      );

      // Debug: In ra thông tin các nhóm tìm được
      for (var group in allGroups) {
        print(
          '   📁 Group: "${group.name}" | Type: "${group.type}" | Status: "${group.status}" | Members: ${group.members.length}',
        );
      }

      // Lọc chỉ lấy nhóm type = 'post'
      final postGroups =
          allGroups.where((group) => group.type == 'post').toList();

      print(
        '✅ [SearchViewModel] Found ${postGroups.length} post groups (filtered from ${allGroups.length})',
      );

      if (postGroups.isEmpty && allGroups.isNotEmpty) {
        print(
          '⚠️ [SearchViewModel] WARNING: All groups were filtered out! Check if "type" field is correct.',
        );
        print('   Expected: type == "post"');
        print(
          '   Found types: ${allGroups.map((g) => g.type).toSet().toList()}',
        );
      }

      return postGroups;
    } catch (e) {
      print('❌ [SearchViewModel] Group search error: $e');
      print('   Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Gửi lời mời kết bạn
  Future<bool> sendFriendRequest(String toUserId) async {
    if (_currentUserId == null || _isDisposed) {
      print(
        '⚠️ [SearchViewModel] Cannot send friend request: currentUserId is null or disposed',
      );
      return false;
    }

    _actionError = null;

    try {
      print(
        '📤 [SearchViewModel] Sending friend request from $_currentUserId to $toUserId',
      );
      await _requestManager.sendRequest(_currentUserId!, toUserId);

      if (_isDisposed) return false;

      // Cập nhật trạng thái trong danh sách
      final index = _searchResults.indexWhere((r) => r.user.id == toUserId);
      if (index != -1) {
        _searchResults[index] = SearchUserResult(
          user: _searchResults[index].user,
          status: 'pending_sent',
        );
        _safeNotifyListeners();
      }

      print('✅ [SearchViewModel] Friend request sent successfully');
      return true;
    } catch (e) {
      print('❌ [SearchViewModel] Error sending friend request: $e');
      if (!_isDisposed) {
        _actionError = e.toString().replaceAll("Exception: ", "");
        _safeNotifyListeners();
      }
      return false;
    }
  }

  
  Future<String> joinGroup(String groupId) async {
  if (_currentUserId == null || _isDisposed) {
    print('⚠️ [SearchViewModel] Cannot join group: currentUserId is null or disposed');
    _actionError = 'Vui lòng đăng nhập để tham gia nhóm';
    _safeNotifyListeners();
    return 'error';
  }

  try {
    print('📤 [SearchViewModel] User $_currentUserId joining group $groupId');
    await _groupRequest.joinGroup(groupId, _currentUserId!);

    if (_isDisposed) return 'error';

    // Nếu thành công -> cập nhật members list
    final index = _groupResults.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final updatedGroup = _groupResults[index];
      _groupResults[index] = GroupModel(
        id: updatedGroup.id,
        ownerId: updatedGroup.ownerId,
        name: updatedGroup.name,
        description: updatedGroup.description,
        coverImage: updatedGroup.coverImage,
        managers: updatedGroup.managers,
        members: [...updatedGroup.members, _currentUserId!],
        settings: updatedGroup.settings,
        status: updatedGroup.status,
        type: updatedGroup.type,
        createdAt: updatedGroup.createdAt,
      );
      _safeNotifyListeners();
    }

    print('✅ [SearchViewModel] Joined group successfully');
    _actionError = null;
    return 'success';
  } catch (e) {
    print('❌ [SearchViewModel] Error joining group: $e');
    final errorMsg = e.toString().replaceAll('Exception: ', '');
    
    if (!_isDisposed) {
      // ✅ Kiểm tra prefix "REQUEST_SENT:" để phát hiện gửi request thành công
      if (errorMsg.startsWith('REQUEST_SENT:')) {
        _actionError = errorMsg.replaceFirst('REQUEST_SENT:', '');
        _safeNotifyListeners();
        return 'pending'; // Trả về 'pending' để View biết gửi request thành công
      } else {
        _actionError = errorMsg;
        _safeNotifyListeners();
        return 'error';
      }
    }
    return 'error';
  }
}


  /// Clear search results
  void clearSearch() {
    print('🧹 [SearchViewModel] Clearing search results');
    _searchResults = [];
    _groupResults = [];
    _errorMessage = null;
    _safeNotifyListeners();
  }

  /// Debug method - gọi để test search groups trực tiếp
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
