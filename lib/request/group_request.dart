
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_join_request.dart'; // Đảm bảo import model này

class GroupRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Group';
  final String _userCollectionName = 'User';

  // =====================================================================
  // =============== TẠO NHÓM – ĐỒNG BỘ 2 CHIỀU ==========================
  // =====================================================================

  Future<void> createGroup(
    String name,
    List<UserModel> members,
    String ownerId,
    String type,
  ) async {
    try {
      final memberIds = members.map((user) => user.id).toList();

      final newGroup = GroupModel(
        id: '',
        name: name,
        ownerId: ownerId,
        members: memberIds,
        managers: [ownerId],
        description: '',
        coverImage: '',
        settings: {},
        status: 'active',
        type: type,
        createdAt: DateTime.now(),
      );

      // 1. Tạo nhóm
      final docRef = await _firestore
          .collection(_collectionName)
          .add(newGroup.toMap());
      final groupId = docRef.id;
      print('✅ [GroupRequest] Created group: $groupId');

      // 2. Đồng bộ trường user.groups
      final batch = _firestore.batch();
      for (String memberId in memberIds) {
        final userRef = _firestore
            .collection(_userCollectionName)
            .doc(memberId);
        batch.update(userRef, {
          'groups': FieldValue.arrayUnion([groupId]),
        });
      }
      await batch.commit();

      print(
        '✅ [GroupRequest] Updated groups field for ${memberIds.length} members',
      );
    } catch (e) {
      print('❌ [GroupRequest] Error creating group: $e');
      rethrow;
    }
  }


  // =====================================================================
  // FILE: group_request.dart - Cập nhật hàm joinGroup
  // =====================================================================

  // Future<void> joinGroup(String groupId, String userId) async {
  //   try {
  //     print('🔄 [GroupRequest] User $userId joining group $groupId');

  //     final groupDoc = await _firestore.collection(_collectionName).doc(groupId).get();
  //     if (!groupDoc.exists) {
  //       throw Exception('Nhóm không tồn tại');
  //     }

  //     final joinPermission = groupDoc.data()?['settings']?['join_permission'] ?? 'requires_approval';

  //     // Kiểm tra điều kiện tham gia
  //     if (joinPermission == 'closed') {
  //       throw Exception('Nhóm này đã khóa, không thể tham gia');
  //     }

  //     // ✅ LOGIC MỚI: Nếu cần phê duyệt -> Gửi request
  //     if (joinPermission == 'requires_approval') {
  //       print('⚠️ [GroupRequest] Group requires approval. Sending request...');
  //       // Gọi hàm gửi yêu cầu
  //       await sendJoinRequest(groupId, userId);
        
  //       // Ném exception với thông báo để ViewModel hiển thị SnackBar và KHÔNG cập nhật UI thành "Đã tham gia"
  //       throw Exception('Đã gửi yêu cầu tham gia. Vui lòng chờ phê duyệt.');
  //     }

  //     // joinPermission == 'open' → Thêm thành viên ngay
  //     await _firestore.collection(_collectionName).doc(groupId).update({
  //       'members': FieldValue.arrayUnion([userId]),
  //     });

  //     await _firestore.collection(_userCollectionName).doc(userId).update({
  //       'groups': FieldValue.arrayUnion([groupId]),
  //     });

  //     print('✅ [GroupRequest] Sync join success');
  //   } catch (e) {
  //     print('❌ [GroupRequest] Error joining group: $e');
  //     rethrow;
  //   }
  // }
  // ✅ FILE: group_request.dart - Đơn giản hóa joinGroup
