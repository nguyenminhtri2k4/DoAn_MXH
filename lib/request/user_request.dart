import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/authanet/firestore_service.dart';

class UserRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Sử dụng FirestoreService cho các thao tác lấy/cập nhật dữ liệu
  final FirestoreService _firestoreService = FirestoreService();

  /// 📥 Lấy thông tin người dùng theo UID (Firebase Auth UID)
  Future<UserModel?> getUserByUid(String uid) async {
    try {
      final user = await _firestoreService.getUserDataByAuthUid(uid);
      if (user != null) {
        print('✅ Đã lấy thông tin user: ${user.name}');
      } else {
        print('⚠️ Không tìm thấy user với UID: $uid');
      }
      return user;
    } catch (e) {
      print('❌ Lỗi khi lấy user theo uid: $e');
      return null;
    }
  }

  /// 💾 Cập nhật thông tin người dùng
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestoreService.updateUser(user);
      print('✅ Cập nhật thông tin user thành công');
    } catch (e) {
      print('❌ Lỗi khi cập nhật thông tin user: $e');
      rethrow;
    }
  }

  /// 🧑‍💻 Thêm mới user (nếu chưa có)
  Future<String> addUser(UserModel user) async {
    try {
      final docRef = await _firestore.collection('users').add(user.toMap());
      print('✅ Thêm user mới với id: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Lỗi khi thêm user: $e');
      rethrow;
    }
  }

  /// 🗑️ Xóa user (chỉ dành cho admin)
  Future<void> deleteUser(String docId) async {
    try {
      await _firestore.collection('users').doc(docId).delete();
      print('✅ Xóa user thành công');
    } catch (e) {
      print('❌ Lỗi khi xóa user: $e');
      rethrow;
    }
  }
}
