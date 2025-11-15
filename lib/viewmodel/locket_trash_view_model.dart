// ==================== PHẦN 1: LOCKET TRASH VIEW MODEL ====================
// File: lib/viewmodel/locket_trash_view_model.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';

class LocketTrashViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<LocketPhoto>> get deletedLocketsStream {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('locket_photos')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'deleted')
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LocketPhoto.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> restoreLocket(String locketId) async {
    try {
      await _firestore.collection('locket_photos').doc(locketId).update({
        'status': 'active',
        'deletedAt': FieldValue.delete(),
      });
      print('✅ [LocketTrashVM] Đã khôi phục locket: $locketId');
    } catch (e) {
      print('❌ [LocketTrashVM] Lỗi khôi phục locket: $e');
      rethrow;
    }
  }

  Future<void> deleteLocketPermanently(String locketId) async {
    try {
      await _firestore.collection('locket_photos').doc(locketId).delete();
      print('✅ [LocketTrashVM] Đã xóa vĩnh viễn locket: $locketId');
    } catch (e) {
      print('❌ [LocketTrashVM] Lỗi xóa vĩnh viễn locket: $e');
      rethrow;
    }
  }
}
