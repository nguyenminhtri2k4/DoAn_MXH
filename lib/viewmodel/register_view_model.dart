import 'package:flutter/material.dart';
import 'package:mangxahoi/request/login_request.dart';

class RegisterViewModel extends ChangeNotifier {
  final LoginRequest _loginRequest = LoginRequest();

  // ==================== TRẠNG THÁI ====================
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== CONTROLLER ====================
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ==================== GETTERS ====================
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== LOGIC ====================
  Future<bool> register() async {
    if (!formKey.currentState!.validate()) return false;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _loginRequest.register(
        email,
        password,
        name: name,
        phone: phone,
      );

      _isLoading = false;

      if (userCredential != null) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
