
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/viewmodel/general_settings_viewmodel.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/view/login_view.dart';

class GeneralSettingsView extends StatelessWidget {
  const GeneralSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GeneralSettingsViewModel(),
      child: const _GeneralSettingsViewContent(),
    );
  }
}

class _GeneralSettingsViewContent extends StatefulWidget {
  const _GeneralSettingsViewContent();

  @override
  State<_GeneralSettingsViewContent> createState() => _GeneralSettingsViewContentState();
}

class _GeneralSettingsViewContentState extends State<_GeneralSettingsViewContent> {
  bool _isLoadingGemini = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralSettingsViewModel>();
    final userService = context.watch<UserService>();
    final currentUser = userService.currentUser;
    final isProAccount = currentUser?.statusAccount == 'Pro';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Cài đặt chung', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              const SizedBox(height: 12),

              // --- SECTION TÀI KHOẢN ---
              Container(
                color: Colors.white,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_outline, color: AppColors.primary),
                    ),
                    title: const Text(
                      'Tài khoản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    children: [
                      // Mục 1: Đổi mật khẩu
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 72, right: 16),
                        leading: const Icon(Icons.lock_reset, size: 22, color: Colors.grey),
                        title: const Text('Đổi mật khẩu'),
                        onTap: () => _showChangePasswordDialog(context, vm),
                      ),
                      // Mục 2: Xóa tài khoản
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 72, right: 16),
                        leading: const Icon(Icons.delete_forever_outlined, size: 22, color: Colors.red),
                        title: const Text('Xóa tài khoản', style: TextStyle(color: Colors.red)),
                        onTap: () => _showDeleteAccountDialog(context, vm),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // --- SECTION GỢI Ý AI (CHỈ HIỆN KHI LÀ PRO) ---
              if (isProAccount && currentUser != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  color: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.purple.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(12),
                    child: SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.purple),
                      ),
                      title: const Text(
                        'Gợi ý tin nhắn với AI',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: const Text(
                        'Sử dụng Gemini để gợi ý câu trả lời nhanh trong tin nhắn.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: currentUser.serviceGemini,
                      activeColor: Colors.purple,
                      onChanged: _isLoadingGemini
                          ? null
                          : (bool value) async {
                              setState(() => _isLoadingGemini = true);
                              try {
                                // 1. Gọi API cập nhật Firestore
                                await UserRequest().updateServiceGemini(currentUser.id, value);

                                // 2. Cập nhật UI Local
                                if (mounted) {
                                  userService.setCurrentUser(
                                    currentUser.copyWith(serviceGemini: value),
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(value ? '✅ Đã bật gợi ý AI' : '❌ Đã tắt gợi ý AI'),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: value ? Colors.green : Colors.orange,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoadingGemini = false);
                                }
                              }
                            },
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: Text(
                    '✨ Tính năng dành riêng cho tài khoản Pro',
                    style: TextStyle(fontSize: 11, color: Colors.purple, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // --- SECTION BẢO MẬT (FACE AUTH) ---
             
              Container(
                color: Colors.white,
                child: SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.face_retouching_natural, color: Colors.blueAccent),
                  ),
                  title: const Text('Bảo mật khuôn mặt', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'Yêu cầu quét khuôn mặt khi mở ứng dụng.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  // Logic hiển thị: Nếu key tồn tại và là true thì Bật, ngược lại Tắt
                  value: currentUser?.notificationSettings['security_face_auth'] == true,
                  activeColor: Colors.blueAccent,
                  onChanged: vm.isLoading
                      ? null
                      : (bool value) async {
                          // 1. Gọi API cập nhật Firestore
                          bool success = await vm.updateFaceAuthSetting(value);

                          if (success && mounted && currentUser != null) {
                            // 2. Xử lý logic Map Local: Bật thì thêm/update, Tắt thì xóa
                            // SỬA LỖI TẠI ĐÂY: Dùng Map<String, bool> thay vì dynamic
                            final updatedSettings = Map<String, bool>.from(currentUser.notificationSettings);
                            
                            if (value) {
                              updatedSettings['security_face_auth'] = true;
                            } else {
                              updatedSettings.remove('security_face_auth');
                            }

                            // 3. Cập nhật UI Local ngay lập tức
                            userService.setCurrentUser(
                              currentUser.copyWith(
                                notificationSettings: updatedSettings, // Giờ kiểu dữ liệu đã khớp
                              ),
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value ? '✅ Đã bật xác thực khuôn mặt' : 'Đã tắt xác thực khuôn mặt'),
                                backgroundColor: value ? Colors.green : Colors.grey,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                ),
              ),
              
              const SizedBox(height: 12),

              // --- SECTION THÔNG BÁO ---
              Container(
                color: Colors.white,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none, color: Colors.orange),
                  ),
                  title: const Text('Thông báo'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pushNamed(context, '/notification_settings');
                  },
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),

          // Loading Indicator
          if (vm.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // --- DIALOG ĐỔI MẬT KHẨU ---
  // --- DIALOG ĐỔI MẬT KHẨU (THIẾT KẾ ĐẸP) ---
void _showChangePasswordDialog(BuildContext context, GeneralSettingsViewModel vm) {
  final currentPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== HEADER =====
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_outline, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đổi mật khẩu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cập nhật mật khẩu của bạn',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ===== CONTENT =====
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mật khẩu hiện tại
                      _buildPasswordField(
                        controller: currentPassCtrl,
                        label: 'Mật khẩu hiện tại',
                        hint: 'Nhập mật khẩu hiện tại',
                        icon: Icons.lock,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Mật khẩu mới
                      _buildPasswordField(
                        controller: newPassCtrl,
                        label: 'Mật khẩu mới',
                        hint: 'Tối thiểu 6 ký tự',
                        icon: Icons.vpn_key,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Gợi ý độ mạnh
                      if (newPassCtrl.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: newPassCtrl.text.length >= 6
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: newPassCtrl.text.length >= 6
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                newPassCtrl.text.length >= 6 ? Icons.check_circle : Icons.info,
                                color: newPassCtrl.text.length >= 6 ? Colors.green : Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  newPassCtrl.text.length >= 6
                                      ? '✅ Mật khẩu hợp lệ'
                                      : '⚠️ Tối thiểu 6 ký tự',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: newPassCtrl.text.length >= 6
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Xác nhận mật khẩu
                      _buildPasswordField(
                        controller: confirmPassCtrl,
                        label: 'Xác nhận mật khẩu mới',
                        hint: 'Nhập lại mật khẩu mới',
                        icon: Icons.check_circle_outline,
                        onChanged: (_) => setState(() {}),
                        error: (newPassCtrl.text.isNotEmpty &&
                                confirmPassCtrl.text.isNotEmpty &&
                                newPassCtrl.text != confirmPassCtrl.text)
                            ? 'Mật khẩu không khớp'
                            : null,
                      ),

                      // Thông báo khớp
                      if (newPassCtrl.text.isNotEmpty && confirmPassCtrl.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: newPassCtrl.text == confirmPassCtrl.text
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: newPassCtrl.text == confirmPassCtrl.text
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  newPassCtrl.text == confirmPassCtrl.text
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: newPassCtrl.text == confirmPassCtrl.text
                                      ? Colors.green
                                      : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  newPassCtrl.text == confirmPassCtrl.text
                                      ? '✅ Mật khẩu khớp'
                                      : '❌ Mật khẩu không khớp',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: newPassCtrl.text == confirmPassCtrl.text
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ===== ACTIONS =====
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (newPassCtrl.text.isEmpty ||
                                      confirmPassCtrl.text.isEmpty ||
                                      newPassCtrl.text != confirmPassCtrl.text ||
                                      newPassCtrl.text.length < 6)
                              ? Colors.grey.shade300
                              : Colors.blue.shade500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: (newPassCtrl.text.isEmpty ||
                                    confirmPassCtrl.text.isEmpty ||
                                    newPassCtrl.text != confirmPassCtrl.text ||
                                    newPassCtrl.text.length < 6)
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                final error = await vm.changePassword(
                                  currentPassCtrl.text.trim(),
                                  newPassCtrl.text.trim(),
                                );

                                if (context.mounted) {
                                  if (error == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('✅ Đổi mật khẩu thành công!'),
                                        backgroundColor: Colors.green.shade400,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: Colors.red.shade400,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: const Text('Cập nhật', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// === HELPER FUNCTION ===
Widget _buildPasswordField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  required Function(String) onChanged,
  String? error,
}) {
  return StatefulBuilder(
    builder: (context, setState) {
      bool isObscured = true;

      return StatefulBuilder(
        builder: (context, setFieldState) => TextField(
          controller: controller,
          obscureText: isObscured,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blue.shade400, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                isObscured ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
                size: 20,
              ),
              onPressed: () => setFieldState(() => isObscured = !isObscured),
            ),
            errorText: error,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );
    },
  );
}

  // --- DIALOG XÓA TÀI KHOẢN ---
  void _showDeleteAccountDialog(BuildContext context, GeneralSettingsViewModel vm) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa vĩnh viễn?', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hành động này sẽ xóa tất cả dữ liệu, bài viết và tin nhắn của bạn. Không thể hoàn tác!',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text('Nhập mật khẩu để xác nhận:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                hintText: 'Mật khẩu của bạn',
                prefixIcon: Icon(Icons.lock_outline, size: 20),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await vm.deleteAccount(passCtrl.text.trim());

              if (context.mounted) {
                if (error == null) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginView()),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tài khoản đã được xóa.'),
                      backgroundColor: Colors.grey,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('XÓA NGAY', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}