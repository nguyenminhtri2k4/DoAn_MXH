// lib/model/model_qr_invite.dart
import 'dart:convert';

class QRInviteData {
  final String groupId;
  final String groupName;
  final String inviterName;
  final DateTime createdAt;
  final String? groupCover;

  QRInviteData({
    required this.groupId,
    required this.groupName,
    required this.inviterName,
    required this.createdAt,
    this.groupCover,
  });

  // Chuyển thành JSON string để tạo QR
  String toQRString() {
    return jsonEncode({
      'type': 'group_invite',
      'groupId': groupId,
      'groupName': groupName,
      'inviterName': inviterName,
      'timestamp': createdAt.millisecondsSinceEpoch,
      'groupCover': groupCover,
    });
  }

  // Parse từ QR string
  factory QRInviteData.fromQRString(String qrString) {
    try {
      final data = jsonDecode(qrString);
      
      // Kiểm tra loại QR
      if (data['type'] != 'group_invite') {
        throw Exception('QR code không hợp lệ');
      }

      return QRInviteData(
        groupId: data['groupId'],
        groupName: data['groupName'],
        inviterName: data['inviterName'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
        groupCover: data['groupCover'],
      );
    } catch (e) {
      throw Exception('Không thể đọc mã QR: $e');
    }
  }

  // Kiểm tra QR có hết hạn không (ví dụ: 24 giờ)
  bool get isExpired {
    return DateTime.now().difference(createdAt).inHours > 24;
  }
}