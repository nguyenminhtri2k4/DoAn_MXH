
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String bio;
  final String gender;
  final String liveAt;
  final String comeFrom;
  final String role;
  final String relationship;
  final String statusAccount;
  final String backgroundImageUrl;

  final List<String> avatar;
  final List<String> friends;
  final List<String> locketFriends;
  final List<String> groups;
  final List<String> posterList;
  final int followerCount;
  final int followingCount;

  final DateTime createAt;
  final DateTime? dateOfBirth;
  final DateTime? lastActive;
  final bool serviceGemini;
  final bool isOnline; // <--- TRƯỜNG MỚI

  final Map<String, bool> notificationSettings;

  UserModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.bio,
    required this.gender,
    required this.liveAt,
    required this.comeFrom,
    required this.role,
    required this.relationship,
    required this.statusAccount,
    required this.backgroundImageUrl,
    required this.avatar,
    required this.friends,
    required this.groups,
    required this.posterList,
    required this.followerCount,
    required this.followingCount,
    required this.createAt,
    this.dateOfBirth,
    this.serviceGemini = false,
    this.isOnline = false, // <--- DEFAULT LÀ FALSE
    this.lastActive,
    required this.notificationSettings,
    List<String>? locketFriends,
  }) : locketFriends = locketFriends ?? [];

  int get friendsCount => friends.length;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    int parseCount(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is List && value.isNotEmpty) {
        final last = value.last;
        if (last is int) return last;
        if (last is String) return int.tryParse(last) ?? 0;
      }
      return 0;
    }

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return UserModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      phone: data['phone'] ?? '',
      bio: data['bio'] ?? 'No',
      gender: data['gender'] ?? '',
      liveAt: data['liveAt'] ?? '',
      comeFrom: data['comeFrom'] ?? '',
      role: data['role'] ?? 'user',
      relationship: data['relationship'] ?? '',
      statusAccount: data['statusAccount'] ?? 'active',
      backgroundImageUrl: data['backgroundImageUrl'] ?? '',
      avatar: parseStringList(data['avatar']),
      friends: parseStringList(data['friends']),
      locketFriends: parseStringList(data['locketFriends']),
      groups: parseStringList(data['groups']),
      posterList: parseStringList(data['posterList']),
      followerCount: parseCount(data['followerCount']),
      followingCount: parseCount(data['followingCount']),
      createAt: data['createAt'] is Timestamp
          ? (data['createAt'] as Timestamp).toDate()
          : DateTime.now(),
      dateOfBirth: data['dateOfBirth'] is Timestamp
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      lastActive: data['lastActive'] is Timestamp
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
      notificationSettings: (data['notificationSettings'] is Map)
          ? Map<String, bool>.from(data['notificationSettings'])
          : {},
      serviceGemini: data['servicegemini'] ?? false,
      isOnline: data['isOnline'] ?? false, // <--- LẤY TỪ FIRESTORE
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'bio': bio,
      'gender': gender,
      'liveAt': liveAt,
      'comeFrom': comeFrom,
      'role': role,
      'relationship': relationship,
      'statusAccount': statusAccount,
      'backgroundImageUrl': backgroundImageUrl,
      'avatar': avatar,
      'friends': friends,
      'locketFriends': locketFriends,
      'groups': groups,
      'posterList': posterList,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'createAt': Timestamp.fromDate(createAt),
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'notificationSettings': notificationSettings,
      'servicegemini': serviceGemini,
      'isOnline': isOnline, // <--- LƯU VÀO FIRESTORE
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? bio,
    String? phone,
    String? gender,
    String? liveAt,
    String? comeFrom,
    String? relationship,
    String? backgroundImageUrl,
    List<String>? avatar,
    List<String>? friends,
    List<String>? locketFriends,
    List<String>? groups,
    List<String>? posterList,
    int? followerCount,
    int? followingCount,
    DateTime? dateOfBirth,
    DateTime? lastActive,
    Map<String, bool>? notificationSettings,
    bool? serviceGemini,
    bool? isOnline, // <--- CẬP NHẬT QUA COPYWITH
  }) {
    return UserModel(
      id: id ?? this.id,
      uid: uid,
      name: name ?? this.name,
      email: email,
      password: password,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      liveAt: liveAt ?? this.liveAt,
      comeFrom: comeFrom ?? this.comeFrom,
      role: role,
      relationship: relationship ?? this.relationship,
      statusAccount: statusAccount,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      avatar: avatar ?? this.avatar,
      friends: friends ?? this.friends,
      locketFriends: locketFriends ?? this.locketFriends,
      groups: groups ?? this.groups,
      posterList: posterList ?? this.posterList,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      createAt: createAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      lastActive: lastActive ?? this.lastActive,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      serviceGemini: serviceGemini ?? this.serviceGemini,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}