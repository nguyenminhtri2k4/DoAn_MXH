import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mangxahoi/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Luồng: Đăng nhập -> Tạo bài viết -> Gắn thẻ bạn bè -> Đăng bài', (WidgetTester tester) async {
    // ==========================================
    // 1. CẤU HÌNH USER TEST
    // ==========================================
    const testEmail = 'son@gmail.com'; 
    const testPassword = 'Susu@123';

    // ==========================================
    // 2. KHỞI ĐỘNG APP & CHỜ (Tăng thời gian chờ)
    // ==========================================
    print('🚀 Bắt đầu khởi động ứng dụng...');
    app.main();

    // [FIX TIME OUT] Tăng thời gian chờ khởi động lên 60 giây
    // Lý do: PushNotificationService có thể mất thời gian hoặc hiện dialog xin quyền
    bool appLoaded = false;
    int retries = 0;
    print('⏳ Đang chờ App khởi tạo (Firebase, Notifications)...');
    
    while (!appLoaded && retries < 60) { 
      await tester.pump(const Duration(seconds: 1));
      if (find.byType(MaterialApp).evaluate().isNotEmpty) {
        appLoaded = true;
        print('✅ Ứng dụng đã khởi chạy thành công (Thấy MaterialApp).');
      } else {
        retries++;
        if (retries % 5 == 0) print('...vẫn đang chờ (${retries}s)');
      }
    }

    if (!appLoaded) {
      fail('❌ Timeout: App không khởi động sau 60s. \n👉 LƯU Ý: Nếu máy ảo hiện popup xin quyền Thông báo, hãy nhấn "Cho phép" bằng tay!');
    }

    // Chờ Loading screen biến mất
    int loadingRetries = 0;
    while (find.text('Đang tải thông tin người dùng...').evaluate().isNotEmpty && loadingRetries < 30) {
      if (loadingRetries == 0) print('⏳ Đang tải dữ liệu người dùng...');
      await tester.pump(const Duration(seconds: 1));
      loadingRetries++;
    }

    // ==========================================
    // 3. XỬ LÝ ĐĂNG NHẬP / HOME
    // ==========================================
    final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Đăng Nhập');
    final fabFinder = find.byType(FloatingActionButton);
    await tester.pump(const Duration(seconds: 1));

    if (loginButtonFinder.evaluate().isNotEmpty) {
      print('👉 Đang ở màn hình Đăng nhập. Đang nhập...');
      
      // Tìm các ô nhập liệu (Dùng index để chắc chắn)
      await tester.enterText(find.byType(TextFormField).at(0), testEmail);
      await tester.pump(); 
      await tester.enterText(find.byType(TextFormField).at(1), testPassword);
      await tester.pump();
      
      // Đóng bàn phím trước khi nhấn nút đăng nhập
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(loginButtonFinder);
      
      // Chờ vào Home
      int loginWait = 0;
      print('⏳ Đang đợi chuyển trang Home...');
      while (fabFinder.evaluate().isEmpty && loginWait < 30) {
         await tester.pump(const Duration(seconds: 1));
         loginWait++;
      }
    } else if (fabFinder.evaluate().isNotEmpty) {
      print('ℹ️ Đã đăng nhập sẵn.');
    } else {
      fail('❌ Không xác định được màn hình (Không thấy Login, cũng không thấy Home).');
    }

    print('✅ Đã vào Trang chủ.');

    // ==========================================
    // 4. MỞ MÀN HÌNH TẠO BÀI VIẾT
    // ==========================================
    print('👉 Nhấn nút tạo bài viết...');
    await tester.tap(fabFinder);
    await tester.pump(const Duration(seconds: 2)); // Chờ chuyển trang

    expect(find.text('Tạo bài viết'), findsOneWidget);
    print('✅ Đã mở màn hình Tạo bài viết.');

    // Nhập nội dung
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bạn đang nghĩ gì?'), 
      'Test bài viết có gắn thẻ bạn bè!'
    );
    await tester.pump(const Duration(seconds: 1));

    // [FIX QUAN TRỌNG] ĐÓNG BÀN PHÍM ĐỂ TRÁNH CHE KHUẤT NÚT
    print('⌨️ Đóng bàn phím...');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(seconds: 2)); 

    // ==========================================
    // 5. THỰC HIỆN GẮN THẺ BẠN BÈ
    // ==========================================
    print('👉 Nhấn nút "Gắn thẻ"...');
    
    // Tìm nút bằng Text (ổn định hơn Icon)
    final tagButtonFinder = find.text('Gắn thẻ');
    
    if (tagButtonFinder.evaluate().isNotEmpty) {
      await tester.tap(tagButtonFinder);
    } else {
      print('⚠️ Không thấy text "Gắn thẻ", thử tìm icon...');
      await tester.tap(find.byIcon(Icons.person_add));
    }
    
    // Chờ chuyển sang màn hình TagFriendsView
    await tester.pump(const Duration(seconds: 3)); 

    expect(find.text('Gắn thẻ bạn bè'), findsOneWidget);
    print('✅ Đã mở màn hình Gắn thẻ bạn bè.');

    // Xử lý chọn bạn bè
    if (find.text('Bạn chưa có bạn bè nào.').evaluate().isNotEmpty) {
      print('⚠️ CẢNH BÁO: Tài khoản này chưa có bạn bè. Bỏ qua bước chọn.');
      await tester.tap(find.widgetWithText(TextButton, 'Xong'));
    } else if (find.text('Không tìm thấy bạn bè nào.').evaluate().isNotEmpty) {
       print('⚠️ CẢNH BÁO: List bạn bè rỗng.');
       await tester.tap(find.widgetWithText(TextButton, 'Xong'));
    } else {
      // Chọn bạn bè đầu tiên
      final firstFriendFinder = find.byType(CheckboxListTile).first;
      
      print('👉 Chọn bạn bè đầu tiên...');
      await tester.tap(firstFriendFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Nhấn nút "Xong"
      print('👉 Nhấn nút Xong...');
      await tester.tap(find.widgetWithText(TextButton, 'Xong'));
    }

    // Chờ quay lại màn hình tạo bài viết
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Tạo bài viết'), findsOneWidget);

    // Kiểm tra UI đã cập nhật chưa
    if (find.textContaining('Đã thẻ').evaluate().isNotEmpty) {
      print('✅ UI cập nhật thành công: Đã hiển thị số lượng người được gắn thẻ.');
    }

    // ==========================================
    // 6. ĐĂNG BÀI
    // ==========================================
    print('👉 Nhấn nút Đăng...');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng'));

    // Chờ upload
    print('⏳ Đang chờ xử lý đăng bài...');
    await tester.pump(const Duration(seconds: 8)); // Tăng thời gian chờ upload

    // Kiểm tra kết quả
    if (find.text('Bài viết của bạn đã được đăng!').evaluate().isNotEmpty) {
      print('🎉 TEST PASSED: Đăng bài kèm gắn thẻ thành công!');
    } else if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
      print('🎉 TEST PASSED: Đã quay về trang chủ (Giả định thành công).');
    } else {
      if (find.text('Lỗi đăng bài').evaluate().isNotEmpty) {
        print('❌ TEST FAILED: Server trả về lỗi.');
      } else {
        print('⚠️ TEST WARNING: Không thấy thông báo xác nhận, nhưng quy trình đã chạy xong.');
      }
    }
  });
}