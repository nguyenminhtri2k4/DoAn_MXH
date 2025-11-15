
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_user.dart';

class GroupRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Group';
  final String _userCollectionName = 'User'; // <-- THÊM

  // ========== SỬA LỖI: Đồng bộ 2 chiều ==========
  
  /// Tạo nhóm mới (đã đồng bộ 2 chiều)
  Future<void> createGroup(String name, List<UserModel> members, String ownerId, String type) async {
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
      final docRef = await _firestore.collection(_collectionName).add(newGroup.toMap());
      final groupId = docRef.id;
      
      print('✅ [GroupRequest] Created group: $groupId');

      // 2. ✨ CÂP NHẬT TRƯỜNG groups CHO TẤT CẢ THÀNH VIÊN
      final batch = _firestore.batch();
      for (String memberId in memberIds) {
        final userRef = _firestore.collection(_userCollectionName).doc(memberId);
        batch.update(userRef, {
          'groups': FieldValue.arrayUnion([groupId])
        });
      }
      await batch.commit();
      
      print('✅ [GroupRequest] Updated groups field for ${memberIds.length} members');
    } catch (e) {
      print('❌ [GroupRequest] Error creating group: $e');
      rethrow;
    }
  }

  /// Tham gia nhóm (đã đồng bộ 2 chiều)
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      print('🔄 [GroupRequest] User $userId joining group $groupId');
      
      // 1. Thêm user vào nhóm
      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      await groupRef.update({
        'members': FieldValue.arrayUnion([userId]),
      });
      print('✅ [GroupRequest] Added user to group.members');

      // 2. ✨ THÊM groupId VÀO user.groups
      final userRef = _firestore.collection(_userCollectionName).doc(userId);
      await userRef.update({
        'groups': FieldValue.arrayUnion([groupId]),
      });
      print('✅ [GroupRequest] Added group to user.groups');
      
    } catch (e) {
      print('❌ [GroupRequest] Error joining group: $e');
      rethrow;
    }
  }

  /// Thêm nhiều thành viên vào nhóm (đã đồng bộ 2 chiều)
  Future<void> addMembersToGroup(String groupId, List<UserModel> newMembers) async {
    try {
      final newMemberIds = newMembers.map((user) => user.id).toList();
      
      // 1. Thêm members vào nhóm
      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      await groupRef.update({
        'members': FieldValue.arrayUnion(newMemberIds),
      });

      // 2. ✨ CÂP NHẬT user.groups CHO TẤT CẢ THÀNH VIÊN MỚI
      final batch = _firestore.batch();
      for (String memberId in newMemberIds) {
        final userRef = _firestore.collection(_userCollectionName).doc(memberId);
        batch.update(userRef, {
          'groups': FieldValue.arrayUnion([groupId])
        });
      }
      await batch.commit();
      
      print('✅ [GroupRequest] Added ${newMemberIds.length} members with sync');
    } catch (e) {
      print('❌ [GroupRequest] Error adding members: $e');
      rethrow;
    }
  }

  /// Xóa thành viên khỏi nhóm (đã đồng bộ 2 chiều)
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      print('🔄 [GroupRequest] Removing user $userId from group $groupId');
      
      // 1. Xóa user khỏi group.members
      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      await groupRef.update({
        'members': FieldValue.arrayRemove([userId]),
      });
      print('✅ [GroupRequest] Removed user from group.members');

      // 2. ✨ XÓA groupId KHỎI user.groups
      final userRef = _firestore.collection(_userCollectionName).doc(userId);
      await userRef.update({
        'groups': FieldValue.arrayRemove([groupId]),
      });
      print('✅ [GroupRequest] Removed group from user.groups');
      
    } catch (e) {
      print('❌ [GroupRequest] Error removing member: $e');
      rethrow;
    }
  }

  /// Rời khỏi nhóm (đã đồng bộ 2 chiều)
  Future<void> leaveGroup(String groupId, String userId) async {
    await removeMemberFromGroup(groupId, userId);
  }

  // ========== KẾT THÚC PHẦN SỬA LỖI ==========

  Stream<List<GroupModel>> getGroupsByUserId(String userId) {
    print('🔍 [GroupRequest] getGroupsByUserId called for: $userId');
    
    return _firestore
        .collection(_collectionName)
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          print('📦 [GroupRequest] Found ${snapshot.docs.length} groups');
          
          if (snapshot.docs.isEmpty) {
            print('⚠️ [GroupRequest] No groups found for user $userId');
          }
          
          return snapshot.docs.map((doc) {
            return GroupModel.fromMap(doc.id, doc.data());
          }).toList();
        })
        .handleError((error) {
          print('❌ [GroupRequest] Stream error: $error');
          return <GroupModel>[];
        });
  }

  /// Lấy thông tin một nhóm theo ID
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(groupId).get();
      
      if (doc.exists && doc.data() != null) {
        return GroupModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Lỗi khi lấy thông tin nhóm $groupId: $e');
      return null;
    }
  }

  /// Lấy thông tin nhiều nhóm cùng lúc (cho việc filter bài viết)
  Future<Map<String, GroupModel>> getGroupsByIds(List<String> groupIds) async {
    if (groupIds.isEmpty) return {};

    try {
      final Map<String, GroupModel> groupsMap = {};
      
      for (int i = 0; i < groupIds.length; i += 10) {
        final batchIds = groupIds.skip(i).take(10).toList();
        
        if (batchIds.isEmpty) continue;

        final snapshot = await _firestore
            .collection(_collectionName)
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (var doc in snapshot.docs) {
          if (doc.exists && doc.data() != null) {
            groupsMap[doc.id] = GroupModel.fromMap(doc.id, doc.data()!);
          }
        }
      }

      return groupsMap;
    } catch (e) {
      print('❌ Lỗi khi lấy thông tin nhiều nhóm: $e');
      return {};
    }
  }

  Stream<List<GroupModel>> getGroupsByIdsStream(List<String> groupIds) {
    if (groupIds.isEmpty) {
      return Stream.value([]);
    }

    List<Stream<List<GroupModel>>> streams = [];
    for (int i = 0; i < groupIds.length; i += 10) {
      final batchIds = groupIds.skip(i).take(10).toList();
      if (batchIds.isNotEmpty) {
        streams.add(_firestore
            .collection(_collectionName)
            .where(FieldPath.documentId, whereIn: batchIds)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => GroupModel.fromMap(doc.id, doc.data()))
                .toList()));
      }
    }

    if (streams.isNotEmpty) {
      return streams.first;
    } else {
      return Stream.value([]);
    }
  }

  /// Lấy tất cả nhóm mà user là thành viên
  Future<List<GroupModel>> getUserGroups(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('members', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => GroupModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('❌ Lỗi khi lấy danh sách nhóm của user: $e');
      return [];
    }
  }

  /// Kiểm tra xem user có phải thành viên của nhóm không
  Future<bool> isMemberOfGroup(String groupId, String userId) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) return false;
      
      return group.members.contains(userId);
    } catch (e) {
      print('❌ Lỗi khi kiểm tra thành viên: $e');
      return false;
    }
  }

  /// Kiểm tra xem user có quyền xem bài viết trong nhóm không
  Future<bool> canViewGroupPosts(String groupId, String userId) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) return false;
      
      if (group.status != 'private') {
        return true;
      }
      
      return group.members.contains(userId);
    } catch (e) {
      print('❌ Lỗi khi kiểm tra quyền xem: $e');
      return false;
    }
  }

  /// Lấy danh sách nhóm công khai (để khám phá)
  Future<List<GroupModel>> getPublicGroups({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('status', isNotEqualTo: 'private')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => GroupModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('❌ Lỗi khi lấy nhóm công khai: $e');
      return [];
    }
  }

  /// Cập nhật trạng thái privacy của nhóm
  Future<void> updateGroupPrivacy(String groupId, String status) async {
    try {
      await _firestore.collection(_collectionName).doc(groupId).update({
        'status': status,
      });
    } catch (e) {
      print('❌ Lỗi khi cập nhật privacy: $e');
      rethrow;
    }
  }

  /// Stream để lắng nghe thay đổi của một nhóm
  Stream<GroupModel?> watchGroup(String groupId) {
    return _firestore
        .collection(_collectionName)
        .doc(groupId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return GroupModel.fromMap(doc.id, doc.data()!);
          }
          return null;
        });
  }

  // ========== BONUS: Script sửa dữ liệu cũ ==========
  
  /// 🔧 Sửa dữ liệu cũ: Đồng bộ lại toàn bộ groups cho tất cả users
  /// CHỈ CHẠY MỘT LẦN để fix dữ liệu hiện tại
  Future<void> syncAllUserGroups() async {
    try {
      print('🔄 [SYNC] Starting to sync all user groups...');
      
      // 1. Lấy tất cả groups
      final groupsSnapshot = await _firestore.collection(_collectionName).get();
      print('📦 [SYNC] Found ${groupsSnapshot.docs.length} groups');
      
      // 2. Tạo map: userId -> [groupIds]
      Map<String, List<String>> userGroupsMap = {};
      
      for (var groupDoc in groupsSnapshot.docs) {
        final groupId = groupDoc.id;
        final members = List<String>.from(groupDoc.data()['members'] ?? []);
        
        for (String memberId in members) {
          if (!userGroupsMap.containsKey(memberId)) {
            userGroupsMap[memberId] = [];
          }
          userGroupsMap[memberId]!.add(groupId);
        }
      }
      
      print('👥 [SYNC] Processing ${userGroupsMap.length} users');
      
      // 3. Cập nhật trường groups cho tất cả users
      final batch = _firestore.batch();
      int count = 0;
      
      for (var entry in userGroupsMap.entries) {
        final userId = entry.key;
        final groupIds = entry.value;
        
        final userRef = _firestore.collection(_userCollectionName).doc(userId);
        batch.update(userRef, {'groups': groupIds});
        
        count++;
        
        // Firestore batch giới hạn 500 operations
        if (count % 500 == 0) {
          await batch.commit();
          print('✅ [SYNC] Committed batch $count');
        }
      }
      
      // Commit batch cuối cùng
      await batch.commit();
      print('✅ [SYNC] Sync completed! Updated ${userGroupsMap.length} users');
      
    } catch (e) {
      print('❌ [SYNC] Error syncing: $e');
      rethrow;
    }
  }
}