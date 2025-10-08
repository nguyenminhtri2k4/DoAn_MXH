// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mangxahoi/model/model_user.dart';

// class FirestoreService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String _collectionName = 'User';

//   // Lấy ID user tiếp theo (user1, user2, user3...) - PHIÊN BẢN MỚI
//   Future<String> getNextUserId() async {
//     try {
//       // Lấy tất cả documents (không dùng orderBy để tránh cần index)
//       final querySnapshot = await _firestore
//           .collection(_collectionName)
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         return 'user1';
//       }

//       // Tìm số lớn nhất
//       int maxNumber = 0;
//       for (var doc in querySnapshot.docs) {
//         final id = doc.id;
//         if (id.startsWith('user')) {
//           final numberPart = id.replaceAll('user', '');
//           final number = int.tryParse(numberPart) ?? 0;
//           if (number > maxNumber) {
//             maxNumber = number;
//           }
//         }
//       }

//       return 'user${maxNumber + 1}';
      
//     } catch (e) {
//       print('❌ Error getting next user ID: $e');
//       return 'user${DateTime.now().millisecondsSinceEpoch}';
//     }
//   }

//   // Lưu user vào Firestore với custom ID
//   Future<String> saveUser(UserModel user) async {
//     try {
//       String docId;
//       if (user.id.isEmpty || user.id.length > 10) {
//         docId = await getNextUserId();
//       } else {
//         docId = user.id;
//       }

//       final userMap = user.toMap();
//       userMap['id'] = docId; // Cập nhật ID trong map

//       await _firestore.collection(_collectionName).doc(docId).set(userMap);
//       print('✅ User saved to Firestore with ID: $docId');
      
//       return docId;
//     } catch (e) {
//       print('❌ Error saving user: $e');
//       rethrow;
//     }
//   }

//   // Các methods khác giữ nguyên...
//   Future<UserModel?> getUserData(String docId) async {
//     try {
//       final doc = await _firestore.collection(_collectionName).doc(docId).get();
//       if (doc.exists) {
//         print('✅ User data fetched: ${doc.id}');
//         return UserModel.fromFirestore(doc);
//       }
//       print('⚠️ No user found with docId: $docId');
//       return null;
//     } catch (e) {
//       print('❌ Error getting user data: $e');
//       return null;
//     }
//   }

//   Future<UserModel?> getUserDataByAuthUid(String authUid) async {
//     try {
//       final query = await _firestore
//           .collection(_collectionName)
//           .where('uid', isEqualTo: authUid)
//           .limit(1)
//           .get();

//       if (query.docs.isNotEmpty) {
//         final userData = UserModel.fromFirestore(query.docs.first);
//         print('✅ User found by authUid: ${userData.name}');
//         return userData;
//       }
//       print('⚠️ No user found with authUid: $authUid');
//       return null;
//     } catch (e) {
//       print('❌ Error getting user by authUid: $e');
//       return null;
//     }
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'User';

  // Lấy ID user tiếp theo (user1, user2, user3...)
  Future<String> getNextUserId() async {
    try {
      final querySnapshot = await _firestore.collection(_collectionName).get();
      if (querySnapshot.docs.isEmpty) return 'user1';

      int maxNumber = 0;
      for (var doc in querySnapshot.docs) {
        final id = doc.id;
        if (id.startsWith('user')) {
          final numberPart = id.replaceAll('user', '');
          final number = int.tryParse(numberPart) ?? 0;
          if (number > maxNumber) maxNumber = number;
        }
      }
      return 'user${maxNumber + 1}';
    } catch (e) {
      print('❌ Error getting next user ID: $e');
      return 'user${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Lưu user vào Firestore với custom ID
  Future<String> saveUser(UserModel user) async {
    try {
      String docId = (user.id.isEmpty || user.id.length > 10)
          ? await getNextUserId()
          : user.id;

      final userMap = user.toMap();
      userMap['id'] = docId;

      await _firestore.collection(_collectionName).doc(docId).set(userMap);
      print('✅ User saved to Firestore with ID: $docId');
      return docId;
    } catch (e) {
      print('❌ Error saving user: $e');
      rethrow;
    }
  }

  // **Cập nhật user**
  Future<void> updateUser(UserModel user) async {
    try {
      if (user.id.isEmpty) {
        throw Exception('User ID không được trống khi cập nhật');
      }
      await _firestore.collection(_collectionName).doc(user.id).update(user.toMap());
      print('✅ User updated: ${user.name}');
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  // Lấy user theo docId
  Future<UserModel?> getUserData(String docId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(docId).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // Lấy user theo authUid
  Future<UserModel?> getUserDataByAuthUid(String authUid) async {
    try {
      final query = await _firestore
          .collection(_collectionName)
          .where('uid', isEqualTo: authUid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) return UserModel.fromFirestore(query.docs.first);
      return null;
    } catch (e) {
      print('❌ Error getting user by authUid: $e');
      return null;
    }
  }
}
