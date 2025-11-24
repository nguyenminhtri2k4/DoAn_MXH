import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/storage_request.dart';
import 'package:mangxahoi/request/group_request.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GroupManagementViewModel extends ChangeNotifier {
  final String groupId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRequest _userRequest = UserRequest();
  final StorageRequest _storageRequest = StorageRequest();
  final GroupRequest _groupRequest = GroupRequest();

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

  //Chuyển quyền sở hữu nhóm//
  Future<void> transferOwnership(String newOwnerId) async {
    if (!isOwner || currentUserId == null) return;

    try {
      await _groupRequest.transferOwnership(
        groupId,
        currentUserId!,
        newOwnerId,
      );
      await _loadGroup();
      await _loadMembers();
      notifyListeners();
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  // Cấp quyền quản lý //
  Future<void> promoteToManager(String userId) async {
    if (!isOwner) return;
    try {
      await _groupRequest.promoteToManager(groupId, userId);
      await _loadGroup();
      notifyListeners();
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  //Gỡ quyền quản lý //
  Future<void> demoteFromManager(String userId) async {
    if (!isOwner) return;
    try {
      await _groupRequest.demoteFromManager(groupId, userId);
      await _loadGroup();
      notifyListeners();
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  bool canTransferOwnership(String userId) {
    if (!isOwner) return false;
    if (userId == currentUserId) return false;
    if (userId == group?.ownerId) return false;
    return true;
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
    print('🔥 [GroupManagementVM] removeMember called for userId: $userId');
    if (!canManageMembers) {
      print('❌ [GroupManagementVM] User không có quyền xóa thành viên');
      return;
    }
    final isTargetManager = group?.managers.contains(userId) ?? false;
    if (isManager && !isOwner && isTargetManager) {
      print('❌ [GroupManagementVM] Manager không thể xóa Manager khác');
      return;
    }
    if (userId == currentUserId) {
      print('❌ [GroupManagementVM] Không thể tự xóa chính mình');
      return;
    }
    try {
      print('🔄 [GroupManagementVM] Bắt đầu xóa thành viên...');
      await _groupRequest.removeMemberFromGroup(groupId, userId);
      print(
        '✅ [GroupManagementVM] GroupRequest.removeMemberFromGroup thành công',
      );
      await _loadGroup();
      await _loadMembers();
      print('✅ [GroupManagementVM] Đã reload group và members');
      notifyListeners();
      print('✅ [GroupManagementVM] removeMember hoàn tất thành công');
    } catch (e) {
      print('❌ [GroupManagementVM] Lỗi khi xóa thành viên: $e');
      rethrow;
    }
  }

  bool canRemoveMember(String userId) {
    if (userId == currentUserId) return false;
    if (userId == group?.ownerId) return false;
    if (isOwner) return true;
    if (isManager) {
      final isTargetManager = group?.managers.contains(userId) ?? false;
      return !isTargetManager;
    }
    return false;
  }

  // Giải tán nhóm //
  Future<void> disbandGroup() async {
    if (!isOwner || currentUserId == null || group == null) return;

    try {
      await _groupRequest.disbandGroup(groupId, currentUserId!);
      print('✅ Giải tán nhóm thành công');
    } catch (e) {
      print('❌ Lỗi: $e');
      rethrow;
    }
  }
}

extension GroupModelCopyWith on GroupModel {
  GroupModel copyWith({String? name, String? description, String? coverImage}) {
    return GroupModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      managers: managers,
      members: members,
      settings: settings,
      status: status,
      type: type,
      createdAt: createdAt,
    );
  }
}
