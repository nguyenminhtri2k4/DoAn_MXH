import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/authanet/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class UserRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirestoreService _firestoreService = FirestoreService();

  final String? _currentAuthUid = FirebaseAuth.instance.currentUser?.uid; 

  // ... (getUserByUid, updateUser, addUser, deleteUser giữ nguyên)

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
  
  // ===> HÀM MỚI ĐỂ TẢI TẤT CẢ USER LÀM CACHE <===
  /// 📥 Tải danh sách lớn người dùng vào bộ nhớ cache (cho tìm kiếm Client-Side)
  Future<List<UserModel>> getAllUsersForCache({int limit = 1000}) async {
    try {
      final querySnapshot = await _firestore
          .collection('User')
          .limit(limit) 
          .get();
      
      final List<UserModel> users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      
      // Lọc ra user hiện tại
      if (_currentAuthUid != null) {
        users.removeWhere((user) => user.uid == _currentAuthUid);
      }

      print('✅ Đã tải ${users.length} user vào cache cục bộ.');
      return users;
    } catch (e) {
      print('❌ Lỗi khi tải user cache: $e');
      rethrow;
    }
  }

}