Future<void> joinGroup(String groupId, String userId) async {
  try {
    print('🔄 [GroupRequest] User $userId joining group $groupId');

    final groupDoc = await _firestore.collection(_collectionName).doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Nhóm không tồn tại');
    }

    final joinPermission = groupDoc.data()?['settings']?['join_permission'] ?? 'requires_approval';

    if (joinPermission == 'closed') {
      throw Exception('Nhóm này đã khóa, không thể tham gia');
    }

    if (joinPermission == 'requires_approval') {
      print('⚠️ [GroupRequest] Group requires approval. Sending request...');
      
      try {
        await sendJoinRequest(groupId, userId);
        // ✅ Throw exception với prefix "REQUEST_SENT:" để ViewModel nhận diện
        throw Exception('REQUEST_SENT:Đã gửi yêu cầu tham gia nhóm. Vui lòng chờ phê duyệt.');
      } catch (e) {
        rethrow;
      }
    }

    await _firestore.collection(_collectionName).doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });

    await _firestore.collection(_userCollectionName).doc(userId).update({
      'groups': FieldValue.arrayUnion([groupId]),
    });

    print('✅ [GroupRequest] Sync join success');
  } catch (e) {
    print('❌ [GroupRequest] Error joining group: $e');
    rethrow;
  }
}

  Future<void> addMembersToGroup(
    String groupId,
    List<UserModel> newMembers,
  ) async {
    try {
      final newMemberIds = newMembers.map((user) => user.id).toList();

      await _firestore.collection(_collectionName).doc(groupId).update({
        'members': FieldValue.arrayUnion(newMemberIds),
      });

      final batch = _firestore.batch();
      for (String uid in newMemberIds) {
        batch.update(_firestore.collection(_userCollectionName).doc(uid), {
          'groups': FieldValue.arrayUnion([groupId]),
        });
      }
      await batch.commit();

      print('✅ [GroupRequest] Added ${newMemberIds.length} members with sync');
    } catch (e) {
      print('❌ [GroupRequest] Error adding members: $e');
      rethrow;
    }
  }

  ///UPDATED: Xóa thành viên khỏi nhóm
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      print('🔄 [GroupRequest] ========================================');
      print('🔄 [GroupRequest] Removing user from group');
      print('   └─ GroupId: $groupId');
      print('   └─ UserId: $userId');

      final WriteBatch batch = _firestore.batch();
      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      final groupDoc = await groupRef.get();
      if (groupDoc.exists) {
        final groupData = groupDoc.data()!;
        final managers = List<String>.from(groupData['managers'] ?? []);
        final isManager = managers.contains(userId);

        if (isManager) {
          batch.update(groupRef, {
            'managers': FieldValue.arrayRemove([userId]),
            'members': FieldValue.arrayRemove([userId]),
          });
          print('   └─ User is MANAGER -> Remove from managers + members');
        } else {
          batch.update(groupRef, {
            'members': FieldValue.arrayRemove([userId]),
          });
          print('   └─ User is MEMBER -> Remove from members only');
        }
      } else {
        print('   └─ Group not found, skipping group update');
      }
      final userRef = _firestore.collection(_userCollectionName).doc(userId);
      batch.update(userRef, {
        'groups': FieldValue.arrayRemove([groupId]),
      });
      print('   └─ Remove groupId from User.groups');
      await batch.commit();
      print('✅ [GroupRequest] Remove member completed!');
      print('🔄 [GroupRequest] ========================================');
    } catch (e) {
      print('❌ [GroupRequest] Error: $e');
      rethrow;
    }
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await removeMemberFromGroup(groupId, userId);
  }

  Stream<List<GroupModel>> getGroupsByUserId(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('members', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => GroupModel.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(groupId).get();
      if (doc.exists && doc.data() != null) {
        return GroupModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getGroupById: $e');
      return null;
    }
  }

  //Chuyển quyền sở hữu nhóm//
  Future<void> transferOwnership(
    String groupId,
    String currentOwnerId,
    String newOwnerId,
  ) async {
    try {
      print('🔄 [GroupRequest] Transfer Ownership');
      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      await groupRef.update({
        'managers': FieldValue.arrayUnion([newOwnerId]),
      });
      await groupRef.update({
        'managers': FieldValue.arrayRemove([currentOwnerId]),
      });
      await groupRef.update({'ownerId': newOwnerId});

      print('✅ [GroupRequest] Transfer completed');
    } catch (e) {
      print('❌ [GroupRequest] Error: $e');
      rethrow;
    }
  }

  //Cấp quyền quản lý//
  Future<void> promoteToManager(String groupId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(groupId).update({
        'managers': FieldValue.arrayUnion([userId]),
      });
      print('✅ Promoted to manager');
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  //Gỡ quyền quản lý//
  Future<void> demoteFromManager(String groupId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(groupId).update({
        'managers': FieldValue.arrayRemove([userId]),
      });
      print('✅ Demoted from manager');
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  // Giải tán nhóm //
  Future<void> disbandGroup(String groupId, String ownerId) async {
    try {
      print('🔥 Disbanding group $groupId');
      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      final groupDoc = await groupRef.get();
      if (!groupDoc.exists) throw Exception('Group not found');
      final groupData = groupDoc.data()!;
      final groupName = groupData['name'] as String;
      final groupType = groupData['type'] as String;
      final memberIds = List<String>.from(groupData['members'] ?? []);
      final batch = _firestore.batch();
      for (String memberId in memberIds) {
        if (memberId != ownerId) {
          final ref = _firestore
              .collection(_userCollectionName)
              .doc(memberId)
              .collection('disbandedGroups')
              .doc(groupId);
          batch.set(ref, {
            'groupId': groupId,
            'name': groupName,
            'type': groupType,
            'disbandedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
      await _firestore.collection(_userCollectionName).doc(ownerId).update({
        'groups': FieldValue.arrayRemove([groupId]),
      });
      final chatQuery =
          await _firestore
              .collection('Chat')
              .where('groupId', isEqualTo: groupId)
              .get();
      final chatBatch = _firestore.batch();
      for (var doc in chatQuery.docs) {
        chatBatch.delete(doc.reference);
      }
      await chatBatch.commit();
      final settingsQuery = await groupRef.collection('settings').get();
      final settingsBatch = _firestore.batch();
      for (var doc in settingsQuery.docs) {
        settingsBatch.delete(doc.reference);
      }
      await settingsBatch.commit();
      await groupRef.delete();
      print('✅ Group disbanded');
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  Future<Map<String, GroupModel>> getGroupsByIds(List<String> groupIds) async {
    if (groupIds.isEmpty) return {};

    try {
      final Map<String, GroupModel> groupsMap = {};

      for (int i = 0; i < groupIds.length; i += 10) {
        final batchIds = groupIds.skip(i).take(10).toList();

        final snapshot =
            await _firestore
                .collection(_collectionName)
                .where(FieldPath.documentId, whereIn: batchIds)
                .get();

        for (var doc in snapshot.docs) {
          groupsMap[doc.id] = GroupModel.fromMap(doc.id, doc.data());
        }
      }

      return groupsMap;
    } catch (e) {
      print('❌ Error getGroupsByIds: $e');
      return {};
    }
  }

  Stream<List<GroupModel>> getGroupsByIdsStream(List<String> groupIds) {
    if (groupIds.isEmpty) return Stream.value([]);

    if (groupIds.length <= 10) {
      return _firestore
          .collection(_collectionName)
          .where(FieldPath.documentId, whereIn: groupIds)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => GroupModel.fromMap(doc.id, doc.data()))
                    .toList(),
          );
    }

    return Stream.value([]); // simple fallback
  }

  Future<List<GroupModel>> getUserGroups(String userId) async {
    try {
      final snap =
          await _firestore
              .collection(_collectionName)
              .where('members', arrayContains: userId)
              .get();

      return snap.docs.map((e) => GroupModel.fromMap(e.id, e.data())).toList();
    } catch (e) {
      print('❌ error getUserGroups: $e');
      return [];
    }
  }

  Future<bool> isMemberOfGroup(String groupId, String userId) async {
    final group = await getGroupById(groupId);
    return group?.members.contains(userId) ?? false;
  }

  Future<bool> canViewGroupPosts(String groupId, String userId) async {
    final group = await getGroupById(groupId);
    if (group == null) return false;

    if (group.status != 'private') return true;
    return group.members.contains(userId);
  }

  Future<List<GroupModel>> getPublicGroups({int limit = 20}) async {
    try {
      final snap =
          await _firestore
              .collection(_collectionName)
              .where('status', isNotEqualTo: 'private')
              .limit(limit)
              .get();

      return snap.docs.map((e) => GroupModel.fromMap(e.id, e.data())).toList();
    } catch (e) {
      print('❌ error getPublicGroups: $e');
      return [];
    }
  }

  Future<void> updateGroupPrivacy(String groupId, String status) async {
    await _firestore.collection(_collectionName).doc(groupId).update({
      'status': status,
    });
  }

  Stream<GroupModel?> watchGroup(String groupId) {
    return _firestore.collection(_collectionName).doc(groupId).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return GroupModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }

  // =====================================================================
  // ============================ SEARCH GROUPS ==========================
  // =====================================================================

  Future<List<GroupModel>> searchGroups(String query) async {
    if (query.trim().isEmpty) {
      print('⚠️ [GroupRequest] Empty query, returning empty list');
      return [];
    }

    try {
      print('🔍 [GroupRequest] ============================================');
      print('🔍 [GroupRequest] Searching groups with query: "$query"');
      print('🔍 [GroupRequest] ============================================');

      final queryLower = query.toLowerCase().trim();

      final snapshot =
          await _firestore
              .collection(_collectionName)
              .where('type', isEqualTo: 'post')
              .limit(100)
              .get();

      print(
        '📦 [GroupRequest] Loaded ${snapshot.docs.length} documents from Firestore',
      );

      if (snapshot.docs.isEmpty) {
        print('⚠️ [GroupRequest] No documents found with type="post"');
        return [];
      }

      final results =
          snapshot.docs
              .map((doc) {
                try {
                  return GroupModel.fromMap(doc.id, doc.data());
                } catch (e) {
                  print('❌ [GroupRequest] Parse error for doc ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<GroupModel>()
              .where((g) {
                if (g.status == 'deleted') {
                  return false;
                }

                final nameLower = g.name.toLowerCase();
                final descLower = g.description.toLowerCase();

                final matches =
                    nameLower.contains(queryLower) ||
                    descLower.contains(queryLower);

                return matches;
              })
              .toList();

      print('✅ [GroupRequest] Found ${results.length} matching groups');
      print('🔍 [GroupRequest] ============================================\n');

      return results;
    } catch (e) {
      print('❌ [GroupRequest] searchGroups error: $e');
      return [];
    }
  }

  Future<List<GroupModel>> searchAllGroups(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      print('🔍 [GroupRequest] Searching ALL group types...');

      final queryLower = query.toLowerCase().trim();

      final snapshot =
          await _firestore.collection(_collectionName).limit(500).get();

      print('📦 [GroupRequest] Loaded ${snapshot.docs.length} total documents');

      final results =
          snapshot.docs
              .map((doc) {
                try {
                  return GroupModel.fromMap(doc.id, doc.data());
                } catch (e) {
                  return null;
                }
              })
              .whereType<GroupModel>()
              .where((g) {
                if (g.type != 'post') return false;
                if (g.status == 'deleted') return false;

                final nameLower = g.name.toLowerCase();
                final descLower = g.description.toLowerCase();

                return nameLower.contains(queryLower) ||
                    descLower.contains(queryLower);
              })
              .toList();

      print('✅ [GroupRequest] Found ${results.length} post groups');
      return results;
    } catch (e) {
      print('❌ [GroupRequest] searchAllGroups error: $e');
      return [];
    }
  }

  // =====================================================================
  // ======================= SYNC DỮ LIỆU CŨ ==============================
  // =====================================================================

  Future<void> syncAllUserGroups() async {
    try {
      print('🔄 SYNC START');

      final groupsSnapshot = await _firestore.collection(_collectionName).get();

      Map<String, List<String>> userGroupsMap = {};

      for (var g in groupsSnapshot.docs) {
        final members = List<String>.from(g['members'] ?? []);
        for (var uid in members) {
          userGroupsMap.putIfAbsent(uid, () => []);
          userGroupsMap[uid]!.add(g.id);
        }
      }

      final batch = _firestore.batch();
      int count = 0;

      userGroupsMap.forEach((uid, groupIds) {
        final ref = _firestore.collection(_userCollectionName).doc(uid);
        batch.update(ref, {'groups': groupIds});
        count++;

        if (count % 500 == 0) batch.commit();
      });

      await batch.commit();
      print('✅ SYNC DONE — updated $count users');
    } catch (e) {
      print('❌ SYNC ERROR: $e');
    }
  }

  /// Cập nhật cài đặt nhóm (Settings Map)
  Future<void> updateGroupSettings(String groupId, Map<String, dynamic> newSettings) async {
    try {
      print('🔄 [GroupRequest] Updating settings for group $groupId');
      
      await _firestore.collection(_collectionName).doc(groupId).update({
        'settings': newSettings,
      });
      
      print('✅ [GroupRequest] Settings updated successfully');
    } catch (e) {
      print('❌ [GroupRequest] Error updating settings: $e');
      rethrow;
    }
  }

  Future<void> updateMessagingPermission(
    String groupId,
    String permission,
  ) async {
    try {
      print('🔄 [GroupRequest] Updating messaging permission for group $groupId');

      final groupRef = _firestore.collection(_collectionName).doc(groupId);

      final groupDoc = await groupRef.get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final currentSettings =
          Map<String, dynamic>.from(groupDoc.data()?['settings'] ?? {});

      currentSettings['messaging_permission'] = permission;

      await groupRef.update({
        'settings': currentSettings,
      });

      print(
        '✅ [GroupRequest] Messaging permission updated to: $permission',
      );
    } catch (e) {
      print('❌ [GroupRequest] Error updating messaging permission: $e');
      rethrow;
    }
  }

  Future<void> updateJoinPermission(
    String groupId,
    String permission,
  ) async {
    try {
      print('🔄 [GroupRequest] Updating join permission for group $groupId');

      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      final groupDoc = await groupRef.get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final currentSettings =
          Map<String, dynamic>.from(groupDoc.data()?['settings'] ?? {});

      currentSettings['join_permission'] = permission;

      await groupRef.update({
        'settings': currentSettings,
      });

      print(
        '✅ [GroupRequest] Join permission updated to: $permission',
      );
    } catch (e) {
      print('❌ [GroupRequest] Error updating join permission: $e');
      rethrow;
    }
  }

  Future<void> updatePostPermission(
    String groupId,
    String permission,
  ) async {
    try {
      print('🔄 [GroupRequest] Updating post permission for group $groupId');

      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      final groupDoc = await groupRef.get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final currentSettings =
          Map<String, dynamic>.from(groupDoc.data()?['settings'] ?? {});

      currentSettings['post_permission'] = permission;

      await groupRef.update({
        'settings': currentSettings,
      });

      print(
        '✅ [GroupRequest] Post permission updated to: $permission',
      );
    } catch (e) {
      print('❌ [GroupRequest] Error updating post permission: $e');
      rethrow;
    }
  }

  /// Gửi yêu cầu tham gia nhóm
  /// Lưu vào: Group/{groupId}/requests/{requestId} (Sub-collection)
  Future<void> sendJoinRequest(String groupId, String userId) async {
    try {
      print('🔄 [GroupRequest] Sending join request: User $userId -> Group $groupId');
      
      // 1. Kiểm tra xem user này đã có yêu cầu nào đang 'pending' trong sub-collection chưa
      final existingQuery = await _firestore
          .collection(_collectionName) // Truy cập Collection 'Group'
          .doc(groupId)                // Truy cập Document nhóm cụ thể
          .collection('requests')      // 👉 ĐI VÀO SUB-COLLECTION 'requests'
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Bạn đã gửi yêu cầu tham gia rồi, vui lòng chờ phê duyệt.');
      }

      final request = JoinRequestModel(
        id: '',
        groupId: groupId,
        userId: userId,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      // 2. Thêm yêu cầu mới vào sub-collection
      await _firestore
          .collection(_collectionName) // 'Group'
          .doc(groupId)                // id nhóm
          .collection('requests')      // 👉 SUB-COLLECTION
          .add(request.toMap());

      print('✅ [GroupRequest] Join request sent successfully to Sub-collection');
    } catch (e) {
      print('❌ [GroupRequest] Error sending join request: $e');
      rethrow;
    }
  }

  /// Lấy danh sách yêu cầu đang chờ (Pending) từ Sub-collection
  Stream<List<JoinRequestModel>> getPendingJoinRequests(String groupId) {
    return _firestore
        .collection(_collectionName) // 'Group'
        .doc(groupId)                // id nhóm
        .collection('requests')      // 👉 SUB-COLLECTION
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JoinRequestModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Chấp nhận yêu cầu tham gia
  Future<void> approveJoinRequest(String groupId, String requestId, String userId) async {
    try {
      print('🔄 [GroupRequest] Approving request $requestId for user $userId');
      
      final batch = _firestore.batch();

      // 1. Cập nhật trạng thái trong Sub-collection thành 'approved'
      final requestRef = _firestore
          .collection(_collectionName) // 'Group'
          .doc(groupId)
          .collection('requests')      // 👉 SUB-COLLECTION
          .doc(requestId);
      
      batch.update(requestRef, {'status': 'approved'});

      // 2. Thêm user vào mảng members của Group (Document cha)
      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      batch.update(groupRef, {
        'members': FieldValue.arrayUnion([userId]),
      });

      // 3. Thêm group vào mảng groups của User (Đồng bộ 2 chiều)
      final userRef = _firestore.collection(_userCollectionName).doc(userId);
      batch.update(userRef, {
        'groups': FieldValue.arrayUnion([groupId]),
      });

      await batch.commit();
      print('✅ [GroupRequest] Request approved & Member synced');
    } catch (e) {
      print('❌ [GroupRequest] Error approving request: $e');
      rethrow;
    }
  }

  /// Từ chối yêu cầu tham gia
  Future<void> rejectJoinRequest(String groupId, String requestId) async {
    try {
      print('🔄 [GroupRequest] Rejecting request $requestId');
      // Cập nhật trạng thái trong Sub-collection thành 'rejected'
      await _firestore
          .collection(_collectionName)
          .doc(groupId)
          .collection('requests')      // 👉 SUB-COLLECTION
          .doc(requestId)
          .delete();
      print('✅ [GroupRequest] Request rejected');
    } catch (e) {
      print('❌ [GroupRequest] Error rejecting request: $e');
      rethrow;
    }
  }
}
class JoinRequestPendingException implements Exception {
  final String message;
  JoinRequestPendingException(this.message);
  
  @override
  String toString() => message;
}