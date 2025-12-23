import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_friend_request.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/friend_request_manager.dart';
import 'package:mangxahoi/request/user_request.dart'; // ✅ THÊM
import 'package:mangxahoi/authanet/firestore_listener.dart';

class FriendsViewModel extends ChangeNotifier {
  final FriendRequestManager _requestManager = FriendRequestManager();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRequest _userRequest = UserRequest(); // ✅ THÊM
  final FirestoreListener? _listener; // ✅ Optional - không bắt buộc

  String? _currentUserDocId;
  UserModel? _currentUser;

  Stream<List<FriendRequestModel>>? incomingRequestsStream;
  Stream<List<FriendRequestModel>>? sentRequestsStream;

  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> get suggestions => _suggestions;

  bool _isLoading = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserDocId => _currentUserDocId;
  UserModel? get currentUser => _currentUser;

  // ✅ Constructor nhận optional listener
  FriendsViewModel([this._listener]) {
    _init();
    // Vẫn lắng nghe listener nếu có (để sync realtime)
    if (_listener != null) {
      _listener!.addListener(_onDataUpdated);
    }
  }

  // ✅ Init tự động như các ViewModel khác
  // Future<void> _init() async {
  //   print('🔧 [FriendsVM] Bắt đầu khởi tạo...');
  //   _isLoading = true;
  //   notifyListeners();

  //   try {
  //     final firebaseUser = _auth.currentUser;
  //     if (firebaseUser == null) {
  //       print('⚠️ [FriendsVM] Chưa đăng nhập Firebase Auth');
  //       _errorMessage = 'Người dùng chưa đăng nhập.';
  //       _isLoading = false;
  //       notifyListeners();
  //       return;
  //     }

  //     print('🔍 [FriendsVM] Đang tìm user với UID: ${firebaseUser.uid}');
  //     _currentUser = await _userRequest.getUserByUid(firebaseUser.uid);

  //     if (_currentUser != null) {
  //       _currentUserDocId = _currentUser!.id;
  //       print('✅ [FriendsVM] Đã lấy currentUserDocId: $_currentUserDocId');

  //       // Khởi tạo streams
  //       incomingRequestsStream = _requestManager.getIncomingRequests(
  //         _currentUserDocId!,
  //       );
  //       sentRequestsStream = _requestManager.getSentRequests(
  //         _currentUserDocId!,
  //       );

  //       print('✅ [FriendsVM] Đã khởi tạo friend request streams');
  //     } else {
  //       print('⚠️ [FriendsVM] Không tìm thấy user trong Firestore');
  //       _errorMessage = 'Không tìm thấy thông tin người dùng.';
  //     }
  //   } catch (e, stackTrace) {
  //     print('❌ [FriendsVM] Lỗi khi init: $e');
  //     print('❌ [FriendsVM] StackTrace: $stackTrace');
  //     _errorMessage = 'Lỗi tải dữ liệu: $e';
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //     print('✅ [FriendsVM] Khởi tạo hoàn tất');
  //   }
  // }
  Future<void> _init() async {
  print('🔧 [FriendsVM] Bắt đầu khởi tạo...');
  _isLoading = true;
  notifyListeners();

  try {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      print('⚠️ [FriendsVM] Chưa đăng nhập Firebase Auth');
      _errorMessage = 'Người dùng chưa đăng nhập.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    print('🔍 [FriendsVM] Đang tìm user với UID: ${firebaseUser.uid}');
    _currentUser = await _userRequest.getUserByUid(firebaseUser.uid);

    if (_currentUser != null) {
      _currentUserDocId = _currentUser!.id;
      print('✅ [FriendsVM] Đã lấy currentUserDocId: $_currentUserDocId');

      // Khởi tạo các stream lời mời
      incomingRequestsStream = _requestManager.getIncomingRequests(_currentUserDocId!);
      sentRequestsStream = _requestManager.getSentRequests(_currentUserDocId!);

      print('✅ [FriendsVM] Đã khởi tạo friend request streams');

      // 🔥 LOGIC MỚI: Load gợi ý bạn bè ngay sau khi có thông tin User
      await _loadSuggestions();
      
    } else {
      print('⚠️ [FriendsVM] Không tìm thấy user trong Firestore');
      _errorMessage = 'Không tìm thấy thông tin người dùng.';
    }
  } catch (e, stackTrace) {
    print('❌ [FriendsVM] Lỗi khi init: $e');
    print('❌ [FriendsVM] StackTrace: $stackTrace');
    _errorMessage = 'Lỗi tải dữ liệu: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
    print('✅ [FriendsVM] Khởi tạo hoàn tất');
  }
}

