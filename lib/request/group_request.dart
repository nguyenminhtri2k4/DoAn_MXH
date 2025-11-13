
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mangxahoi/model/model_group.dart';
// import 'package:mangxahoi/model/model_user.dart';

// class GroupRequest {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String _collectionName = 'Group';

//   Future<void> createGroup(String name, List<UserModel> members, String ownerId, String type) async {
//     try {
//       final memberIds = members.map((user) => user.id).toList();

//       final newGroup = GroupModel(
//         id: '',
//         name: name,
//         ownerId: ownerId,
//         members: memberIds,
//         managers: [ownerId],
//         description: '',
//         coverImage: '', // Đảm bảo bạn đã thêm trường này trong model_group.dart
//         settings: '',
//         status: 'active',
//         type: type,
//         createdAt: DateTime.now(),
//       );

//       await _firestore.collection(_collectionName).add(newGroup.toMap());
//     } catch (e) {
//       print('Error creating group: $e');
//       rethrow;
//     }
//   }

//   Stream<List<GroupModel>> getGroupsByUserId(String userId) {
//     return _firestore
//         .collection(_collectionName)
//         .where('members', arrayContains: userId)
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//             .map((doc) => GroupModel.fromMap(doc.id, doc.data()))
//             .toList());
//   }

//   /// --- PHƯƠSNG THỨC MỚI ĐỂ THÊM THÀNH VIÊN ---
//   /// Cập nhật nhóm bằng cách thêm các thành viên mới (dùng arrayUnion)
//   Future<void> addMembersToGroup(String groupId, List<UserModel> newMembers) async {
//     try {
//       // Lấy danh sách ID từ UserModel
//       final newMemberIds = newMembers.map((user) => user.id).toList();

//       // Lấy tham chiếu đến tài liệu nhóm
//       final groupRef = _firestore.collection(_collectionName).doc(groupId);

//       // Sử dụng FieldValue.arrayUnion để thêm các ID mới vào mảng 'members'
//       // mà không bị trùng lặp
//       await groupRef.update({
//         'members': FieldValue.arrayUnion(newMemberIds),
//       });
//     } catch (e) {
//       print('Error adding members to group: $e');
//       rethrow;
//     }
//   }

//   // === THÊM PHƯƠNG THỨC NÀY (SỬA LỖI 1) ===
//   /// Tham gia nhóm bằng ID người dùng
//   Future<void> joinGroup(String groupId, String userId) async {
//     try {
//       final groupRef = _firestore.collection(_collectionName).doc(groupId);
//       // Sử dụng FieldValue.arrayUnion để thêm 1 ID mới vào mảng 'members'
//       await groupRef.update({
//         'members': FieldValue.arrayUnion([userId]),
//       });
//     } catch (e) {
//       print('Error joining group: $e');
//       rethrow;
//     }
//   }
//   // ==========================================
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_user.dart';

class GroupRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Group';

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

      await _firestore.collection(_collectionName).add(newGroup.toMap());
    } catch (e) {
      print('Error creating group: $e');
      rethrow;
    }
  }

  Stream<List<GroupModel>> getGroupsByUserId(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Thêm thành viên vào nhóm
  Future<void> addMembersToGroup(String groupId, List<UserModel> newMembers) async {
    try {
      final newMemberIds = newMembers.map((user) => user.id).toList();
      final groupRef = _firestore.collection(_collectionName).doc(groupId);

      await groupRef.update({
        'members': FieldValue.arrayUnion(newMemberIds),
      });
    } catch (e) {
      print('Error adding members to group: $e');
      rethrow;
    }
  }

  /// Tham gia nhóm bằng ID người dùng
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      await groupRef.update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error joining group: $e');
      rethrow;
    }
  }

  // ============ PHƯƠNG THỨC MỚI CHO PRIVACY ============

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
      
      // Firestore chỉ cho phép query 'in' với tối đa 10 items
      // Nên phải chia thành nhiều batch
      for (int i = 0; i < groupIds.length; i += 10) {
        final batch = groupIds.skip(i).take(10).toList();
        
        final snapshot = await _firestore
            .collection(_collectionName)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          if (doc.exists && doc.data() != null) {
            groupsMap[doc.id] = GroupModel.fromMap(doc.id, doc.data());
          }
        }
      }

      return groupsMap;
    } catch (e) {
      print('❌ Lỗi khi lấy thông tin nhiều nhóm: $e');
      return {};
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
      
      // Nếu nhóm công khai, ai cũng xem được
      if (group.status != 'private') {
        return true;
      }
      
      // Nếu nhóm riêng tư, chỉ thành viên mới xem được
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
        'status': status, // 'private' hoặc 'active' (công khai)
      });
    } catch (e) {
      print('❌ Lỗi khi cập nhật privacy: $e');
      rethrow;
    }
  }

  /// Xóa thành viên khỏi nhóm
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      await groupRef.update({
        'members': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print('❌ Lỗi khi xóa thành viên: $e');
      rethrow;
    }
  }

  /// Rời khỏi nhóm
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await removeMemberFromGroup(groupId, userId);
    } catch (e) {
      print('❌ Lỗi khi rời nhóm: $e');
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
}