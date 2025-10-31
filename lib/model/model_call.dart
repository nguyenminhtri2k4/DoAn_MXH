// lib/model/model_call.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Enum này để theo dõi trạng thái cuộc gọi
enum CallStatus { pending, accepted, declined, ended, missed }

// Enum để phân loại cuộc gọi 1-1 hay nhóm
enum CallType { oneToOne, group }

// THÊM MỚI: Enum để phân biệt loại media (tiếng hay video)
enum CallMediaType { audio, video }

class CallModel {
  final String id;
  final String callerId;      // ID của người bắt đầu gọi
  final String callerName;    // Tên người gọi
  final String callerAvatar;  // Avatar người gọi
  
  final List<String> receiverIds; // Danh sách ID của (các) người nhận
  
  final CallStatus status;
  final CallType callType;    // 1-1 hay nhóm
  
  // THÊM MỚI:
  final CallMediaType mediaType; // Tiếng hay video
  
  final String channelName; // Tên phòng (channel) để ZegoCloud kết nối
  final Timestamp createdAt;

  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.receiverIds,
    required this.status,
    required this.callType,
    required this.mediaType, // Đã thêm
    required this.channelName,
    required this.createdAt,
  });

  // Chuyển đổi từ CallModel thành một đối tượng JSON để lưu lên Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverIds': receiverIds,
      'status': status.name, 
      'callType': callType.name,
      'mediaType': mediaType.name, // Đã thêm
      'channelName': channelName,
      'createdAt': createdAt,
    };
  }

  // Chuyển đổi từ JSON (lấy từ Firestore) về lại CallModel
  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'],
      callerId: json['callerId'],
      callerName: json['callerName'],
      callerAvatar: json['callerAvatar'],
      receiverIds: List<String>.from(json['receiverIds']),
      
      status: CallStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CallStatus.ended,
      ),
      
      callType: CallType.values.firstWhere(
        (e) => e.name == json['callType'],
        orElse: () => CallType.oneToOne,
      ),
      
      // Đọc loại media
      mediaType: CallMediaType.values.firstWhere(
        (e) => e.name == json['mediaType'],
        orElse: () => CallMediaType.audio, // Mặc định là audio nếu lỗi
      ), // Đã thêm
      
      channelName: json['channelName'],
      createdAt: json['createdAt'],
    );
  }
}
extension CallModelExtension on CallModel {
  CallModel copyWith({CallStatus? status}) {
    return CallModel(
      id: id,
      callerId: callerId,
      callerName: callerName,
      callerAvatar: callerAvatar,
      receiverIds: receiverIds,
      status: status ?? this.status,
      callType: callType,
      mediaType: mediaType,
      channelName: channelName,
      createdAt: createdAt,
    );
  }
}