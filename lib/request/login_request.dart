
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <--- IMPORT MỚI
import 'package:mangxahoi/authanet/firestore_service.dart';
import 'package:mangxahoi/model/model_user.dart';

class LoginRequest {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  // THAY YOUR_WEB_CLIENT_ID bằng Web Client ID từ bước 3
  clientId: '55399679019-j318ahbn27sri4glbgu9g2eroqsqd7r3.apps.googleusercontent.com',
  ); // <--- THÊM MỚI

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

  // *** BẮT ĐẦU CODE MỚI: ĐĂNG NHẬP BẰNG GOOGLE ***
  Future<UserModel?> signInWithGoogle() async {
    try {
      print('🌎 Bắt đầu đăng nhập Google...');
      
      // 1. Bắt đầu quy trình đăng nhập Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('🚫 Người dùng đã hủy đăng nhập Google');
        return null; // Người dùng đã hủy
      }

      // 2. Lấy thông tin xác thực (token)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Tạo credential cho Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Đăng nhập vào Firebase
      print('🔐 Đang đăng nhập Firebase với Google credential...');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User user = userCredential.user!;
      print('✅ Đăng nhập Firebase Auth thành công, UID: ${user.uid}');

      // 5. Kiểm tra xem có phải người dùng mới không
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        print('👋 Chào người dùng mới! Đang tạo tài khoản Firestore...');
        // Tạo UserModel mới
        final newUser = UserModel(
          id: '', // Sẽ được gán trong saveUser
          uid: user.uid,
          name: user.displayName ?? googleUser.email.split('@').first,
          email: user.email!,
          password: '', // Không lưu mật khẩu cho Google Sign-in
          phone: user.phoneNumber ?? '',
          bio: 'Xin chào! Tôi là người dùng mới',
          gender: '',
          liveAt: '',
          comeFrom: '',
          role: 'user',
          relationship: '',
          statusAccount: 'active',
          backgroundImageUrl: '', 
          avatar: user.photoURL != null ? [user.photoURL!] : [], // Thêm avatar từ Google
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

        // Lưu vào Firestore
        final docId = await _firestoreService.saveUser(newUser);
        print('✅ Đã lưu user mới vào Firestore với ID: $docId');
        // Trả về user model đã có docId
        return await _firestoreService.getUserData(docId);
      } else {
        // 6. Nếu là người dùng cũ, lấy thông tin từ Firestore
        print('👍 Chào mừng trở lại, người dùng cũ!');
        final userModel = await _firestoreService.getUserDataByAuthUid(user.uid);
        if (userModel == null) {
          print('⚠️ Lỗi: Người dùng đã đăng nhập Auth nhưng không có dữ liệu Firestore!');
          // Đây là trường hợp hiếm gặp, có thể tạo dữ liệu ở đây nếu cần
          throw Exception('Tài khoản tồn tại trong Auth nhưng không có trong Firestore.');
        }
        
        // Cập nhật avatar nếu nó trống trong F_Store
        if (userModel.avatar.isEmpty && user.photoURL != null) {
          userModel.avatar.add(user.photoURL!);
          await _firestoreService.updateUser(userModel);
        }

        print('✅ Đã tải dữ liệu user: ${userModel.name}');
        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Lỗi Firebase Auth (Google): ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Lỗi đăng nhập Google: $e');
      // Đảm bảo đăng xuất khỏi Google nếu có lỗi
      await _googleSignIn.signOut();
      rethrow;
    }
  }
  // *** KẾT THÚC CODE MỚI ***


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
        backgroundImageUrl: '', // <--- SỬA LỖI: THÊM DÒNG NÀY
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
  
  // Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('📬 Đang gửi email đặt lại mật khẩu tới: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('✅ Gửi email thành công');
    } on FirebaseAuthException catch (e) {
      print('❌ Lỗi gửi email đặt lại mật khẩu: ${e.code} - ${e.message}');
      // Ném lỗi đã được xử lý để ViewModel bắt
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Lỗi không xác định khi gửi email: $e');
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
      // Lỗi mới cho Google Sign-In
      case 'account-exists-with-different-credential':
        return 'Tài khoản đã tồn tại với phương thức đăng nhập khác (ví dụ: email, Facebook...)';
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
        // Đăng xuất khỏi Google nếu đã đăng nhập bằng Google
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
          print('✅ Đăng xuất Google thành công');
        }
        print('✅ Đăng xuất Firebase thành công');
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