
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_friend_request.dart';
import 'package:mangxahoi/model/model_friend.dart';
import 'package:mangxahoi/model/model_user.dart';

class FriendRequestManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _friendRequestCollection = 'FriendRequest';
  final String _userCollection = 'User';
  final String _friendCollection = 'Friend';
  final String _blockedCollection = 'Blocked';

  // ==================== A. CÁC HÀM QUẢN LÝ LỜI MỜI KẾT BẠN ====================

  Future<void> sendRequest(String fromUserId, String toUserId) async {
    if (fromUserId == toUserId) return;

    // 1. Kiểm tra trạng thái chặn
    final blockStatus = await checkBlockedStatus(fromUserId, toUserId);
    if (blockStatus['isBlocked'] == true) {
       if (blockStatus['blockedBy'] == toUserId) {
          throw Exception("Bạn không thể gửi lời mời do đã bị người này chặn.");
       } else {
          throw Exception("Bạn đã chặn người này. Hãy bỏ chặn để kết bạn.");
       }
    }

    // 2. Kiểm tra các trạng thái khác
    final status = await getFriendshipStatus(fromUserId, toUserId);
    if (status == 'friends') throw Exception("Hai bạn đã là bạn bè.");
    if (status == 'pending_sent') throw Exception("Đã gửi lời mời, đang chờ chấp nhận.");
    if (status == 'pending_received') throw Exception("Người này đã gửi lời mời cho bạn. Hãy kiểm tra.");

    // 3. Gửi lời mời
    final newRequest = FriendRequestModel(
      id: '',
      fromUserId: fromUserId,
      toUserId: toUserId,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    try {
      await _firestore.collection(_friendRequestCollection).add(newRequest.toMap());
    } catch (e) {
      throw Exception("Lỗi khi gửi lời mời: $e");
    }
  }

  Future<void> cancelSentRequest(String requestId) async {
    await _firestore.collection(_friendRequestCollection).doc(requestId).delete();
  }

  Stream<List<FriendRequestModel>> getIncomingRequests(String userId) {
    return _firestore
        .collection(_friendRequestCollection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequestModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<FriendRequestModel>> getSentRequests(String userId) {
    return _firestore
        .collection(_friendRequestCollection)
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequestModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> acceptRequest(FriendRequestModel request) async {
    final user1Id = request.fromUserId;
    final user2Id = request.toUserId;
    final batch = _firestore.batch();

    final requestRef = _firestore.collection(_friendRequestCollection).doc(request.id);
    batch.update(requestRef, {'status': 'accepted', 'updatedAt': FieldValue.serverTimestamp()});

    final newFriend = FriendModel(
      id: '',
      user1: user1Id,
      user2: user2Id,
      status: 'accepted',
      createdAt: DateTime.now(),
    );
    final friendRef = _firestore.collection(_friendCollection).doc();
    batch.set(friendRef, newFriend.toMap());

    final user1Ref = _firestore.collection(_userCollection).doc(user1Id);
    batch.update(user1Ref, {
      'friends': FieldValue.arrayUnion([user2Id]),
      'followingCount': FieldValue.increment(1)
    });
    final user2Ref = _firestore.collection(_userCollection).doc(user2Id);
    batch.update(user2Ref, {
      'friends': FieldValue.arrayUnion([user1Id]),
      'followingCount': FieldValue.increment(1)
    });

    await batch.commit();
  }

  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection(_friendRequestCollection).doc(requestId).delete();
  }

  Future<String> getFriendshipStatus(String userId1, String userId2) async {
    if (userId1 == userId2) return 'self';

    final blockedStatus = await checkBlockedStatus(userId1, userId2);
    if (blockedStatus['isBlocked'] == true) return 'blocked';

    final user1Doc = await _firestore.collection(_userCollection).doc(userId1).get();
    if (!user1Doc.exists) return 'none';
    final userModel = UserModel.fromFirestore(user1Doc);
    if (userModel.friends.contains(userId2)) return 'friends';

    final sentQuery = await _firestore
        .collection(_friendRequestCollection)
        .where('fromUserId', isEqualTo: userId1)
        .where('toUserId', isEqualTo: userId2)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (sentQuery.docs.isNotEmpty) return 'pending_sent';

    final receivedQuery = await _firestore
        .collection(_friendRequestCollection)
        .where('fromUserId', isEqualTo: userId2)
        .where('toUserId', isEqualTo: userId1)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (receivedQuery.docs.isNotEmpty) return 'pending_received';

    return 'none';
  }

  // ==================== B. LOGIC HỦY BẠN, CHẶN, BỎ CHẶN ====================

  Future<void> unfriend(String userId1, String userId2) async {
    final batch = _firestore.batch();
    final friendQuery = await _firestore
        .collection(_friendCollection)
        .where('user1', whereIn: [userId1, userId2])
        .where('user2', whereIn: [userId1, userId2])
        .limit(1)
        .get();

    if (friendQuery.docs.isNotEmpty) {
      final friendDocId = friendQuery.docs.first.id;
      batch.delete(_firestore.collection(_friendCollection).doc(friendDocId));
    }

    final user1Ref = _firestore.collection(_userCollection).doc(userId1);
    batch.update(user1Ref, {
      'friends': FieldValue.arrayRemove([userId2]),
      'followingCount': FieldValue.increment(-1)
    });
    final user2Ref = _firestore.collection(_userCollection).doc(userId2);
    batch.update(user2Ref, {
      'friends': FieldValue.arrayRemove([userId1]),
      'followingCount': FieldValue.increment(-1)
    });
    await batch.commit();
  }

  Future<void> blockUser(String blockerId, String blockedId) async {
    final batch = _firestore.batch();
    final blockedRef = _firestore.collection(_blockedCollection).doc();
    batch.set(blockedRef, {
      'blockerId': blockerId,
      'blockedId': blockedId,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final friendQuery = await _firestore
        .collection(_friendCollection)
        .where('user1', whereIn: [blockerId, blockedId])
        .where('user2', whereIn: [blockerId, blockedId])
        .limit(1)
        .get();

    if (friendQuery.docs.isNotEmpty) {
      final friendDocId = friendQuery.docs.first.id;
      batch.delete(_firestore.collection(_friendCollection).doc(friendDocId));
    }

    final blockerUserRef = _firestore.collection(_userCollection).doc(blockerId);
    batch.update(blockerUserRef, {'friends': FieldValue.arrayRemove([blockedId])});

    final blockedUserRef = _firestore.collection(_userCollection).doc(blockedId);
    batch.update(blockedUserRef, {'friends': FieldValue.arrayRemove([blockerId])});

    await batch.commit();
  }

  Future<void> unblockUser(String blockerId, String blockedId) async {
    final blockedQuery = await _firestore
        .collection(_blockedCollection)
        .where('blockerId', isEqualTo: blockerId)
        .where('blockedId', isEqualTo: blockedId)
        .where('status', isEqualTo: 'active')
        .get();

    final batch = _firestore.batch();
    for (var doc in blockedQuery.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<List<String>> getBlockedUsers(String blockerId) {
    return _firestore
        .collection(_blockedCollection)
        .where('blockerId', isEqualTo: blockerId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()['blockedId'] as String).toList());
  }

  // ===> ĐÂY LÀ HÀM BỊ THIẾU, HÃY CHẮC CHẮN NÓ CÓ TRONG FILE <===
  Future<Map<String, dynamic>> checkBlockedStatus(String user1Id, String user2Id) async {
    try {
      final block1 = await _firestore
          .collection(_blockedCollection)
          .where('blockerId', isEqualTo: user1Id)
          .where('blockedId', isEqualTo: user2Id)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (block1.docs.isNotEmpty) {
        return {'isBlocked': true, 'blockedBy': user1Id};
      }

      final block2 = await _firestore
          .collection(_blockedCollection)
          .where('blockerId', isEqualTo: user2Id)
          .where('blockedId', isEqualTo: user1Id)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (block2.docs.isNotEmpty) {
        return {'isBlocked': true, 'blockedBy': user2Id};
      }

      return {'isBlocked': false, 'blockedBy': null};
    } catch (e) {
      print('❌ Lỗi kiểm tra chặn: $e');
      return {'isBlocked': false, 'blockedBy': null};
    }
  }
}