  Future<void> _loadSuggestions() async {
  if (_currentUser == null) return;
    try {
      // Lấy toàn bộ user từ cache (UserRequest của bạn đã có hàm này)
      final allUsers = await _userRequest.getAllUsersForCache();
      final myFriendIds = _currentUser!.friends;

      List<Map<String, dynamic>> tempSuggestions = [];

      for (var user in allUsers) {
        // Điều kiện lọc: 
        // - Không phải bản thân
        // - Chưa có trong danh sách bạn bè
        if (user.id == _currentUserDocId || myFriendIds.contains(user.id)) continue;

        // Thuật toán tìm bạn chung: Giao điểm của 2 mảng ID bạn bè
        final mutualFriends = user.friends.where((id) => myFriendIds.contains(id)).toList();

        if (mutualFriends.isNotEmpty) {
          tempSuggestions.add({
            'user': user,
            'mutualCount': mutualFriends.length,
          });
        }
      }

      // Sắp xếp: Ai nhiều bạn chung hơn thì hiện lên trước
      tempSuggestions.sort((a, b) => b['mutualCount'].compareTo(a['mutualCount']));
      
      _suggestions = tempSuggestions;
      notifyListeners();
    } catch (e) {
      print('❌ [FriendsVM] Lỗi gợi ý: $e');
    }
  }

  // ✅ Sync với FirestoreListener nếu có (realtime updates)
  void _onDataUpdated() {
    if (_listener == null) return;

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    final newCurrentUser = _listener!.getUserByAuthUid(firebaseUser.uid);

    if (newCurrentUser != null && _currentUser?.id != newCurrentUser.id) {
      print('🔄 [FriendsVM] Cập nhật user từ FirestoreListener');
      _currentUser = newCurrentUser;
      _currentUserDocId = _currentUser!.id;

      // Chỉ init streams nếu chưa có
      incomingRequestsStream ??= _requestManager.getIncomingRequests(
        _currentUserDocId!,
      );
      sentRequestsStream ??= _requestManager.getSentRequests(
        _currentUserDocId!,
      );

      notifyListeners();
    }
  }

  Future<void> acceptRequest(FriendRequestModel request) async {
    if (_currentUserDocId == null) {
      print('⚠️ [FriendsVM] acceptRequest: currentUserDocId = null');
      return;
    }

    try {
      print('🔄 [FriendsVM] Accepting request from ${request.fromUserId}');
      await _requestManager.acceptRequest(request);

      // Cập nhật local cache nếu có listener
      if (_listener != null) {
        _listener!.updateLocalFriendship(
          request.fromUserId,
          request.toUserId,
          true,
        );
      }

      print('✅ [FriendsVM] Request accepted');
    } catch (e, stackTrace) {
      print('❌ [FriendsVM] Lỗi chấp nhận lời mời: $e');
      print('❌ [FriendsVM] StackTrace: $stackTrace');
      _errorMessage = 'Lỗi chấp nhận lời mời: $e';
      notifyListeners();
    }
  }

  Future<void> rejectOrCancelRequest(String requestId) async {
    try {
      print('🔄 [FriendsVM] Rejecting/canceling request $requestId');
      await _requestManager.rejectRequest(requestId);
      print('✅ [FriendsVM] Request rejected/canceled');
    } catch (e, stackTrace) {
      print('❌ [FriendsVM] Lỗi xử lý lời mời: $e');
      print('❌ [FriendsVM] StackTrace: $stackTrace');
      _errorMessage = 'Lỗi xử lý lời mời: $e';
      notifyListeners();
    }
  }

  // ✅ Thêm hàm refresh thủ công
  Future<void> refresh() async {
    await _init();
  }

  @override
  void dispose() {
    print('🔧 [FriendsVM] Disposing...');
    if (_listener != null) {
      _listener!.removeListener(_onDataUpdated);
    }
    super.dispose();
  }
}
