
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/model/model_user.dart';

class GeneralSettingsViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRequest _userRequest = UserRequest();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Thông tin user hiện tại (lấy từ Firestore)
  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Load user ngay khi khởi tạo ViewModel
  GeneralSettingsViewModel() {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _setLoading(true);
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) {
        print('[GeneralSettingsViewModel] Không có user đăng nhập');
        return;
      }

      final userModel = await _userRequest.getUserByUid(authUser.uid);
      if (userModel != null) {
        _currentUserModel = userModel;
        print('Đã load user thành công: ${userModel.name}');
        print('→ Document ID (Firestore): ${userModel.id}');
        print('→ Auth UID: ${userModel.uid}');
      } else {
        print('Không tìm thấy document User cho UID: ${authUser.uid}');
      }
    } catch (e) {
      print('Lỗi load current user: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ===================================================================
  // ĐỔI MẬT KHẨU – ĐÃ SỬA CHÍNH XÁC 100%
  // ===================================================================
  Future<String?> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) return 'Bạn chưa đăng nhập';
      if (authUser.email == null) return 'Tài khoản không có email';

      // Validation
      if (currentPassword.isEmpty) return 'Vui lòng nhập mật khẩu hiện tại';
      if (newPassword.isEmpty) return 'Vui lòng nhập mật khẩu mới';
      if (newPassword.length < 6) return 'Mật khẩu mới phải từ 6 ký tự';
      if (currentPassword == newPassword) return 'Mật khẩu mới phải khác cũ';

      // 1. Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: authUser.email!,
        password: currentPassword,
      );
      await authUser.reauthenticateWithCredential(credential);

      // 2. Update password trên Firebase Auth
      await authUser.updatePassword(newPassword);

      // 3. Update timestamp trên Firestore → DÙNG DOCUMENT ID THẬT!
      if (_currentUserModel == null) {
        await _loadCurrentUser(); // reload nếu chưa có
      }
      if (_currentUserModel == null) return 'Không lấy được thông tin người dùng';

      await _firestore
          .collection('User')
          .doc(_currentUserModel!.id)  // ← ĐÚNG RỒI ĐÂY! Dùng .id (document ID)
          .update({
            'password': newPassword,
            'updatedPasswordAt': FieldValue.serverTimestamp()});

      _setLoading(false);
      return null; // thành công
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Mật khẩu hiện tại không đúng';
        case 'requires-recent-login':
          return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
        default:
          return 'Lỗi: ${e.message}';
      }
    } catch (e) {
      _setLoading(false);
      return 'Lỗi không xác định: $e';
    }
  }


  // ===================================================================
  // CẬP NHẬT CÀI ĐẶT KHUÔN MẶT (Lưu trong notificationSettings)
  // ===================================================================
  Future<bool> updateFaceAuthSetting(bool isEnabled) async {
    _setLoading(true);
    try {
      if (_currentUserModel == null) await _loadCurrentUser();
      if (_currentUserModel == null) return false;

      // Tạo map mới từ settings cũ để tránh lỗi reference
      final Map<String, bool> newSettings = Map<String, bool>.from(_currentUserModel!.notificationSettings);

      if (isEnabled) {
        newSettings['security_face_auth'] = true; // Lưu bật
      } else {
        newSettings.remove('security_face_auth'); // Tắt thì xóa key đi
      }

      // Cập nhật lên Firestore
      await _firestore
          .collection('User')
          .doc(_currentUserModel!.id)
          .update({'notificationSettings': newSettings});

      // Cập nhật lại model cục bộ
      _currentUserModel = _currentUserModel!.copyWith(notificationSettings: newSettings);
      
      _setLoading(false);
      return true;
    } catch (e) {
      print('Lỗi cập nhật Face Auth: $e');
      _setLoading(false);
      return false;
    }
  }

  // ===================================================================
  // XÓA TÀI KHOẢN – SOFT DELETE CHÍNH XÁC 100%
  // ===================================================================
  Future<String?> deleteAccount(String password) async {
    _setLoading(true);
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) return 'Bạn chưa đăng nhập';
      if (authUser.email == null) return 'Tài khoản không có email';
      if (password.isEmpty) return 'Vui lòng nhập mật khẩu để xác nhận';

      // 1. Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: authUser.email!,
        password: password,
      );
      await authUser.reauthenticateWithCredential(credential);

      // 2. Lấy document ID thật sự từ Firestore
      if (_currentUserModel == null) {
        await _loadCurrentUser();
      }
      if (_currentUserModel == null) {
        return 'Không tìm thấy thông tin tài khoản trong hệ thống';
      }

      final String realDocId = _currentUserModel!.id; // ← CHÍNH XÁC!

      // 3. Soft delete trên Firestore
      await _userRequest.deleteUser(realDocId); // ← Hàm deleteUser nhận document ID
      print('Soft delete thành công: $realDocId');

      // 4. Xóa hoàn toàn Firebase Auth (phải làm cuối cùng)
      await authUser.delete();
      print('Đã xóa tài khoản Firebase Auth');

      _setLoading(false);
      return null; // thành công
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Mật khẩu không đúng';
        case 'requires-recent-login':
          return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
        default:
          return 'Lỗi xác thực: ${e.message}';
      }
    } catch (e) {
      _setLoading(false);
      return 'Lỗi nghiêm trọng: $e';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}