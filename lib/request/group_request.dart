import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_user.dart';

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
        settings: '',
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
  // =============== JOIN / LEAVE GROUP – ĐỒNG BỘ 2 CHIỀU ================
  // =====================================================================

  Future<void> joinGroup(String groupId, String userId) async {
    try {
      print('🔄 [GroupRequest] User $userId joining group $groupId');

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

  /// ✅ HƯỚNG DẪN: Tìm phương thức removeMemberFromGroup trong file group_request.dart của bạn
  /// và THAY THẾ nó bằng phương thức này:

  /// ✅ UPDATED: Xóa thành viên khỏi nhóm - Đồng bộ cả managers và members
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      print('🔄 [GroupRequest] Removing user $userId from group $groupId');

      // 1. Lấy thông tin nhóm để kiểm tra xem user có phải manager không
      final groupDoc =
          await _firestore.collection(_collectionName).doc(groupId).get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final managers = List<String>.from(groupData['managers'] ?? []);
      final isManager = managers.contains(userId);

      // 2. Xóa khỏi group (cả members và managers nếu là manager)
      final Map<String, dynamic> updateData = {
        'members': FieldValue.arrayRemove([userId]),
      };

      // Nếu là manager thì cũng xóa khỏi danh sách managers
      if (isManager) {
        print('   └─ User is manager, removing from managers list too');
        updateData['managers'] = FieldValue.arrayRemove([userId]);
      }

      await _firestore
          .collection(_collectionName)
          .doc(groupId)
          .update(updateData);

      print('   ✓ Removed from group collection');

      // 3. Xóa groupId khỏi user.groups
      await _firestore.collection(_userCollectionName).doc(userId).update({
        'groups': FieldValue.arrayRemove([groupId]),
      });

      print('   ✓ Removed from user collection');
      print('✅ [GroupRequest] Remove member sync completed successfully');
    } catch (e) {
      print('❌ [GroupRequest] Error removing member: $e');
      rethrow;
    }
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await removeMemberFromGroup(groupId, userId);
  }

  // =====================================================================
  // ======================= GET / STREAM GROUPS =========================
  // =====================================================================

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

  /// 🔍 Tìm kiếm nhóm theo tên — CHỈ NHÓM BÀI ĐĂNG (type = "post")
  /// ✅ FIX: Không dùng isNotEqualTo để tránh lỗi composite index
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

      // ✅ CHỈ FILTER type="post" TRÊN SERVER
      // Không dùng isNotEqualTo để tránh cần composite index
      final snapshot =
          await _firestore
              .collection(_collectionName)
              .where('type', isEqualTo: 'post') // CHỈ LẤY NHÓM BÀI ĐĂNG
              .limit(100)
              .get();

      print(
        '📦 [GroupRequest] Loaded ${snapshot.docs.length} documents from Firestore',
      );

      if (snapshot.docs.isEmpty) {
        print('⚠️ [GroupRequest] No documents found with type="post"');
        print(
          '💡 [GroupRequest] Check if any groups have type="post" in Firestore',
        );
        return [];
      }

      // Debug: In ra TẤT CẢ documents
      print('📋 [GroupRequest] Documents found:');
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('   📄 ID: ${doc.id}');
        print('      └─ name: ${data['name']}');
        print('      └─ type: ${data['type']}');
        print('      └─ status: ${data['status']}');
      }

      // Parse và filter ở client
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
                // Loại bỏ nhóm đã xóa
                if (g.status == 'deleted') {
                  print('   🗑️ Filtered out deleted group: ${g.name}');
                  return false;
                }

                // Filter theo tên hoặc mô tả
                final nameLower = g.name.toLowerCase();
                final descLower = g.description.toLowerCase();

                final matches =
                    nameLower.contains(queryLower) ||
                    descLower.contains(queryLower);

                if (matches) {
                  print('   ✓ Match found: "${g.name}"');
                }

                return matches;
              })
              .toList();

      print('✅ [GroupRequest] Found ${results.length} matching groups');
      print('🔍 [GroupRequest] ============================================\n');

      return results;
    } catch (e) {
      print('❌ [GroupRequest] searchGroups error: $e');
      print('   Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// 🔍 Alternative: Tìm kiếm KHÔNG CẦN biết type (lấy tất cả)
  /// Dùng khi cần test hoặc debug
  Future<List<GroupModel>> searchAllGroups(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      print('🔍 [GroupRequest] Searching ALL group types...');

      final queryLower = query.toLowerCase().trim();

      // Lấy tất cả nhóm (không filter gì cả)
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
                // Filter ở client: type=post, status!=deleted, tên khớp
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
}
