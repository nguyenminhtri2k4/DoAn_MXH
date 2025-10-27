
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // document ID
  final String uid; // uid Firebase Auth
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
    this.lastActive,
    required this.notificationSettings,
    List<String>? locketFriends, 
  }) : locketFriends = locketFriends ?? []; 

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    int parseCount(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is List && value.isNotEmpty) {
        final lastElement = value.last;
        if (lastElement is int) return lastElement;
        if (lastElement is String) return int.tryParse(lastElement) ?? 0;
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
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      phone: data['phone'] ?? '',
      bio: data['bio'] ?? 'No',
      gender: data['gender'] ?? '',
      liveAt: data['liveAt'] ?? '',
      comeFrom: data['comeFrom'] ?? '',
      role: data['role'] ?? 'user',
      relationship: data['relationship'] ?? '',
      statusAccount: data['statusAccount'] ?? data['statusAccont'] ?? 'active',
      backgroundImageUrl: data['backgroundImageUrl'] ?? '', 
      avatar: parseStringList(data['avatar']),
      friends: parseStringList(data['friends']),
      locketFriends: parseStringList(data['locketFriends']), 
      groups: parseStringList(data['groups']),
      posterList: parseStringList(data['posterList']),
      followerCount: parseCount(data['followerCount']),
      followingCount: parseCount(data['followingCount']),
      createAt: (data['createAt'] as Timestamp).toDate(),
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
      notificationSettings:
          Map<String, bool>.from(data['notificationSettings'] ?? {}),
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
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'lastActive':
          lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'notificationSettings': notificationSettings,
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
    Map<String, bool>? notificationSettings, // <--- THÊM LẠI DÒNG NÀY
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
      notificationSettings: notificationSettings ?? this.notificationSettings, // <--- THÊM LẠI DÒNG NÀY
    );
  }
}