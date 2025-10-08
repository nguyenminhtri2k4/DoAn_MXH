// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:mangxahoi/model/model_user.dart';

// class FirestoreListener extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   Map<String, UserModel> _users = {};
//   String? _errorMessage;

//   Map<String, UserModel> get users => _users;
//   String? get errorMessage => _errorMessage;

//   FirestoreListener() {
//     _startListening();
//   }

//   void _startListening() {
//     _firestore.collection('User').snapshots().listen(
//       (snapshot) {
//         try {
//           _users = {};
//           for (var doc in snapshot.docs) {
//             final user = UserModel.fromFirestore(doc);
//             _users[doc.id] = user;
//           }
//           _errorMessage = null;
//           notifyListeners();
//         } catch (e) {
//           _errorMessage = 'Lỗi khi lắng nghe dữ liệu: $e';
//           notifyListeners();
//         }
//       },
//       onError: (error) {
//         _errorMessage = 'Lỗi kết nối: $error';
//         notifyListeners();
//       },
//     );
//   }

//   UserModel? getUserById(String uid) {
//     return _users[uid];
//   }
// }
// lib/authanet/firestore_listener.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';

class FirestoreListener extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Map lưu người dùng theo Document ID (ví dụ: 'user1')
  Map<String, UserModel> _usersByDocId = {};
  // Map mới để lưu người dùng theo Auth UID (ví dụ: 'Abc123xyz...')
  Map<String, UserModel> _usersByAuthUid = {};

  String? _errorMessage;

  Map<String, UserModel> get users => _usersByDocId;
  String? get errorMessage => _errorMessage;

  FirestoreListener() {
    _startListening();
  }

  void _startListening() {
    _firestore.collection('User').snapshots().listen(
      (snapshot) {
        try {
          // Xóa cả hai map để xây dựng lại từ đầu
          _usersByDocId = {};
          _usersByAuthUid = {};
          
          for (var doc in snapshot.docs) {
            final user = UserModel.fromFirestore(doc);
            // Thêm vào map theo Document ID
            _usersByDocId[doc.id] = user;
            
            // Thêm vào map theo Auth UID (nếu có)
            if (user.uid.isNotEmpty) {
              _usersByAuthUid[user.uid] = user;
            }
          }
          
          _errorMessage = null;
          notifyListeners();
        } catch (e) {
          _errorMessage = 'Lỗi khi lắng nghe dữ liệu người dùng: $e';
          notifyListeners();
        }
      },
      onError: (error) {
        _errorMessage = 'Lỗi kết nối: $error';
        notifyListeners();
      },
    );
  }

  /// Lấy người dùng bằng Document ID (ví dụ: 'user1', 'user2')
  UserModel? getUserById(String docId) {
    return _usersByDocId[docId];
  }

  /// ===> HÀM MỚI QUAN TRỌNG <===
  /// Lấy người dùng bằng Firebase Authentication UID
  UserModel? getUserByAuthUid(String authUid) {
    return _usersByAuthUid[authUid];
  }
}