import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/storage_request.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GroupManagementViewModel extends ChangeNotifier {
  final String groupId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRequest _userRequest = UserRequest();
  final StorageRequest _storageRequest = StorageRequest();

  GroupModel? group;
  List<UserModel> members = [];
  Set<String> mutedMembers = {};

  UserModel? currentUser;

  bool isLoading = true;
  final String? currentUserId;

  GroupManagementViewModel({
    required this.groupId,
    required this.currentUserId,
  }) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _loadGroup();
      await _loadMembers();
      await _loadMutedMembers();

      if (currentUserId != null) {
        currentUser = await _userRequest.getUserData(currentUserId!);
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadGroup() async {
    final doc = await _firestore.collection('Group').doc(groupId).get();
    if (doc.exists) {
      group = GroupModel.fromMap(doc.id, doc.data()!);
    }
  }

  Future<void> _loadMembers() async {
    if (group == null) return;

    members.clear();
    for (String memberId in group!.members) {
      final user = await _userRequest.getUserData(memberId);
      if (user != null) {
        members.add(user);
      }
    }
    notifyListeners();
  }

  Future<void> _loadMutedMembers() async {
    try {
      final doc =
          await _firestore
              .collection('Group')
              .doc(groupId)
              .collection('settings')
              .doc('muted_members')
              .get();

      if (doc.exists) {
        mutedMembers = Set<String>.from(doc.data()?['members'] ?? []);
      }
    } catch (e) {
      print('Error loading muted members: $e');
    }
  }

  bool get isOwner => group?.ownerId == currentUserId;
  bool get isManager => group?.managers.contains(currentUserId) ?? false;
  bool get canEdit => isOwner || isManager;
  bool get canManageMembers => isOwner || isManager;
  bool get canInviteMembers {
    if (isOwner || isManager) return true;
    if (isPrivate) return false;
    return true;
  }

  bool get isPrivate => group?.status == 'private';

  String get messagingPermission {
    final settings = group?.settings ?? '';
    if (settings.contains('messaging:owner')) return 'owner';
    if (settings.contains('messaging:managers')) return 'managers';
    return 'all';
  }

  Future<void> updateGroupName(String newName) async {
    if (newName.isEmpty || !canEdit) return;

    try {
      await _firestore.collection('Group').doc(groupId).update({
        'name': newName,
      });

      group = group?.copyWith(name: newName);
      notifyListeners();
    } catch (e) {
      print('Error updating group name: $e');
    }
  }

  Future<void> updateGroupDescription(String newDescription) async {
    if (!canEdit) return;

    try {
      await _firestore.collection('Group').doc(groupId).update({
        'description': newDescription,
      });

      group = group?.copyWith(description: newDescription);
      notifyListeners();
    } catch (e) {
      print('Error updating group description: $e');
    }
  }

  Future<void> updateCoverImage(BuildContext context) async {
    if (!canEdit) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && currentUserId != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        final files = [File(image.path)];
        final mediaIds = await _storageRequest.uploadFilesAndCreateMedia(
          files,
          currentUserId!,
        );

        if (mediaIds.isNotEmpty) {
          final mediaDoc =
              await _firestore.collection('Media').doc(mediaIds.first).get();

          if (mediaDoc.exists) {
            final imageUrl = mediaDoc.data()?['url'] ?? '';

            await _firestore.collection('Group').doc(groupId).update({
              'coverImage': imageUrl,
            });

            await _loadGroup();
            notifyListeners();
          }
        }

        if (context.mounted) Navigator.pop(context);
      }
    } catch (e) {
      print('Error updating cover image: $e');
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> togglePrivacy(bool isPrivate) async {
    if (!isOwner) return;

    try {
      String newStatus = isPrivate ? 'private' : 'public';

      await _firestore.collection('Group').doc(groupId).update({
        'status': newStatus,
      });

      await _loadGroup();
      notifyListeners();
    } catch (e) {
      print('Error toggling privacy: $e');
    }
  }

  Future<void> updateMessagingPermission(String permission) async {
    if (!canEdit) return;

    try {
      String newSettings = group?.settings ?? '';

      newSettings = newSettings
          .replaceAll('messaging:owner', '')
          .replaceAll('messaging:managers', '')
          .replaceAll('messaging:all', '')
          .replaceAll(',,', ',');

      if (permission != 'all') {
        newSettings += ',messaging:$permission';
      }

      await _firestore.collection('Group').doc(groupId).update({
        'settings': newSettings,
      });

      await _loadGroup();
      notifyListeners();
    } catch (e) {
      print('Error updating messaging permission: $e');
    }
  }

  Future<void> promoteToManager(String userId) async {
    if (!isOwner) return;

    try {
      await _firestore.collection('Group').doc(groupId).update({
        'managers': FieldValue.arrayUnion([userId]),
      });

      await _loadGroup();
      notifyListeners();
    } catch (e) {
      print('Error promoting to manager: $e');
    }
  }

  Future<void> demoteFromManager(String userId) async {
    if (!isOwner) return;

    try {
      await _firestore.collection('Group').doc(groupId).update({
        'managers': FieldValue.arrayRemove([userId]),
      });

      await _loadGroup();
      notifyListeners();
    } catch (e) {
      print('Error demoting from manager: $e');
    }
  }

  Future<void> toggleMuteMember(String userId) async {
    if (!canManageMembers) return;

    try {
      final docRef = _firestore
          .collection('Group')
          .doc(groupId)
          .collection('settings')
          .doc('muted_members');

      if (mutedMembers.contains(userId)) {
        mutedMembers.remove(userId);
      } else {
        mutedMembers.add(userId);
      }

      await docRef.set({'members': mutedMembers.toList()});

      notifyListeners();
    } catch (e) {
      print('Error toggling mute: $e');
    }
  }

  Future<void> removeMember(String userId) async {
    if (!canManageMembers) return;

    try {
      await _firestore.collection('Group').doc(groupId).update({
        'members': FieldValue.arrayRemove([userId]),
      });

      if (group?.managers.contains(userId) ?? false) {
        await _firestore.collection('Group').doc(groupId).update({
          'managers': FieldValue.arrayRemove([userId]),
        });
      }

      await _loadGroup();
      await _loadMembers();
      notifyListeners();
    } catch (e) {
      print('Error removing member: $e');
    }
  }

  Future<void> disbandGroup() async {
    if (!isOwner || currentUserId == null) return;

    try {
      print('🔥 [GroupManagementVM] Bắt đầu giải tán nhóm $groupId');
      await _firestore.collection('Group').doc(groupId).update({
        'status': 'deleted',
        'managers': FieldValue.arrayRemove([currentUserId!]),
        'members': FieldValue.arrayRemove([currentUserId!]),
      });
      print(
        '   ✓ Đã đổi status thành deleted và xóa owner khỏi managers/members',
      );
      await _firestore.collection('User').doc(currentUserId).update({
        'groups': FieldValue.arrayRemove([groupId]),
      });
      print('   ✓ Đã xóa groupId khỏi User collection của owner');
      final chatQuery =
          await _firestore
              .collection('Chat')
              .where('groupId', isEqualTo: groupId)
              .get();

      for (var doc in chatQuery.docs) {
        await doc.reference.delete();
      }
      print('   ✓ Đã xóa ${chatQuery.docs.length} chat documents');

      print('✅ [GroupManagementVM] Giải tán nhóm thành công');
    } catch (e) {
      print('❌ [GroupManagementVM] Lỗi khi giải tán nhóm: $e');
    }
  }
}

extension GroupModelCopyWith on GroupModel {
  GroupModel copyWith({String? name, String? description, String? coverImage}) {
    return GroupModel(
      id: this.id,
      ownerId: this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      managers: this.managers,
      members: this.members,
      settings: this.settings,
      status: this.status,
      type: this.type,
      createdAt: this.createdAt,
    );
  }
}
