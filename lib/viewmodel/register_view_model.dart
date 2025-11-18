
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
  String? _pendingUid;
  bool _isCompleting = false; // ✅ Ngăn nhấn nhiều lần

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
  bool get isCompleting => _isCompleting;

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

  // ==================== HELPER: LOG VỚI TIMESTAMP ====================
  void _logWithTime(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] $message');
  }

  // ==================== BƯỚC 1: GỬI EMAIL XÁC THỰC ====================
  Future<bool> sendVerificationEmail() async {
    if (!formKey.currentState!.validate()) return false;

    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final startTime = DateTime.now();
    _logWithTime('📧 [START] Bắt đầu quy trình đăng ký cho: $email');

    try {
      // BƯỚC 1: Tạo Auth
      final authStart = DateTime.now();
      _logWithTime('🔑 [1/3] Đang tạo Firebase Auth...');
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _pendingUid = userCredential.user!.uid;
      final authDuration = DateTime.now().difference(authStart);
      _logWithTime('✅ [1/3] Auth thành công (${authDuration.inMilliseconds}ms), UID: $_pendingUid');

      // BƯỚC 2: Lưu Firestore NGAY LẬP TỨC
      final firestoreStart = DateTime.now();
      _logWithTime('💾 [2/3] Đang lưu vào Firestore...');
      
      final newUser = UserModel(
        id: '',
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

      // ✅ CHỜ LƯU HOÀN TẤT
      final docId = await _firestoreService.saveUser(newUser);
      final firestoreDuration = DateTime.now().difference(firestoreStart);
      _logWithTime('✅ [2/3] Firestore thành công (${firestoreDuration.inMilliseconds}ms), DocID: $docId');

      // BƯỚC 3: Gửi email (SAU KHI ĐÃ CÓ DOCUMENT)
      final emailStart = DateTime.now();
      _logWithTime('📧 [3/3] Đang gửi email xác thực...');
      
      await userCredential.user!.sendEmailVerification();
      
      final emailDuration = DateTime.now().difference(emailStart);
      final totalDuration = DateTime.now().difference(startTime);
      _logWithTime('✅ [3/3] Email đã gửi (${emailDuration.inMilliseconds}ms)');
      _logWithTime('🎉 [COMPLETE] Tổng thời gian: ${totalDuration.inMilliseconds}ms');
      
      _isOtpSent = true;
      _isLoading = false;
      notifyListeners();
      
      return true;
      
    } on FirebaseAuthException catch (e) {
      final errorDuration = DateTime.now().difference(startTime);
      _logWithTime('❌ [ERROR] Firebase Auth (${errorDuration.inMilliseconds}ms): ${e.code}');
      
      _isLoading = false;
      
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
          _errorMessage = 'Lỗi kết nối mạng';
          break;
        default:
          _errorMessage = e.message ?? 'Lỗi không xác định';
      }
      
      notifyListeners();
      return false;
      
    } catch (e) {
      final errorDuration = DateTime.now().difference(startTime);
      _logWithTime('❌ [ERROR] Lỗi không xác định (${errorDuration.inMilliseconds}ms): $e');
      
      _isLoading = false;
      _errorMessage = 'Lỗi: ${e.toString()}';
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
        _errorMessage = 'Email chưa được xác thực. Vui lòng kiểm tra hộp thư.';
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

  // ==================== BƯỚC 3: HOÀN TẤT ĐĂNG KÝ (CHỈ 1 LẦN) ====================
  Future<bool> completeRegistration() async {
    // ✅ Ngăn nhấn nhiều lần
    if (_isCompleting) {
      print('⚠️ [RegisterVM] Đang xử lý, bỏ qua request');
      return false;
    }

    if (!_isEmailVerified) {
      _errorMessage = 'Vui lòng xác thực email trước';
      notifyListeners();
      return false;
    }

    _isCompleting = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null || _pendingUid == null) {
        _errorMessage = 'Không tìm thấy thông tin người dùng';
        _isLoading = false;
        _isCompleting = false;
        notifyListeners();
        return false;
      }

      print('💾 Hoàn tất đăng ký (document đã được tạo ở bước 1)');
      print('✅ UID: $_pendingUid');
      
      _isLoading = false;
      // ✅ Giữ _isCompleting = true để disable nút
      notifyListeners();
      return true;
      
    } catch (e) {
      _isLoading = false;
      _isCompleting = false; // Reset để cho phép retry
      _errorMessage = 'Lỗi: ${e.toString()}';
      print('❌ Lỗi: $e');
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
      _errorMessage = 'Không thể gửi lại email. Vui lòng thử lại sau.';
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
        await user.delete();
        print('✅ Đã xóa tài khoản Auth');
      }
      
      await _auth.signOut();
      
      _isOtpSent = false;
      _isEmailVerified = false;
      _pendingUid = null;
      _errorMessage = null;
      _isCompleting = false;
      
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