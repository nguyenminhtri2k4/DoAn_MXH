
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/authanet/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class UserRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentAuthUid = FirebaseAuth.instance.currentUser?.uid; 

  /// Lấy thông tin người dùng theo Document ID
  Future<UserModel?> getUserData(String docId) async {
    try {
      // ✅ Thêm timeout
      final user = await _firestoreService
          .getUserData(docId)
          .timeout(const Duration(seconds: 15));
          
      if (user != null) {
        print('✅ Đã lấy thông tin user: ${user.name}');
      } else {
        print('⚠️ Không tìm thấy user với Doc ID: $docId');
      }
      return user;
    } catch (e) {
      print('❌ Lỗi khi lấy user theo docId: $e');
      return null;
    }
  }

  /// ✅ Lấy thông tin người dùng theo UID với retry & timeout
  Future<UserModel?> getUserByUid(String uid, {int maxRetries = 5}) async {
    print('🔍 [UserRequest] getUserByUid called with UID: $uid');
    
    try {
      print('🔍 [UserRequest] Calling FirestoreService.getUserDataByAuthUid...');
      
      // ✅ Gọi với retry logic & timeout
      final user = await _firestoreService
          .getUserDataByAuthUid(uid, maxRetries: maxRetries)
          .timeout(const Duration(seconds: 30)); // Timeout tổng
      
      if (user != null) {
        print('✅ [UserRequest] SUCCESS: Found user: ${user.name}');
        print('🔍 [UserRequest] User document ID: ${user.id}');
        print('🔍 [UserRequest] User auth UID: ${user.uid}');
      } else {
        print('❌ [UserRequest] FAILED: No user found with UID: $uid');
        print('🔍 [UserRequest] This means Firestore query returned empty after retries');
      }
      return user;
    } catch (e) {
      print('❌ [UserRequest] ERROR: $e');
      return null;
    }
  }

  /// Cập nhật thông tin người dùng
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestoreService
          .updateUser(user)
          .timeout(const Duration(seconds: 15));
      print('✅ Cập nhật thông tin user thành công');
    } catch (e) {
      print('❌ Lỗi khi cập nhật thông tin user: $e');
      rethrow;
    }
  }

  /// Thêm mới user
  Future<String> addUser(UserModel user) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .add(user.toMap())
          .timeout(const Duration(seconds: 15));
      print('✅ Thêm user mới với id: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Lỗi khi thêm user: $e');
      rethrow;
    }
  }

  /// Xóa user
  Future<void> deleteUser(String docId) async {
    try {
      await _firestore
          .collection('users')
          .doc(docId)
          .delete()
          .timeout(const Duration(seconds: 10));
      print('✅ Xóa user thành công');
    } catch (e) {
      print('❌ Lỗi khi xóa user: $e');
      rethrow;
    }
  }
  
  /// Tải danh sách user cho cache
  Future<List<UserModel>> getAllUsersForCache({int limit = 1000}) async {
    try {
      final querySnapshot = await _firestore
          .collection('User')
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 30)); // ✅ Timeout cho query lớn
      
      final List<UserModel> users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      
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