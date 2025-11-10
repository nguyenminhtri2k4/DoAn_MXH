
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/authanet/firestore_service.dart';
import 'package:mangxahoi/model/model_user.dart';

class RegisterViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // ==================== TRẠNG THÁI ====================
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEmailVerified = false;
  bool _isOtpSent = false;
  String? _pendingUid; // Lưu UID tạm thời

  // ==================== CONTROLLER ====================
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ==================== GETTERS ====================
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmailVerified => _isEmailVerified;
  bool get isOtpSent => _isOtpSent;

  // ==================== VALIDATION ====================
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != passwordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  // ==================== BƯỚC 1: GỬI EMAIL XÁC THỰC ====================
  Future<bool> sendVerificationEmail() async {
    if (!formKey.currentState!.validate()) return false;

    final email = emailController.text.trim();
    final password = passwordController.text;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📧 Bắt đầu gửi email xác thực cho: $email');
      
      // Tạo tài khoản Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _pendingUid = userCredential.user!.uid;
      print('✅ Tạo tài khoản Auth thành công, UID: $_pendingUid');

      // Gửi email xác thực
      await userCredential.user!.sendEmailVerification();
      print('✅ Email xác thực đã được gửi đến: $email');
      
      _isOtpSent = true;
      _isLoading = false;
      notifyListeners();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      print('❌ Lỗi Firebase Auth: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'email-already-in-use':
          _errorMessage = 'Email này đã được đăng ký';
          break;
        case 'invalid-email':
          _errorMessage = 'Email không hợp lệ';
          break;
        case 'weak-password':
          _errorMessage = 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
          break;
        case 'operation-not-allowed':
          _errorMessage = 'Tính năng đăng ký chưa được kích hoạt';
          break;
        case 'network-request-failed':
          _errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet';
          break;
        default:
          _errorMessage = e.message ?? 'Lỗi không xác định';
      }
      
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi không xác định: ${e.toString()}';
      print('❌ Lỗi không xác định: $e');
      notifyListeners();
      return false;
    }
  }

  // ==================== BƯỚC 2: KIỂM TRA XÁC THỰC EMAIL ====================
  Future<bool> checkEmailVerification() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔍 Đang kiểm tra trạng thái xác thực email...');
      
      // Reload user để cập nhật trạng thái
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user == null) {
        _isLoading = false;
        _errorMessage = 'Không tìm thấy người dùng. Vui lòng thử lại.';
        notifyListeners();
        return false;
      }

      if (user.emailVerified) {
        print('✅ Email đã được xác thực thành công!');
        _isEmailVerified = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('⚠️ Email chưa được xác thực');
        _isLoading = false;
        _errorMessage = 'Email chưa được xác thực. Vui lòng kiểm tra hộp thư và nhấn vào liên kết xác thực.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi khi kiểm tra xác thực: ${e.toString()}';
      print('❌ Lỗi khi kiểm tra xác thực: $e');
      notifyListeners();
      return false;
    }
  }

  // ==================== BƯỚC 3: HOÀN TẤT ĐĂNG KÝ (LƯU VÀO FIRESTORE) ====================
  Future<bool> completeRegistration() async {
    if (!_isEmailVerified) {
      _errorMessage = 'Vui lòng xác thực email trước';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null || _pendingUid == null) {
        _errorMessage = 'Không tìm thấy thông tin người dùng';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('💾 Bắt đầu lưu thông tin user vào Firestore...');

      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final phone = phoneController.text.trim();
      final password = passwordController.text;

      // Tạo UserModel
      final newUser = UserModel(
        id: '', // Để trống, sẽ được gán trong saveUser
        uid: _pendingUid!,
        name: name.isNotEmpty ? name : email.split('@').first,
        email: email,
        password: password,
        phone: phone,
        bio: 'Xin chào! Tôi là người dùng mới',
        gender: '',
        liveAt: '',
        comeFrom: '',
        role: 'user',
        relationship: '',
        statusAccount: 'active',
        backgroundImageUrl: '',
        avatar: [],
        friends: [],
        locketFriends: [],
        groups: [],
        posterList: [],
        followerCount: 0,
        followingCount: 0,
        createAt: DateTime.now(),
        dateOfBirth: null,
        lastActive: DateTime.now(),
        notificationSettings: {
          'comments': true,
          'friendRequests': true,
          'likes': true,
          'messages': true,
          'tags': true,
        },
      );

      // Lưu vào Firestore
      final docId = await _firestoreService.saveUser(newUser);
      print('✅ Đã lưu user vào Firestore với document ID: $docId');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi khi lưu thông tin: ${e.toString()}';
      print('❌ Lỗi khi lưu thông tin user: $e');
      notifyListeners();
      return false;
    }
  }

  // ==================== GỬI LẠI EMAIL XÁC THỰC ====================
  Future<void> resendVerificationEmail() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        print('✅ Email xác thực đã được gửi lại');
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể gửi lại email. Vui lòng chờ một chút và thử lại.';
      print('❌ Lỗi khi gửi lại email: $e');
      notifyListeners();
    }
  }

  // ==================== HỦY ĐĂNG KÝ ====================
  Future<void> cancelRegistration() async {
    try {
      print('🚫 Đang hủy quá trình đăng ký...');
      
      final user = _auth.currentUser;
      if (user != null) {
        // Xóa tài khoản Auth nếu chưa hoàn tất
        await user.delete();
        print('✅ Đã xóa tài khoản Auth');
      }
      
      await _auth.signOut();
      
      _isOtpSent = false;
      _isEmailVerified = false;
      _pendingUid = null;
      _errorMessage = null;
      
      notifyListeners();
      print('✅ Đã hủy đăng ký thành công');
    } catch (e) {
      _errorMessage = 'Lỗi khi hủy đăng ký: ${e.toString()}';
      print('❌ Lỗi khi hủy đăng ký: $e');
      notifyListeners();
    }
  }

  // ==================== CLEAR ERROR ====================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== DISPOSE ====================
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}