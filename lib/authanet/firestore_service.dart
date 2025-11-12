// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mangxahoi/model/model_user.dart';

// class FirestoreService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String _collectionName = 'User';

//   // Lấy ID user tiếp theo (user1, user2, user3...)
//   Future<String> getNextUserId() async {
//     try {
//       final querySnapshot = await _firestore.collection(_collectionName).get();
//       if (querySnapshot.docs.isEmpty) return 'user1';

//       int maxNumber = 0;
//       for (var doc in querySnapshot.docs) {
//         final id = doc.id;
//         if (id.startsWith('user')) {
//           final numberPart = id.replaceAll('user', '');
//           final number = int.tryParse(numberPart) ?? 0;
//           if (number > maxNumber) maxNumber = number;
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
//       String docId = (user.id.isEmpty || user.id.length > 10)
//           ? await getNextUserId()
//           : user.id;

//       final userMap = user.toMap();
//       userMap['id'] = docId;

//       await _firestore.collection(_collectionName).doc(docId).set(userMap);
//       print('✅ User saved to Firestore with ID: $docId');
//       return docId;
//     } catch (e) {
//       print('❌ Error saving user: $e');
//       rethrow;
//     }
//   }

//   // **Cập nhật user**
//   Future<void> updateUser(UserModel user) async {
//     try {
//       if (user.id.isEmpty) {
//         throw Exception('User ID không được trống khi cập nhật');
//       }
//       await _firestore.collection(_collectionName).doc(user.id).update(user.toMap());
//       print('✅ User updated: ${user.name}');
//     } catch (e) {
//       print('❌ Error updating user: $e');
//       rethrow;
//     }
//   }

//   // Lấy user theo docId
//   Future<UserModel?> getUserData(String docId) async {
//     try {
//       final doc = await _firestore.collection(_collectionName).doc(docId).get();
//       if (doc.exists) return UserModel.fromFirestore(doc);
//       return null;
//     } catch (e) {
//       print('❌ Error getting user data: $e');
//       return null;
//     }
//   }

//   // Lấy user theo authUid
//   // Future<UserModel?> getUserDataByAuthUid(String authUid) async {
//   //   try {
//   //     final query = await _firestore
//   //         .collection(_collectionName)
//   //         .where('uid', isEqualTo: authUid)
//   //         .limit(1)
//   //         .get();

//   //     if (query.docs.isNotEmpty) return UserModel.fromFirestore(query.docs.first);
//   //     return null;
//   //   } catch (e) {
//   //     print('❌ Error getting user by authUid: $e');
//   //     return null;
//   //   }
//   // }
//   // TRONG FirestoreService - THÊM LOG DEBUG
// Future<UserModel?> getUserDataByAuthUid(String authUid) async {
//   print('🔍 [FirestoreService] getUserDataByAuthUid called with: $authUid');
//   try {
//     print('🔍 [FirestoreService] Querying Firestore: collection=User, where=uid==$authUid');
    
//     final querySnapshot = await _firestore
//         .collection('User')
//         .where('uid', isEqualTo: authUid)
//         .limit(1)
//         .get();

//     print('🔍 [FirestoreService] Query completed, docs count: ${querySnapshot.docs.length}');
    
//     if (querySnapshot.docs.isNotEmpty) {
//       final doc = querySnapshot.docs.first;
//       print('🔍 [FirestoreService] Found document: ${doc.id}');
//       print('🔍 [FirestoreService] Document data: ${doc.data()}');
      
//       final user = UserModel.fromFirestore(doc);
//       print('✅ [FirestoreService] SUCCESS: User parsed: ${user.name}');
//       return user;
//     }
    
//     print('❌ [FirestoreService] FAILED: No documents found for UID: $authUid');
//     print('🔍 [FirestoreService] Check if:');
//     print('🔍 [FirestoreService] 1. User collection exists');
//     print('🔍 [FirestoreService] 2. Field name is "uid" (not "authUid")');
//     print('🔍 [FirestoreService] 3. User document has the correct UID value');
//     return null;
//   } catch (e) {
//     print('❌ [FirestoreService] ERROR: $e');
   
//     return null;
//   }
// }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'User';

  // Lấy ID user tiếp theo
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
      
      // ✅ Đợi một chút để Firestore kịp index
      await Future.delayed(const Duration(milliseconds: 500));
      print('⏳ Đợi Firestore index xong...');
      
      return docId;
    } catch (e) {
      print('❌ Error saving user: $e');
      rethrow;
    }
  }

  // Cập nhật user
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

  // ✅ Lấy user theo authUid với RETRY LOGIC
  Future<UserModel?> getUserDataByAuthUid(String authUid, {int maxRetries = 5}) async {
    print('🔍 [FirestoreService] getUserDataByAuthUid: $authUid (maxRetries: $maxRetries)');
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔄 [FirestoreService] Thử lần $attempt/$maxRetries...');
        
        final querySnapshot = await _firestore
            .collection('User')
            .where('uid', isEqualTo: authUid)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10)); // ✅ Thêm timeout

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          print('✅ [FirestoreService] Found document: ${doc.id} (attempt $attempt)');
          print('🔍 [FirestoreService] Document data: ${doc.data()}');
          
          final user = UserModel.fromFirestore(doc);
          print('✅ [FirestoreService] User parsed successfully: ${user.name}');
          return user;
        }
        
        // Nếu không tìm thấy và chưa hết retry
        if (attempt < maxRetries) {
          final delay = Duration(milliseconds: 500 * attempt); // Tăng dần delay
          print('⏳ [FirestoreService] Document chưa sẵn sàng, đợi ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
        }
        
      } catch (e) {
        print('❌ [FirestoreService] Error attempt $attempt: $e');
        if (attempt == maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    
    print('❌ [FirestoreService] No user found after $maxRetries attempts');
    print('🔍 [FirestoreService] Checklist:');
    print('  1. User collection exists?');
    print('  2. Field name is "uid" (not "authUid")?');
    print('  3. Document has correct UID value?');
    return null;
  }
}