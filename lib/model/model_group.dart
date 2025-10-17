
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final List<String> managers;
  final List<String> members;
  final String settings;
  final String status;
  final String type;
  final DateTime? createdAt;

  GroupModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
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
      managers: List<String>.from(map['managers'] ?? []),
      members: List<String>.from(map['members'] ?? []),
      settings: map['settings'] ?? '',
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
      'managers': managers,
      'members': members,
      'settings': settings,
      'status': status,
      'type': type,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}