
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart';

class UserService extends ChangeNotifier {
  final UserRequest _userRequest = UserRequest();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription? _authSubscription;
  Timer? _retryTimer;

  UserService() {
    print('🔧 [UserService] Constructor called');
    _initialize();
  }

  void _initialize() {
    print('🔄 [UserService] Initializing auth listener...');
    
    // Kiểm tra ngay user hiện tại
    final currentFirebaseUser = _auth.currentUser;
    print('🔍 [UserService] Current Firebase user: ${currentFirebaseUser?.uid}');
    
    if (currentFirebaseUser != null) {
      print('🚀 [UserService] Có user đang logged in, loading ngay...');
      _loadUserWithRetry(currentFirebaseUser.uid);
    }

    // Lắng nghe thay đổi trạng thái auth
    _authSubscription = _auth.authStateChanges().listen((firebaseUser) {
      print('🎯 [UserService] authStateChanges triggered: ${firebaseUser?.uid}');
      _onAuthStateChanged(firebaseUser);
    }, onError: (error) {
      print('❌ [UserService] authStateChanges error: $error');
    });
  }

  // ✅ THÊM: Hàm load user với retry mechanism
  Future<void> _loadUserWithRetry(String uid, {int retryCount = 0}) async {
    print('📥 [UserService] _loadUserWithRetry called for UID: $uid (retry: $retryCount)');
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _userRequest.getUserByUid(uid);
      
      if (_currentUser != null) {
        print('✅ [UserService] _loadUserWithRetry SUCCESS: ${_currentUser!.name}');
        _cancelRetryTimer();
      } else {
        print('❌ [UserService] _loadUserWithRetry FAILED: User not found');
        
        // ✅ THÊM: Retry sau 2 giây nếu user chưa có trong Firestore (trường hợp đăng ký mới)
        if (retryCount < 3) {
          print('🔄 [UserService] Scheduling retry in 2 seconds...');
          _retryTimer = Timer(const Duration(seconds: 2), () {
            _loadUserWithRetry(uid, retryCount: retryCount + 1);
          });
        } else {
          print('❌ [UserService] Max retries reached, giving up');
        }
      }
    } catch (e) {
      print('❌ [UserService] _loadUserWithRetry ERROR: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('🔍 [UserService] _loadUserWithRetry completed - _currentUser: ${_currentUser != null}');
    }
  }

  void _cancelRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    print('🔄 [UserService] _onAuthStateChanged: ${firebaseUser?.uid}');
    
    if (firebaseUser == null) {
      print('👤 [UserService] User signed out');
      _cancelRetryTimer();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Nếu đã có user rồi thì không load lại
    if (_currentUser?.uid == firebaseUser.uid) {
      print('⚠️ [UserService] User already loaded, skipping...');
      return;
    }

    await _loadUserWithRetry(firebaseUser.uid);
  }

  Future<void> reloadUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      print('🔄 [UserService] Manual reload requested');
      await _loadUserWithRetry(firebaseUser.uid);
    }
  }

  Future<bool> forceReloadUserWithTimeout({Duration timeout = const Duration(seconds: 5)}) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      print('⚠️ [UserService] forceReload: No Firebase user');
      return false;
    }

    print('🔄 [UserService] Force reload user với UID: ${firebaseUser.uid}');
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _userRequest.getUserByUid(firebaseUser.uid)
          .timeout(timeout);
      
      _isLoading = false;
      notifyListeners();
      
      if (_currentUser != null) {
        print('✅ [UserService] Force reload thành công: ${_currentUser!.name}');
        return true;
      } else {
        print('⚠️ [UserService] Force reload: User not found');
        return false;
      }
    } catch (e) {
      print('❌ [UserService] Force reload lỗi: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Debug method
  void printDebugInfo() {
    final firebaseUser = _auth.currentUser;
    print('🔍 [UserService] DEBUG INFO:');
    print('🔍 [UserService] Firebase User: ${firebaseUser?.uid}');
    print('🔍 [UserService] Current User: ${_currentUser?.name} (${_currentUser?.uid})');
    print('🔍 [UserService] Is Loading: $_isLoading');
    print('🔍 [UserService] Has Auth Subscription: ${_authSubscription != null}');
    print('🔍 [UserService] Has Retry Timer: ${_retryTimer != null}');
  }

  // ✅ HÀM MỚI: Cập nhật user hiện tại và thông báo cho các widget nghe (listeners)
  // Hàm này giúp cập nhật UI ngay lập tức (ví dụ khi bật/tắt toggle Gemini)
  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  @override
  void dispose() {
    print('🔧 [UserService] Disposing...');
    _cancelRetryTimer();
    _authSubscription?.cancel();
    super.dispose();
  }
}