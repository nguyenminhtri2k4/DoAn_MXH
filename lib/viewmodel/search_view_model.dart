import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/friend_request_manager.dart'; 
import 'dart:async'; 
import 'package:firebase_auth/firebase_auth.dart'; 

// Helper class để đóng gói User và Status
class SearchUserResult {
  final UserModel user;
  final String status; // 'friends', 'pending_sent', 'pending_received', 'none'

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
  Timer? _debounce; 

  String? _currentUserId; // Document ID của user hiện tại

  List<SearchUserResult> get searchResults => _searchResults; 
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SearchViewModel() {
    _getCurrentUserDocId();
    searchController.addListener(_onSearchChanged);
    _loadAllUsersCache(); 
  }
  
  void _getCurrentUserDocId() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
        final user = await _userRequest.getUserByUid(firebaseUser.uid);
        if (user != null) _currentUserId = user.id;
    }
  }

  Future<void> _loadAllUsersCache() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _allUsersCache = await _userRequest.getAllUsersForCache(limit: 1000); 
      _errorMessage = null;
    } catch (e) {
      print('❌ Lỗi khi tải cache user: $e');
      _errorMessage = 'Lỗi tải dữ liệu cơ sở. Vui lòng thử lại sau.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onSearchChanged() {
    final query = searchController.text.trim();
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      _searchResults = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchLocalCache(query);
    });
  }
  
  // Thuật toán tìm kiếm Gần đúng (Substring/Contains) trên Cache
  void _searchLocalCache(String query) async { 
    if (query.isEmpty || _currentUserId == null) {
      _searchResults = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final lowerCaseQuery = query.toLowerCase();
    
    // 1. Lọc UserModels (Search Substring)
    final filteredUsers = _allUsersCache.where((user) {
      final userNameLower = user.name.toLowerCase();
      final userEmailLower = user.email.toLowerCase();
      final userPhone = user.phone;

      return userNameLower.contains(lowerCaseQuery) ||
             userEmailLower.contains(lowerCaseQuery) ||
             userPhone.contains(lowerCaseQuery);
    }).toList();

    // 2. Lấy trạng thái bạn bè cho từng user
    List<SearchUserResult> resultsWithStatus = [];
    
    // Chạy song song các request lấy status
    final statusFutures = filteredUsers.map((user) {
        return _requestManager.getFriendshipStatus(_currentUserId!, user.id);
    }).toList();
    
    final statuses = await Future.wait(statusFutures);

    for(int i = 0; i < filteredUsers.length; i++) {
        resultsWithStatus.add(SearchUserResult(
            user: filteredUsers[i],
            status: statuses[i],
        ));
    }

    _searchResults = resultsWithStatus;
    _isLoading = false;

    if (_searchResults.isEmpty) {
      _errorMessage = 'Không tìm thấy kết quả nào khớp với "$query".';
    } else {
      _errorMessage = null;
    }
    
    notifyListeners();
  }
  
  // GỬI LỜI MỜI VÀ CẬP NHẬT TRẠNG THÁI CỤC BỘ
  Future<bool> sendFriendRequest(String toUserId) async {
    if (_currentUserId == null) return false;
    
    final success = await _requestManager.sendRequest(_currentUserId!, toUserId);
    
    if (success) {
      // Cập nhật trạng thái cục bộ thành 'pending_sent'
      final index = _searchResults.indexWhere((r) => r.user.id == toUserId);
      if (index != -1) {
          _searchResults[index] = SearchUserResult(
              user: _searchResults[index].user,
              status: 'pending_sent', 
          );
          notifyListeners();
      }
    }
    
    return success;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}