
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/request/login_request.dart';
import 'package:mangxahoi/model/model_user.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginRequest _loginRequest = LoginRequest();
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  /// Optimized login method
  Future<bool> login(String email, String password) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      print('🔄 Starting login process for: $email');
      
      // 1. Authenticate with Firebase Auth
      final userCredential = await _loginRequest.login(email, password);
      
      if (_isDisposed) return false;

      if (userCredential == null) {
        _errorMessage = 'Sai email hoặc mật khẩu';
        _isLoading = false;
        _safeNotify();
        return false;
      }

      final uid = userCredential.user?.uid;
      if (uid == null) {
        _errorMessage = 'Không tìm thấy UID người dùng';
        _isLoading = false;
        _safeNotify();
        return false;
      }

      print('✅ Firebase Auth successful, UID: $uid');

      // 2. Get user data from Firestore
      _currentUser = await _loginRequest.getUserDataByAuthUid(uid);
      
      if (_isDisposed) return false;

      if (_currentUser == null) {
        _errorMessage = 'Không tìm thấy thông tin người dùng trong database';
        _isLoading = false;
        _safeNotify();
        return false;
      }

      print('✅ Login successful: ${_currentUser!.name}');
      _isLoading = false;
      _safeNotify();
      return true;
      
    } on FirebaseAuthException catch (e) {
      if (_isDisposed) return false;
      _isLoading = false;
      _errorMessage = _parseFirebaseError(e);
      _safeNotify();
      return false;
    } catch (e) {
      if (_isDisposed) return false;
      _isLoading = false;
      _errorMessage = 'Lỗi đăng nhập: ${e.toString()}';
      _safeNotify();
      return false;
    }
  }
  
  // *** BẮT ĐẦU CODE MỚI ***
  /// Gửi email đặt lại mật khẩu
  Future<bool> sendPasswordResetEmail(String email) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await _loginRequest.sendPasswordResetEmail(email);
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _isLoading = false;
      // Lỗi đã được xử lý bởi LoginRequest
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }
  // *** KẾT THÚC CODE MỚI ***

  String _parseFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email không tồn tại';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau';
      default:
        return 'Lỗi đăng nhập: ${e.message}';
    }
  }

  Future<void> logout() async {
    await _loginRequest.logout();
    _currentUser = null;
    _safeNotify();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }
}