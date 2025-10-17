
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_group.dart';

class FirestoreListener extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, UserModel> _usersByDocId = {};
  Map<String, UserModel> _usersByAuthUid = {};
  Map<String, GroupModel> _groupsByDocId = {};

  String? _errorMessage;

  Map<String, UserModel> get users => _usersByDocId;
  String? get errorMessage => _errorMessage;

  FirestoreListener() {
    _startListening();
  }

  void _startListening() {
    // Lắng nghe dữ liệu người dùng
    _firestore.collection('User').snapshots().listen(
      (snapshot) {
        try {
          _usersByDocId = {};
          _usersByAuthUid = {};
          
          for (var doc in snapshot.docs) {
            final user = UserModel.fromFirestore(doc);
            _usersByDocId[doc.id] = user;
            
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
        _errorMessage = 'Lỗi kết nối người dùng: $error';
        notifyListeners();
      },
    );

    // Lắng nghe dữ liệu nhóm
    _firestore.collection('Group').snapshots().listen(
      (snapshot) {
        try {
          _groupsByDocId = {};
          for (var doc in snapshot.docs) {
            final group = GroupModel.fromMap(doc.id, doc.data());
            _groupsByDocId[doc.id] = group;
          }
          _errorMessage = null;
          notifyListeners();
        } catch (e) {
          _errorMessage = 'Lỗi khi lắng nghe dữ liệu nhóm: $e';
          notifyListeners();
        }
      },
      onError: (error) {
        _errorMessage = 'Lỗi kết nối nhóm: $error';
        notifyListeners();
      },
    );
  }

  UserModel? getUserById(String docId) {
    return _usersByDocId[docId];
  }

  UserModel? getUserByAuthUid(String authUid) {
    return _usersByAuthUid[authUid];
  }

  GroupModel? getGroupById(String docId) {
    return _groupsByDocId[docId];
  }
}