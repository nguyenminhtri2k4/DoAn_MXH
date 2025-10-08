import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/authanet/firestore_service.dart';
import 'package:mangxahoi/model/model_user.dart';

class LoginRequest {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Đăng nhập - Tối ưu hóa
  Future<UserCredential?> login(String email, String password) async {
    try {
      print('🔐 Bắt đầu đăng nhập với email: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = userCredential.user!.uid;
      print('✅ Đăng nhập Firebase Auth thành công, UID: $uid');

      // Lấy user data từ Firestore theo Auth UID
      final userData = await _firestoreService.getUserDataByAuthUid(uid);
      if (userData == null) {
        print('⚠️ Không tìm thấy dữ liệu user trong Firestore cho uid: $uid');
      } else {
        print('✅ Đã tải dữ liệu user: ${userData.name}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Đăng nhập thất bại: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Lỗi đăng nhập: $e');
      rethrow;
    }
  }

  // Đăng ký - Tối ưu hóa
  Future<UserCredential?> register(
    String email,
    String password, {
    String? name,
    String? phone,
  }) async {
    try {
      print('📝 Bắt đầu đăng ký với email: $email');
      
      // Tạo user trong Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = userCredential.user!.uid;
      print('✅ Tạo tài khoản Auth thành công, UID: $uid');

      // Tạo UserModel tạm thời với uid
      final tempUser = UserModel(
        id: '', // ĐỂ TRỐNG, sẽ được gán trong saveUser
        uid: uid,
        name: name ?? email.split('@').first, // Tên mặc định từ email
        email: email,
        password: password,
        phone: phone ?? '',
        bio: 'Xin chào! Tôi là người dùng mới',
        gender: '',
        liveAt: '',
        comeFrom: '',
        role: 'user',
        relationship: '',
        statusAccount: 'active',
        avatar: [],
        friends: [],
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

      // Lưu vào Firestore và nhận document ID mới (user1, user2, user3...)
      final docId = await _firestoreService.saveUser(tempUser);
      print('✅ Đã lưu user vào Firestore với document ID: $docId');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Đăng ký thất bại: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Lỗi đăng ký: $e');
      rethrow;
    }
  }

  // Xử lý Firebase Auth exceptions - Cải tiến
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email không tồn tại trong hệ thống';
      case 'wrong-password':
        return 'Mật khẩu không chính xác';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng cho tài khoản khác';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn';
      case 'operation-not-allowed':
        return 'Tính năng đăng nhập bằng email/mật khẩu chưa được kích hoạt';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ quản trị viên';
      case 'too-many-requests':
        return 'Quá nhiều lần thử đăng nhập. Vui lòng thử lại sau vài phút';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet';
      default:
        return e.message ?? 'Đã xảy ra lỗi không xác định. Vui lòng thử lại';
    }
  }

  // Lấy user data theo document id
  Future<UserModel?> getUserData(String docId) async {
    try {
      print('📖 Đang lấy thông tin user với docId: $docId');
      final user = await _firestoreService.getUserData(docId);
      if (user != null) {
        print('✅ Đã tìm thấy user: ${user.name}');
      } else {
        print('⚠️ Không tìm thấy user với docId: $docId');
      }
      return user;
    } catch (e) {
      print('❌ Lỗi khi lấy thông tin user: $e');
      rethrow;
    }
  }

  // Lấy user data theo field uid (Firebase Auth uid)
  Future<UserModel?> getUserDataByAuthUid(String authUid) async {
    try {
      print('🔍 Đang tìm user với authUid: $authUid');
      final user = await _firestoreService.getUserDataByAuthUid(authUid);
      if (user != null) {
        print('✅ Đã tìm thấy user: ${user.name} (ID: ${user.id})');
      } else {
        print('⚠️ Không tìm thấy user với authUid: $authUid');
      }
      return user;
    } catch (e) {
      print('❌ Lỗi khi lấy user theo authUid: $e');
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('🚪 Đang đăng xuất user: ${currentUser.email}');
        await _auth.signOut();
        print('✅ Đăng xuất thành công');
      } else {
        print('ℹ️ Không có user nào đang đăng nhập');
      }
    } catch (e) {
      print('❌ Lỗi khi đăng xuất: $e');
      rethrow;
    }
  }

  // Lấy current user
  User? getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      print('👤 User hiện tại: ${user.email} (UID: ${user.uid})');
    } else {
      print('ℹ️ Không có user nào đang đăng nhập');
    }
    return user;
  }

  // Kiểm tra trạng thái đăng nhập
  bool isLoggedIn() {
    final isLoggedIn = _auth.currentUser != null;
    print(isLoggedIn ? '✅ Đã đăng nhập' : '❌ Chưa đăng nhập');
    return isLoggedIn;
  }
}