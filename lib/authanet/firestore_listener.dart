
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_media.dart';

class FirestoreListener extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, UserModel> _usersByDocId = {};
  Map<String, UserModel> _usersByAuthUid = {}; // Thêm lại Map này
  Map<String, GroupModel> _groupsByDocId = {};
  Map<String, MediaModel> _mediaByDocId = {};

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  FirestoreListener() {
    _startListening();
  }

  void _startListening() {
    // Lắng nghe User
    _firestore.collection('User').snapshots().listen((snapshot) {
      try {
        // Cập nhật lại logic để điền vào cả hai Map
        _usersByDocId = {};
        _usersByAuthUid = {};
        for (var doc in snapshot.docs) {
          final user = UserModel.fromFirestore(doc);
          _usersByDocId[doc.id] = user;
          if (user.uid.isNotEmpty) {
            _usersByAuthUid[user.uid] = user;
          }
        }
        notifyListeners();
      } catch (e) { 
        _errorMessage = 'Lỗi khi lắng nghe dữ liệu người dùng: $e';
        notifyListeners();
      }
    });

    // Lắng nghe Group
    _firestore.collection('Group').snapshots().listen((snapshot) {
      try {
        _groupsByDocId = { for (var doc in snapshot.docs) doc.id : GroupModel.fromMap(doc.id, doc.data()) };
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Lỗi khi lắng nghe dữ liệu nhóm: $e';
        notifyListeners();
       }
    });
    
    // Lắng nghe Media
    _firestore.collection('Media').snapshots().listen((snapshot) {
      try {
        _mediaByDocId = { for (var doc in snapshot.docs) doc.id : MediaModel.fromFirestore(doc) };
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Lỗi khi lắng nghe dữ liệu media: $e';
        notifyListeners();
      }
    });
  }

  UserModel? getUserById(String docId) => _usersByDocId[docId];
  
  // THÊM LẠI HÀM BỊ THIẾU
  UserModel? getUserByAuthUid(String authUid) => _usersByAuthUid[authUid];

  GroupModel? getGroupById(String docId) => _groupsByDocId[docId];
  MediaModel? getMediaById(String docId) => _mediaByDocId[docId];
}