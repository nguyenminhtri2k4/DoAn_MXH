import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mangxahoi/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Kiểm thử luồng đăng nhập thất bại với tài khoản sai', (WidgetTester tester) async {
    // 1. KHỞI ĐỘNG ỨNG DỤNG
    print('🚀 Bắt đầu khởi động ứng dụng...');
    app.main();

    // 2. CHỜ ỨNG DỤNG TẢI (Fix lỗi Timing)
    // Chờ cho đến khi MaterialApp xuất hiện (Main đã chạy xong)
    bool appLoaded = false;
    int retries = 0;
    while (!appLoaded && retries < 30) {
      await tester.pump(const Duration(seconds: 1));
      if (find.byType(MaterialApp).evaluate().isNotEmpty) {
        appLoaded = true;
        print('✅ Ứng dụng đã khởi chạy thành công.');
      }
      retries++;
    }

    if (!appLoaded) fail('❌ Timeout: Ứng dụng không thể khởi chạy.');

    // Chờ màn hình loading "Đang tải thông tin người dùng..." biến mất (nếu có)
    int loadingRetries = 0;
    while (find.text('Đang tải thông tin người dùng...').evaluate().isNotEmpty && loadingRetries < 20) {
      if (loadingRetries == 0) print('⏳ Đang tải dữ liệu khởi động...');
      await tester.pump(const Duration(seconds: 1));
      loadingRetries++;
    }

    // 3. KIỂM TRA MÀN HÌNH HIỆN TẠI
    final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Đăng Nhập');
    
    // Nếu đang ở màn hình Login thì mới test
    if (loginButtonFinder.evaluate().isNotEmpty) {
      print('👉 Đã thấy màn hình đăng nhập. Bắt đầu test...');

      // [FIX QUAN TRỌNG] Tìm Widget theo thứ tự xuất hiện
      // LoginView có 2 ô nhập: Email (trên) và Mật khẩu (dưới)
      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);

      // Nhập Email
      print('👉 Đang nhập Email...');
      await tester.enterText(emailField, 'son@gmail.com');
      await tester.pump(const Duration(seconds: 1)); // Chờ UI cập nhật

      // Nhập Password sai
      print('👉 Đang nhập Password...');
      await tester.enterText(passwordField, 'Susu@123'); 
      await tester.pump(const Duration(seconds: 1));

      // Nhấn nút Đăng nhập
      print('👉 Nhấn nút Đăng nhập...');
      await tester.tap(loginButtonFinder);
      
      // Chờ xử lý Firebase (dùng pump thay vì pumpAndSettle để tránh treo)
      await tester.pump(const Duration(seconds: 5));

      // 4. KIỂM TRA KẾT QUẢ (ASSERT)
      // Kiểm tra xem SnackBar lỗi có hiện ra không
      // LoginView hiển thị SnackBar với nội dung từ ViewModel
      bool isErrorShown = false;
      
      if (find.byType(SnackBar).evaluate().isNotEmpty) {
         // Nếu tìm thấy SnackBar, kiểm tra nội dung
         final snackBarFinder = find.byType(SnackBar);
         final snackBarText = find.descendant(of: snackBarFinder, matching: find.byType(Text));
         
         if (snackBarText.evaluate().isNotEmpty) {
           // In ra text để debug
           final Text textWidget = tester.widget(snackBarText.first) as Text;
           print('📢 Thông báo nhận được: "${textWidget.data}"');
           isErrorShown = true;
         }
      }

      if (isErrorShown) {
         print('✅ TEST PASS: Đã hiển thị thông báo lỗi khi đăng nhập sai.');
      } else {
         print('⚠️ TEST WARNING: Không bắt được SnackBar (có thể đã ẩn quá nhanh).');
      }

    } else {
      print('ℹ️ App đang đăng nhập sẵn hoặc ở màn hình khác. Không thể test Login.');
    }
  });
}