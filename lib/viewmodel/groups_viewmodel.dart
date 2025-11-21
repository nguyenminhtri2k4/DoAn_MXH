import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_disbanded_group.dart';
import 'package:mangxahoi/request/group_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/request/user_request.dart';

/// Model để lưu thông tin nhóm + trạng thái tồn tại
class GroupWithStatus {
  final String groupId;
  final GroupModel? group; // null nếu nhóm đã bị xóa
  final bool exists; // true nếu document Group tồn tại
  final DisbandedGroupModel? disbandedInfo; // Thông tin từ subcollection

  GroupWithStatus({
    required this.groupId,
    required this.group,
    required this.exists,
    this.disbandedInfo,
  });

  /// Nhóm đã bị giải tán (document không tồn tại)
  bool get isDisbanded => !exists;

  /// Lấy type của nhóm (từ group nếu còn tồn tại, hoặc từ disbandedInfo)
  String get type => group?.type ?? disbandedInfo?.type ?? 'chat';

  /// Lấy tên của nhóm (từ group nếu còn tồn tại, hoặc từ disbandedInfo)
  String get name =>
      group?.name ?? disbandedInfo?.name ?? 'Nhóm không xác định';
}

class GroupsViewModel extends ChangeNotifier {
  final GroupRequest _groupRequest = GroupRequest();
  final UserRequest _userRequest = UserRequest();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  // ✅ Stream trả về danh sách GroupWithStatus (bao gồm cả nhóm đã bị xóa)
  Stream<List<GroupWithStatus>>? _groupsWithStatusStream;
  Stream<List<GroupWithStatus>>? get groupsWithStatusStream =>
      _groupsWithStatusStream;

  GroupsViewModel() {
    _init();
  }

  void _init() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final user = await _userRequest.getUserByUid(firebaseUser.uid);
      if (user != null) {
        _currentUserId = user.id;

        // ✅ Lắng nghe thay đổi từ User document
        _groupsWithStatusStream = _firestore
            .collection('User')
            .doc(user.id)
            .snapshots()
            .asyncMap((userSnapshot) async {
              if (!userSnapshot.exists) return <GroupWithStatus>[];

              final userData = userSnapshot.data();
              final groupIds = List<String>.from(userData?['groups'] ?? []);

              // ✅ Lấy danh sách nhóm đã giải tán từ SUBCOLLECTION
              final disbandedSnapshot =
                  await _firestore
                      .collection('User')
                      .doc(user.id)
                      .collection('disbandedGroups')
                      .get();

              // Tạo map để tra cứu nhanh thông tin nhóm đã giải tán
              final Map<String, DisbandedGroupModel> disbandedMap = {};
              for (var doc in disbandedSnapshot.docs) {
                final disbanded = DisbandedGroupModel.fromMap(
                  doc.id,
                  doc.data(),
                );
                disbandedMap[disbanded.groupId] = disbanded;
              }

              final List<GroupWithStatus> result = [];

              for (String gid in groupIds) {
                try {
                  final groupDoc =
                      await _firestore.collection('Group').doc(gid).get();

                  if (groupDoc.exists) {
                    // Document tồn tại → parse GroupModel
                    final group = GroupModel.fromMap(
                      groupDoc.id,
                      groupDoc.data()!,
                    );
                    result.add(
                      GroupWithStatus(groupId: gid, group: group, exists: true),
                    );
                  } else {
                    // Document KHÔNG tồn tại → nhóm đã bị giải tán
                    // Lấy thông tin từ subcollection disbandedGroups
                    result.add(
                      GroupWithStatus(
                        groupId: gid,
                        group: null,
                        exists: false,
                        disbandedInfo: disbandedMap[gid],
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Error checking group $gid: $e');
                  result.add(
                    GroupWithStatus(
                      groupId: gid,
                      group: null,
                      exists: false,
                      disbandedInfo: disbandedMap[gid],
                    ),
                  );
                }
              }

              return result;
            });

        notifyListeners();
      }
    }
  }

  Future<void> removeGroupFromUser(String groupId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('User').doc(_currentUserId).update({
        'groups': FieldValue.arrayRemove([groupId]),
      });
      await _firestore
          .collection('User')
          .doc(_currentUserId)
          .collection('disbandedGroups')
          .doc(groupId)
          .delete();

      print(
        '✅ Đã xóa groupId $groupId và disbandedGroups doc khỏi User $_currentUserId',
      );
    } catch (e) {
      print('❌ Lỗi khi xóa groupId: $e');
      rethrow;
    }
  }
}
