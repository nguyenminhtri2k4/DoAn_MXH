import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String coverImage;
  final List<String> managers;
  final List<String> members;
  final Map<String, dynamic> settings; // <--- Sửa từ String thành Map
  final String status;
  final String type;
  final DateTime? createdAt;

  GroupModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    this.coverImage = '',
    required this.managers,
    required this.members,
    required this.settings,
    required this.status,
    this.type = 'post',
    this.createdAt,
  });

  /// Firestore → Dart
  factory GroupModel.fromMap(String id, Map<String, dynamic> map) {
    return GroupModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      coverImage: map['coverImage'] ?? '',
      managers: List<String>.from(map['managers'] ?? []),
      members: List<String>.from(map['members'] ?? []),
      // Xử lý an toàn: Nếu null hoặc không phải Map thì trả về Map rỗng
      settings: map['settings'] is Map<String, dynamic> 
          ? map['settings'] 
          : {}, 
      status: map['status'] ?? 'activate',
      type: map['type'] ?? 'post',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Dart → Firestore
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'managers': managers,
      'members': members,
      'settings': settings, // Lưu Map trực tiếp lên Firestore
      'status': status,
      'type': type,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}