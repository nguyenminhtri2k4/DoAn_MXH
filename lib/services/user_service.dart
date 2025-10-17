// lib/services/user_service.dart
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

  UserService() {
    // Ngay lập tức lắng nghe thay đổi trạng thái đăng nhập
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _isLoading = false;
    } else {
      _isLoading = true;
      notifyListeners();
      try {
        _currentUser = await _userRequest.getUserByUid(firebaseUser.uid);
      } catch (e) {
        print("Lỗi khi tải dữ liệu người dùng trong UserService: $e");
        _currentUser = null;
      } finally {
        _isLoading = false;
      }
    }
    notifyListeners();
  }

  Future<void> reloadUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _isLoading = true;
      notifyListeners();
      _currentUser = await _userRequest.getUserByUid(firebaseUser.uid);
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}