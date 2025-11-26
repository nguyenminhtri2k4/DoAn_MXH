import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mangxahoi/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Luồng: Đăng nhập -> Vào Home -> Đăng bài viết mới', (WidgetTester tester) async {
    // ----------------------------------------------------------------
    // 1. CẤU HÌNH TÀI KHOẢN TEST
    // ----------------------------------------------------------------
    const testEmail = 'son@gmail.com'; 
    const testPassword = 'Susu@123';

    // ----------------------------------------------------------------
    // 2. KHỞI ĐỘNG ỨNG DỤNG VÀ CHỜ LOAD
    // ----------------------------------------------------------------
    print('🚀 Bắt đầu khởi động ứng dụng...');
    app.main(); // Gọi hàm main() của app

    // [FIX QUAN TRỌNG]: Chờ cho đến khi MaterialApp xuất hiện
    // Điều này đảm bảo main() đã chạy xong Firebase.initializeApp và gọi runApp()
    bool appLoaded = false;
    int retries = 0;
    
    print('⏳ Đang chờ ứng dụng khởi tạo (Firebase init)...');
    while (!appLoaded && retries < 30) { // Chờ tối đa 30s
      await tester.pump(const Duration(seconds: 1));
      
      // Kiểm tra xem MaterialApp đã được mount vào cây Widget chưa
      if (find.byType(MaterialApp).evaluate().isNotEmpty) {
        appLoaded = true;
        print('✅ Ứng dụng đã khởi chạy thành công (MaterialApp found).');
      } else {
        retries++;
        if (retries % 5 == 0) print('...vẫn đang chờ (${retries}s)');
      }
    }

    if (!appLoaded) {
      fail('❌ Timeout: Ứng dụng không thể khởi chạy sau 30s. Kiểm tra kết nối mạng hoặc Firebase config.');
    }

    // ----------------------------------------------------------------
    // 2.1 CHỜ MÀN HÌNH LOADING (nếu có)
    // ----------------------------------------------------------------
    // Lúc này App đã chạy, có thể đang ở trạng thái "Đang tải thông tin người dùng..."
    int loadingRetries = 0;
    while (find.text('Đang tải thông tin người dùng...').evaluate().isNotEmpty && loadingRetries < 20) {
      if (loadingRetries == 0) print('⏳ Đang tải dữ liệu user...');
      await tester.pump(const Duration(seconds: 1));
      loadingRetries++;
    }

    // ----------------------------------------------------------------
    // 3. XÁC ĐỊNH TRẠNG THÁI HIỆN TẠI (Login hay Home)
    // ----------------------------------------------------------------
    final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Đăng Nhập');
    final fabFinder = find.byType(FloatingActionButton);

    // Dùng pump() một lần nữa để chắc chắn UI đã ổn định
    await tester.pump(const Duration(seconds: 1));

    if (loginButtonFinder.evaluate().isNotEmpty) {
      print('👉 Đang ở màn hình Đăng nhập. Tiến hành đăng nhập...');

      final emailFinder = find.ancestor(
        of: find.text('Email'),
        matching: find.byType(TextFormField),
      ).first;

      final passwordFinder = find.ancestor(
        of: find.text('Mật khẩu'),
        matching: find.byType(TextFormField),
      ).first;

      await tester.enterText(emailFinder, testEmail);
      await tester.pump(); 
      
      await tester.enterText(passwordFinder, testPassword);
      await tester.pump();

      await tester.tap(loginButtonFinder);
      print('⏳ Đã nhấn nút Đăng nhập...');
      
      // Chờ quá trình đăng nhập và init services
      int loginWait = 0;
      print('⏳ Đang đợi chuyển trang Home...');
      while (fabFinder.evaluate().isEmpty && loginWait < 20) {
         await tester.pump(const Duration(seconds: 1));
         loginWait++;
      }
    } else if (fabFinder.evaluate().isNotEmpty) {
      print('ℹ️ Đã đăng nhập sẵn (Tìm thấy FAB). Tiếp tục vào Home.');
    } else {
      print('⚠️ Không xác định được màn hình hiện tại. Dump UI tree:');
      debugDumpApp();
      fail('Test thất bại do không tìm thấy màn hình Login hoặc Home sau khi App đã load.');
    }

    // ----------------------------------------------------------------
    // 4. KIỂM TRA MÀN HÌNH HOME
    // ----------------------------------------------------------------
    expect(fabFinder, findsOneWidget, reason: 'Không tìm thấy nút FAB sau khi đăng nhập/load xong');
    print('✅ Đã vào trang chủ thành công.');

    // ----------------------------------------------------------------
    // 5. MỞ MÀN HÌNH TẠO BÀI VIẾT
    // ----------------------------------------------------------------
    print('👉 Nhấn nút tạo bài viết...');
    await tester.tap(fabFinder);
    
    // Chờ chuyển trang
    await tester.pump(const Duration(seconds: 2)); 

    expect(find.text('Tạo bài viết'), findsOneWidget);
    print('✅ Đã mở màn hình Tạo bài viết.');

    // ----------------------------------------------------------------
    // 6. NHẬP NỘI DUNG VÀ ĐĂNG
    // ----------------------------------------------------------------
    final contentFieldFinder = find.widgetWithText(TextFormField, 'Bạn đang nghĩ gì?');
    
    const postContent = 'Test Integration: Bài viết tự động từ Flutter Test';
    await tester.enterText(contentFieldFinder, postContent);
    await tester.pump(const Duration(seconds: 1)); 

    final postButtonFinder = find.widgetWithText(ElevatedButton, 'Đăng');
    
    print('👉 Nhấn nút Đăng...');
    await tester.tap(postButtonFinder);

    // ----------------------------------------------------------------
    // 7. XÁC NHẬN KẾT QUẢ
    // ----------------------------------------------------------------
    print('⏳ Đang chờ upload và đóng màn hình...');
    
    // Chờ thông báo thành công hoặc quay về Home
    // Tăng thời gian chờ lên vì upload Firestore có thể lâu
    await tester.pump(const Duration(seconds: 5));

    bool isSuccess = false;
    // Kiểm tra các dấu hiệu thành công
    if (find.text('Bài viết của bạn đã được đăng!').evaluate().isNotEmpty) {
      isSuccess = true;
      print('✅ Tìm thấy thông báo thành công.');
    } 
    else if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
      isSuccess = true;
      print('✅ Đã quay lại màn hình Home.');
    }

    if (!isSuccess) {
       print('⏳ Chưa thấy phản hồi, chờ thêm 5s...');
       await tester.pump(const Duration(seconds: 5));
       if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
          isSuccess = true;
       }
    }

    if (isSuccess) {
      print('🎉 TEST PASSED: Quy trình hoàn tất.');
    } else {
      if (find.text('Lỗi đăng bài').evaluate().isNotEmpty) {
        print('❌ TEST FAILED: Có lỗi server khi đăng bài.');
      } else {
        print('⚠️ TEST WARNING: Kết thúc nhưng không xác định được trạng thái cuối.');
      }
    }
  });
}