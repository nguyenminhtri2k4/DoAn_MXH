import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart';
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
  final FriendRequestManager _requestManager = FriendRequestManager();
  final TextEditingController searchController = TextEditingController();

  List<UserModel> _allUsersCache = [];
  List<SearchUserResult> _searchResults = [];

  bool _isLoading = false;
  String? _errorMessage;
  String? _actionError;
  Timer? _debounce;
  bool _isDisposed = false;

  String? _currentUserId;

  List<SearchUserResult> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;

  SearchViewModel() {
    _getCurrentUserDocId();
    searchController.addListener(_onSearchChanged);
    _loadAllUsersCache();
  }

  @override
  void dispose() {
    print('🧹 [SearchViewModel] Disposing...');
    _isDisposed = true;
    
    // ✅ Cancel debounce BEFORE removing listener
    _debounce?.cancel();
    _debounce = null;
    
    // ✅ Remove listener BEFORE disposing controller
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    
    super.dispose();
  }

  // ✅ Safe notify that checks disposed AND hasListeners
  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ [SearchViewModel] Error notifying listeners: $e');
      }
    }
  }

  void _getCurrentUserDocId() async {
    if (_isDisposed) return;
    
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && !_isDisposed) {
        final user = await _userRequest.getUserByUid(firebaseUser.uid);
        if (!_isDisposed && user != null) {
          _currentUserId = user.id;
          print('✅ [SearchViewModel] Current user ID: $_currentUserId');
        }
      }
    } catch (e) {
      print('❌ [SearchViewModel] Error getting current user: $e');
    }
  }

  Future<void> _loadAllUsersCache() async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _safeNotifyListeners();

    try {
      _allUsersCache = await _userRequest.getAllUsersForCache(limit: 1000);
      
      if (_isDisposed) return;
      
      _errorMessage = null;
      print('✅ [SearchViewModel] Loaded ${_allUsersCache.length} users into cache');
    } catch (e) {
      print('❌ [SearchViewModel] Lỗi khi tải cache user: $e');
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
    
    // ✅ Cancel previous debounce
    _debounce?.cancel();
    _debounce = null;

    if (query.isEmpty) {
      _searchResults = [];
      _errorMessage = null;
      _safeNotifyListeners();
      return;
    }

    // ✅ Create new debounce timer with disposed check
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!_isDisposed) {
        _searchLocalCache(query);
      }
    });
  }

  void _searchLocalCache(String query) async {
    if (_isDisposed) return;
    
    if (query.isEmpty || _currentUserId == null) {
      _searchResults = [];
      _errorMessage = null;
      _safeNotifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final lowerCaseQuery = query.toLowerCase();

      final filteredUsers = _allUsersCache.where((user) {
        final userNameLower = user.name.toLowerCase();
        final userEmailLower = user.email.toLowerCase();
        final userPhone = user.phone;

        return userNameLower.contains(lowerCaseQuery) ||
            userEmailLower.contains(lowerCaseQuery) ||
            userPhone.contains(lowerCaseQuery);
      }).toList();

      // ✅ Check disposed before async operation
      if (_isDisposed) return;

      List<SearchUserResult> resultsWithStatus = [];
      
      // ✅ Process in smaller batches to allow for disposal checks
      for (var user in filteredUsers) {
        if (_isDisposed) return; // Check on each iteration
        
        final status = await _requestManager.getFriendshipStatus(_currentUserId!, user.id);
        
        if (_isDisposed) return; // Check after each async call
        
        resultsWithStatus.add(SearchUserResult(
          user: user,
          status: status,
        ));
      }

      // ✅ Final check before updating state
      if (_isDisposed) return;

      _searchResults = resultsWithStatus;

      if (_searchResults.isEmpty) {
        _errorMessage = 'Không tìm thấy kết quả nào khớp với "$query".';
      } else {
        _errorMessage = null;
      }
      
      print('✅ [SearchViewModel] Found ${_searchResults.length} results for "$query"');
    } catch (e) {
      print('❌ [SearchViewModel] Lỗi khi tìm kiếm: $e');
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

  Future<bool> sendFriendRequest(String toUserId) async {
    if (_currentUserId == null || _isDisposed) {
      print('⚠️ [SearchViewModel] Cannot send friend request: currentUserId is null or disposed');
      return false;
    }
    
    _actionError = null;

    try {
      print('📤 [SearchViewModel] Sending friend request to $toUserId');
      await _requestManager.sendRequest(_currentUserId!, toUserId);

      if (_isDisposed) return false;

      // ✅ Update UI
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
}