import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';

class FirestoreListener extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, UserModel> _users = {};
  String? _errorMessage;

  Map<String, UserModel> get users => _users;
  String? get errorMessage => _errorMessage;

  FirestoreListener() {
    _startListening();
  }

  void _startListening() {
    // ĐỔI TỪ 'users' THÀNH 'User'
    _firestore.collection('User').snapshots().listen(
      (snapshot) {
        try {
          _users = {};
          for (var doc in snapshot.docs) {
            final user = UserModel.fromFirestore(doc);
            _users[doc.id] = user;
          }
          _errorMessage = null;
          notifyListeners();
        } catch (e) {
          _errorMessage = 'Lỗi khi lắng nghe dữ liệu: $e';
          notifyListeners();
        }
      },
      onError: (error) {
        _errorMessage = 'Lỗi kết nối: $error';
        notifyListeners();
      },
    );
  }

  UserModel? getUserById(String uid) {
    return _users[uid];
  }
}