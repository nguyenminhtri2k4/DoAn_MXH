
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_friend_request.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/friend_request_manager.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';

class FriendsViewModel extends ChangeNotifier {
  final FriendRequestManager _requestManager = FriendRequestManager();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreListener _listener; // Đây là FirestoreListener

  String? _currentUserDocId;
  UserModel? _currentUser;

  Stream<List<FriendRequestModel>>? incomingRequestsStream;
  Stream<List<FriendRequestModel>>? sentRequestsStream;

  bool _isLoading = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserDocId => _currentUserDocId;

  FriendsViewModel(this._listener) {
    // <-- _listener được inject
    _initialize();
  }

  void _initialize() {
    _listener.addListener(_onDataUpdated);
    _onDataUpdated();
  }

  void _onDataUpdated() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _errorMessage = 'Người dùng chưa đăng nhập.';
      if (_isLoading) _isLoading = false;
      notifyListeners();
      return;
    }

    final newCurrentUser = _listener.getUserByAuthUid(firebaseUser.uid);

    if (newCurrentUser != null && _currentUser?.id != newCurrentUser.id) {
      _currentUser = newCurrentUser;
      _currentUserDocId = _currentUser!.id;

      incomingRequestsStream ??=
          _requestManager.getIncomingRequests(_currentUserDocId!);
      sentRequestsStream ??=
          _requestManager.getSentRequests(_currentUserDocId!);

      if (_isLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> acceptRequest(FriendRequestModel request) async {
    try {
      await _requestManager.acceptRequest(request);
      // --- DÒNG SỬA LỖI ---
      // Gọi hàm cập nhật local cache ngay lập tức, báo là "thêm bạn" (true)
      _listener.updateLocalFriendship(request.fromUserId, request.toUserId, true);
      // --------------------
    } catch (e) {
      _errorMessage = 'Lỗi chấp nhận lời mời: $e';
      notifyListeners();
    }
  }

  Future<void> rejectOrCancelRequest(String requestId) async {
    try {
      await _requestManager.rejectRequest(requestId);
    } catch (e) {
      _errorMessage = 'Lỗi xử lý lời mời: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _listener.removeListener(_onDataUpdated);
    super.dispose();
  }
}