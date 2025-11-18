import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId; // ai gửi báo cáo
  final String targetId; // ID của bài viết, bình luận, user, v.v.
  final String targetAuthorId; // ID của người chủ bài viết (NGƯỜI BỊ BÁO CÁO)
  final String targetType; // "post", "comment", "user"...
  final String reason; // lý do báo cáo
  final String status; // "pending", "reviewed", "rejected"
  final String? reviewedBy; // admin xử lý
  final DateTime createdAt;
  final DateTime? reviewedAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetAuthorId, // Thêm vào constructor
    required this.targetType,
    required this.reason,
    this.status = 'pending',
    this.reviewedBy,
    required this.createdAt,
    this.reviewedAt,
  });

  factory ReportModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ReportModel(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      targetId: data['targetId'] ?? '',
      targetAuthorId: data['targetAuthorId'] ?? '', // Thêm logic lấy dữ liệu
      targetType: data['targetType'] ?? '',
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'pending',
      reviewedBy: data['reviewedBy'],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] is Timestamp
              ? (data['reviewedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['reviewedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'targetId': targetId,
      'targetAuthorId': targetAuthorId, // Thêm vào map
      'targetType': targetType,
      'reason': reason,
      'status': status,
      'reviewedBy': reviewedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }
}
// DẤU } THỪA ĐÃ BỊ XÓA Ở ĐÂY