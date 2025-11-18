
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/authanet/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentAuthUid = FirebaseAuth.instance.currentUser?.uid;
  final String _collectionName = 'User';

  /// Lấy thông tin người dùng theo Document ID
  Future<UserModel?> getUserData(String docId) async {
    try {
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

  /// ✅ MỚI: Stream theo dõi thay đổi realtime của user document
  Stream<UserModel?> getUserDataStream(String docId) {
    return _firestore
        .collection(_collectionName)
        .doc(docId)
        .snapshots()
        .map((docSnapshot) {
          if (!docSnapshot.exists || docSnapshot.data() == null) {
            print('⚠️ [UserRequest] User document not found: $docId');
            return null;
          }
          
          try {
            final user = UserModel.fromFirestore(docSnapshot);
            print('✅ [UserRequest] User stream updated: ${user.name}');
            return user;
          } catch (e) {
            print('❌ [UserRequest] Error parsing user data: $e');
            return null;
          }
        })
        .handleError((error) {
          print('❌ [UserRequest] Stream error for user $docId: $error');
        });
  }

  /// Lấy thông tin người dùng theo UID với retry & timeout
  Future<UserModel?> getUserByUid(String uid, {int maxRetries = 5}) async {
    print('🔍 [UserRequest] getUserByUid called with UID: $uid');

    try {
      print('🔍 [UserRequest] Calling FirestoreService.getUserDataByAuthUid...');

      final user = await _firestoreService
          .getUserDataByAuthUid(uid, maxRetries: maxRetries)
          .timeout(const Duration(seconds: 30));

      if (user != null) {
        print('✅ [UserRequest] SUCCESS: Found user: ${user.name}');
        print('🔍 [UserRequest] User document ID: ${user.id}');
        print('🔍 [UserRequest] User auth UID: ${user.uid}');
      } else {
        print('❌ [UserRequest] FAILED: No user found with UID: $uid');
        print(
            '🔍 [UserRequest] This means Firestore query returned empty after retries');
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
          .collection(_collectionName)
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
          .collection(_collectionName)
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
          .collection(_collectionName)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 30));

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

  /// Lấy thông tin nhiều người dùng bằng danh sách ID (dạng Future)
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    List<UserModel> users = [];
    try {
      // Chia thành các batch 10 ID (giới hạn của Firestore 'whereIn')
      for (int i = 0; i < userIds.length; i += 10) {
        final batchIds = userIds.skip(i).take(10).toList();
        if (batchIds.isNotEmpty) {
          final snapshot = await _firestore
              .collection(_collectionName)
              .where(FieldPath.documentId, whereIn: batchIds)
              .get();

          users.addAll(snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList());
        }
      }
      // Sắp xếp lại theo thứ tự ID gốc
      final userMap = {for (var user in users) user.id: user};
      return userIds
          .map((id) => userMap[id])
          .where((user) => user != null)
          .cast<UserModel>()
          .toList();
    } catch (e) {
      print('❌ Lỗi khi lấy danh sách người dùng: $e');
      return [];
    }
  }

  /// Lấy thông tin nhiều người dùng bằng danh sách ID (dạng Stream)
  /// LƯU Ý: Do giới hạn của `whereIn`, stream này chỉ lấy batch 10 user đầu tiên.
  /// Đây là giải pháp phù hợp để xem trước (preview) 9 bạn bè trên profile.
  Stream<List<UserModel>> getUsersByIdsStream(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value([]);
    }

    // Chỉ lấy 10 ID đầu tiên cho stream
    final batchIds = userIds.take(10).toList();

    return _firestore
        .collection(_collectionName)
        .where(FieldPath.documentId, whereIn: batchIds)
        .snapshots()
        .map((snapshot) {
      final userMap = {
        for (var doc in snapshot.docs)
          doc.id: UserModel.fromFirestore(doc)
      };
      // Sắp xếp lại kết quả theo thứ tự của batchIds
      return batchIds
          .map((id) => userMap[id])
          .where((user) => user != null)
          .cast<UserModel>()
          .toList();
    }).handleError((error) {
      print('❌ Lỗi stream danh sách người dùng: $error');
      return [];
    });
  }

  Future<void> updateServiceGemini(String uid, bool isEnabled) async {
    try {
      await _firestore.collection('User').doc(uid).update({
        'servicegemini': isEnabled, 
      });
    } catch (e) {
      print('❌ Lỗi cập nhật Service Gemini: $e');
      throw e;
    }
  }
  
}