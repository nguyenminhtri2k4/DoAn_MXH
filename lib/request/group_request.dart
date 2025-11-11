
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
        coverImage: '', // Đảm bảo bạn đã thêm trường này trong model_group.dart
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

  /// --- PHƯƠSNG THỨC MỚI ĐỂ THÊM THÀNH VIÊN ---
  /// Cập nhật nhóm bằng cách thêm các thành viên mới (dùng arrayUnion)
  Future<void> addMembersToGroup(String groupId, List<UserModel> newMembers) async {
    try {
      // Lấy danh sách ID từ UserModel
      final newMemberIds = newMembers.map((user) => user.id).toList();

      // Lấy tham chiếu đến tài liệu nhóm
      final groupRef = _firestore.collection(_collectionName).doc(groupId);

      // Sử dụng FieldValue.arrayUnion để thêm các ID mới vào mảng 'members'
      // mà không bị trùng lặp
      await groupRef.update({
        'members': FieldValue.arrayUnion(newMemberIds),
      });
    } catch (e) {
      print('Error adding members to group: $e');
      rethrow;
    }
  }

  // === THÊM PHƯƠNG THỨC NÀY (SỬA LỖI 1) ===
  /// Tham gia nhóm bằng ID người dùng
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      final groupRef = _firestore.collection(_collectionName).doc(groupId);
      // Sử dụng FieldValue.arrayUnion để thêm 1 ID mới vào mảng 'members'
      await groupRef.update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error joining group: $e');
      rethrow;
    }
  }
  // ==========================================
}