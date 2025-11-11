// lib/viewmodel/qr_scanner_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:provider/provider.dart';

class QRScannerViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isJoining = false;
  bool get isJoining => _isJoining;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> joinGroup(BuildContext context, String groupId) async {
    _isJoining = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userService = context.read<UserService>();
      final currentUser = userService.currentUser;

      if (currentUser == null) {
        _errorMessage = 'Vui lòng đăng nhập';
        _isJoining = false;
        notifyListeners();
        return false;
      }

      // 1. Kiểm tra nhóm có tồn tại không
      final groupDoc = await _firestore.collection('Group').doc(groupId).get();
      if (!groupDoc.exists) {
        _errorMessage = 'Nhóm không tồn tại';
        _isJoining = false;
        notifyListeners();
        return false;
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final List<String> members = List<String>.from(groupData['members'] ?? []);

      // 2. Kiểm tra đã là thành viên chưa
      if (members.contains(currentUser.id)) {
        _errorMessage = 'Bạn đã là thành viên của nhóm này';
        _isJoining = false;
        notifyListeners();
        return false;
      }

      // 3. Thêm vào nhóm
      await _firestore.collection('Group').doc(groupId).update({
        'members': FieldValue.arrayUnion([currentUser.id]),
      });

      // 4. Thêm groupId vào user
      await _firestore.collection('User').doc(currentUser.id).update({
        'groups': FieldValue.arrayUnion([groupId]),
      });

      // 5. Tạo tin nhắn thông báo trong nhóm chat (nếu có)
      try {
        final chatId = groupId; // Giả sử chat ID = group ID
        await _firestore
            .collection('Chat')
            .doc(chatId)
            .collection('messages')
            .add({
          'type': 'system',
          'content': '${currentUser.name} đã tham gia nhóm qua mã QR',
          'senderId': 'system',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'sent',
          'mediaIds': [],
        });

        // Cập nhật lastMessage của chat
        await _firestore.collection('Chat').doc(chatId).update({
          'lastMessage': '${currentUser.name} đã tham gia nhóm',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('⚠️ Không thể tạo tin nhắn thông báo: $e');
        // Không throw error vì đây không phải lỗi nghiêm trọng
      }

      _isJoining = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = 'Lỗi khi tham gia nhóm: $e';
      _isJoining = false;
      notifyListeners();
      return false;
    }
  }
}