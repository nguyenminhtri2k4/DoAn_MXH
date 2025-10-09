import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_friend_request.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/friend_request_manager.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';

class FriendsViewModel extends ChangeNotifier {
  final FriendRequestManager _requestManager = FriendRequestManager();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreListener _listener;
  
  String? _currentUserDocId;
  String? _currentAuthUid;
  
  // Dữ liệu Stream: Stream 1 cho lời mời đến, Stream 2 cho lời mời đã gửi
  Stream<List<FriendRequestModel>>? incomingRequestsStream;
  Stream<List<FriendRequestModel>>? sentRequestsStream;
  
  bool _isLoading = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  FriendsViewModel(this._listener) {
    _initialize();
  }
  
  void _initialize() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _errorMessage = 'Người dùng chưa đăng nhập.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    _currentAuthUid = firebaseUser.uid;
    
    _listener.addListener(_onListenerUpdate);
    _checkAndStartStreams(); // Thử khởi tạo ngay lần đầu
  }
  
  void _onListenerUpdate() {
      // Hàm này chạy mỗi khi user data trong FirestoreListener cập nhật
      _checkAndStartStreams();
  }

  void _checkAndStartStreams() {
      // Chỉ chạy nếu các streams chưa được khởi tạo và Auth UID đã có
      if (incomingRequestsStream != null || _currentAuthUid == null) {
          return;
      }
      
      // Lấy Document ID của user hiện tại
      UserModel? currentUser = _listener.getUserByAuthUid(_currentAuthUid!);
      
      if (currentUser != null) {
          // Dữ liệu đã có, gỡ listener và khởi tạo Streams
          _listener.removeListener(_onListenerUpdate);
          
          _currentUserDocId = currentUser.id;
          
          incomingRequestsStream = _requestManager.getIncomingRequests(_currentUserDocId!);
          sentRequestsStream = _requestManager.getSentRequests(_currentUserDocId!);
          
          _isLoading = false;
          notifyListeners();
      } else {
          // Tiếp tục hiển thị loading nếu user data chưa được tải
          if (!_isLoading) {
             _isLoading = true;
             notifyListeners();
          }
      }
  }


  /// Chấp nhận lời mời kết bạn
  Future<void> acceptRequest(FriendRequestModel request) async {
    try {
      await _requestManager.acceptRequest(request);
      // Stream sẽ tự động cập nhật UI (lời mời sẽ biến mất)
    } catch (e) {
      _errorMessage = 'Lỗi chấp nhận lời mời: $e';
      notifyListeners();
    }
  }

  /// Từ chối/Hủy lời mời kết bạn (dùng chung cho cả 2 loại request)
  Future<void> rejectOrCancelRequest(String requestId) async {
    try {
      await _requestManager.rejectRequest(requestId);
       // Stream sẽ tự động cập nhật UI (lời mời sẽ biến mất)
    } catch (e) {
      _errorMessage = 'Lỗi xử lý lời mời: $e';
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
      _listener.removeListener(_onListenerUpdate);
      super.dispose();
  }
}