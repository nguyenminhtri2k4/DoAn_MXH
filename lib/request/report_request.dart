import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_report.dart';

class ReportRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Reports'; // Tên collection cho báo cáo

  /// Gửi một báo cáo mới lên Firestore
  Future<void> createReport(ReportModel report) async {
    try {
      // Chuyển đổi model thành Map và thêm vào Firestore
      // Firestore sẽ tự động tạo ID cho document
      await _firestore.collection(_collectionName).add(report.toMap());
      print('✅ Báo cáo đã được gửi thành công!');
    } catch (e) {
      print('❌ Lỗi khi gửi báo cáo: $e');
      // Ném lại lỗi để xử lý ở UI nếu cần
      rethrow;
    }
  }

  /// Kiểm tra xem người dùng đã báo cáo bài viết này chưa
  /// Tránh spam báo cáo
  Future<bool> hasUserAlreadyReported(
      String userId, String targetId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('reporterId', isEqualTo: userId)
          .where('targetId', isEqualTo: targetId)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Lỗi khi kiểm tra báo cáo: $e');
      return false; // Mặc định là chưa báo cáo nếu có lỗi
    }
  }
}