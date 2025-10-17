
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
}