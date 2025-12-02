import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/constant/app_colors.dart'; // Đảm bảo import đúng đường dẫn AppColors

class BannedView extends StatelessWidget {
  const BannedView({super.key});

  @override
  Widget build(BuildContext context) {
    // Chặn nút Back vật lý và cử chỉ vuốt Back
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.block_flipped,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tài khoản bị khóa',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tài khoản của bạn đã vi phạm tiêu chuẩn cộng đồng và hiện đang bị vô hiệu hóa. Bạn không thể tiếp tục truy cập ứng dụng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      // Đăng xuất khỏi Firebase Auth
                      await FirebaseAuth.instance.signOut();
                      // UserService lắng nghe authStateChanges sẽ tự động đưa về LoginView
                    },
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}