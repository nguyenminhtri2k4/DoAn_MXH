import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRequest _userRequest = UserRequest();

  UserModel? currentUserData;
  bool isLoading = false;

  /// 📥 Lấy thông tin người dùng hiện tại
  Future<void> loadCurrentUser() async {
    try {
      isLoading = true;
      notifyListeners();

      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        currentUserData = null;
        return;
      }

      // Lấy thông tin từ Firestore
      final user = await _userRequest.getUserByUid(firebaseUser.uid);
      currentUserData = user;
    } catch (e) {
      print('❌ Lỗi khi tải thông tin người dùng: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 🚪 Đăng xuất tài khoản
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('❌ Lỗi khi đăng xuất: $e');
    }
  }
}
