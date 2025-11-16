
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
  bool _isMounted = true; // ✅ THÊM: Track mounted state

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
    _isMounted = false; // ✅ Mark as unmounted
    _debounce?.cancel();
    _debounce = null; // ✅ Clear reference
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    // ✅ QUAN TRỌNG: Kiểm tra cả disposed và mounted
    if (!_isDisposed && _isMounted && hasListeners) {
      try {
        super.notifyListeners();
      } catch (e) {
        print('⚠️ [SearchViewModel] Error notifying listeners: $e');
      }
    }
  }

  void _getCurrentUserDocId() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && !_isDisposed && _isMounted) {
        final user = await _userRequest.getUserByUid(firebaseUser.uid);
        if (!_isDisposed && _isMounted && user != null) {
          _currentUserId = user.id;
        }
      }
    } catch (e) {
      print('❌ [SearchViewModel] Error getting current user: $e');
    }
  }

  Future<void> _loadAllUsersCache() async {
    if (_isDisposed || !_isMounted) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _allUsersCache = await _userRequest.getAllUsersForCache(limit: 1000);
      
      if (_isDisposed || !_isMounted) return;
      
      _errorMessage = null;
    } catch (e) {
      print('❌ [SearchViewModel] Lỗi khi tải cache user: $e');
      if (!_isDisposed && _isMounted) {
        _errorMessage = 'Lỗi tải dữ liệu cơ sở. Vui lòng thử lại sau.';
      }
    } finally {
      if (!_isDisposed && _isMounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _onSearchChanged() {
    if (_isDisposed || !_isMounted) return;
    
    final query = searchController.text.trim();
    
    // ✅ Cancel previous debounce
    _debounce?.cancel();

    if (query.isEmpty) {
      _searchResults = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    // ✅ Create new debounce timer
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!_isDisposed && _isMounted) {
        _searchLocalCache(query);
      }
    });
  }

  void _searchLocalCache(String query) async {
    if (_isDisposed || !_isMounted) return;
    
    if (query.isEmpty || _currentUserId == null) {
      _searchResults = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

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

      // ✅ Check again before async operation
      if (_isDisposed || !_isMounted) return;

      List<SearchUserResult> resultsWithStatus = [];
      final statusFutures = filteredUsers.map((user) {
        return _requestManager.getFriendshipStatus(_currentUserId!, user.id);
      }).toList();

      final statuses = await Future.wait(statusFutures);

      // ✅ Check again after async operation
      if (_isDisposed || !_isMounted) return;

      for (int i = 0; i < filteredUsers.length; i++) {
        resultsWithStatus.add(SearchUserResult(
          user: filteredUsers[i],
          status: statuses[i],
        ));
      }

      _searchResults = resultsWithStatus;

      if (_searchResults.isEmpty) {
        _errorMessage = 'Không tìm thấy kết quả nào khớp với "$query".';
      } else {
        _errorMessage = null;
      }
    } catch (e) {
      print('❌ [SearchViewModel] Lỗi khi tìm kiếm: $e');
      if (!_isDisposed && _isMounted) {
        _errorMessage = 'Có lỗi xảy ra khi tìm kiếm.';
      }
    } finally {
      if (!_isDisposed && _isMounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> sendFriendRequest(String toUserId) async {
    if (_currentUserId == null || _isDisposed || !_isMounted) return false;
    
    _actionError = null;

    try {
      await _requestManager.sendRequest(_currentUserId!, toUserId);

      if (_isDisposed || !_isMounted) return false;

      final index = _searchResults.indexWhere((r) => r.user.id == toUserId);
      if (index != -1) {
        _searchResults[index] = SearchUserResult(
          user: _searchResults[index].user,
          status: 'pending_sent',
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      if (_isDisposed || !_isMounted) return false;
      _actionError = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }
}