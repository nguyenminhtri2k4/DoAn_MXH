import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/constant/app_colors.dart';

class GeneralSettingsView extends StatefulWidget {
  const GeneralSettingsView({super.key});

  @override
  State<GeneralSettingsView> createState() => _GeneralSettingsViewState();
}

class _GeneralSettingsViewState extends State<GeneralSettingsView> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin user hiện tại từ Provider
    final userService = context.watch<UserService>();
    final currentUser = userService.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Kiểm tra điều kiện tài khoản Pro
    final bool isProAccount = currentUser.statusAccount == 'Pro';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt chung"),
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Các cài đặt khác (ví dụ)
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Ngôn ngữ"),
            subtitle: const Text("Tiếng Việt"),
            onTap: () {},
          ),
          const Divider(),

          // --- PHẦN GỢI Ý TIN NHẮN AI (CHỈ HIỆN KHI LÀ PRO) ---
          if (isProAccount) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.2)), // Viền tím nhẹ cho đẹp
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                  "Gợi ý tin nhắn với AI",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Sử dụng Gemini để gợi ý câu trả lời nhanh trong tin nhắn.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: currentUser.serviceGemini, // Lấy giá trị từ Model
                activeColor: Colors.purple,
                onChanged: _isLoading
                    ? null
                    : (bool value) async {
                        setState(() => _isLoading = true);
                        try {
                          // 1. Gọi API cập nhật Firestore
                          await UserRequest().updateServiceGemini(currentUser.id, value);
                          
                          // 2. Cập nhật UI Local
                          userService.setCurrentUser(
                            currentUser!.copyWith(serviceGemini: value), // 👈 QUAN TRỌNG: Thêm dấu ! vào đây
                          );
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(value ? "Đã bật gợi ý AI" : "Đã tắt gợi ý AI"),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Lỗi: $e")),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Text(
                "✨ Tính năng dành riêng cho tài khoản Pro",
                style: TextStyle(fontSize: 11, color: Colors.purple, fontStyle: FontStyle.italic),
              ),
            ),
          ] else ...[
             // Nếu không phải Pro, có thể ẩn luôn hoặc hiện thông báo nâng cấp (tùy bạn)
             // Ở đây mình ẩn luôn theo yêu cầu của bạn.
          ],
        ],
      ),
    );
  }
}