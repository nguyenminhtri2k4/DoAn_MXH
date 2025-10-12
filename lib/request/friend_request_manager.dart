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

  // ==================== A. CÁC HÀM CŨ (GIỮ NGUYÊN) ====================

  Future<bool> sendRequest(String fromUserId, String toUserId) async {
    if (fromUserId == toUserId) return false;
    final status = await getFriendshipStatus(fromUserId, toUserId);
    if (status != 'none') return false;

    final newRequest = FriendRequestModel(id: '', fromUserId: fromUserId, toUserId: toUserId, status: 'pending', createdAt: DateTime.now());
    try {
      await _firestore.collection(_friendRequestCollection).add(newRequest.toMap());
      return true;
    } catch (e) { rethrow; }
  }

  Future<void> cancelSentRequest(String requestId) async {
    await _firestore.collection(_friendRequestCollection).doc(requestId).delete();
  }

  Stream<List<FriendRequestModel>> getIncomingRequests(String userId) {
    return _firestore.collection(_friendRequestCollection).where('toUserId', isEqualTo: userId).where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => FriendRequestModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<FriendRequestModel>> getSentRequests(String userId) {
    return _firestore.collection(_friendRequestCollection).where('fromUserId', isEqualTo: userId).where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => FriendRequestModel.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> acceptRequest(FriendRequestModel request) async {
    final user1Id = request.fromUserId;
    final user2Id = request.toUserId;
    final batch = _firestore.batch();
    final requestRef = _firestore.collection(_friendRequestCollection).doc(request.id);
    batch.update(requestRef, {'status': 'accepted', 'updatedAt': FieldValue.serverTimestamp()});
    final newFriend = FriendModel(id: '', user1: user1Id, user2: user2Id, status: 'accepted', createdAt: DateTime.now());
    final friendRef = _firestore.collection(_friendCollection).doc();
    batch.set(friendRef, newFriend.toMap());
    final user1Ref = _firestore.collection(_userCollection).doc(user1Id);
    batch.update(user1Ref, {'friends': FieldValue.arrayUnion([user2Id]), 'followingCount': FieldValue.increment(1)});
    final user2Ref = _firestore.collection(_userCollection).doc(user2Id);
    batch.update(user2Ref, {'friends': FieldValue.arrayUnion([user1Id]), 'followingCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection(_friendRequestCollection).doc(requestId).delete();
  }

  Future<String> getFriendshipStatus(String userId1, String userId2) async {
    if (userId1 == userId2) return 'self';
    final user1Doc = await _firestore.collection(_userCollection).doc(userId1).get();
    if (!user1Doc.exists) return 'none';
    final userModel = UserModel.fromFirestore(user1Doc);
    if (userModel.friends.contains(userId2)) return 'friends';
    final sentQuery = await _firestore.collection(_friendRequestCollection).where('fromUserId', isEqualTo: userId1).where('toUserId', isEqualTo: userId2).where('status', isEqualTo: 'pending').limit(1).get();
    if (sentQuery.docs.isNotEmpty) return 'pending_sent';
    final receivedQuery = await _firestore.collection(_friendRequestCollection).where('fromUserId', isEqualTo: userId2).where('toUserId', isEqualTo: userId1).where('status', isEqualTo: 'pending').limit(1).get();
    if (receivedQuery.docs.isNotEmpty) return 'pending_received';
    return 'none';
  }

  // ==================== B. LOGIC HỦY BẠN, CHẶN, BỎ CHẶN (ĐÃ SỬA) ====================

  /// Hủy kết bạn (Chỉ dành cho trường hợp hủy bạn bè đơn thuần)
  Future<void> unfriend(String userId1, String userId2) async {
    final batch = _firestore.batch();
    final friendQuery = await _firestore.collection(_friendCollection).where('user1', whereIn: [userId1, userId2]).where('user2', whereIn: [userId1, userId2]).limit(1).get();

    if (friendQuery.docs.isNotEmpty) {
      final friendDocId = friendQuery.docs.first.id;
      final friendRef = _firestore.collection(_friendCollection).doc(friendDocId);
      batch.update(friendRef, {'status': 'unfriended'});
    }

    final user1Ref = _firestore.collection(_userCollection).doc(userId1);
    batch.update(user1Ref, {'friends': FieldValue.arrayRemove([userId2]), 'followingCount': FieldValue.increment(-1)});
    final user2Ref = _firestore.collection(_userCollection).doc(userId2);
    batch.update(user2Ref, {'friends': FieldValue.arrayRemove([userId1]), 'followingCount': FieldValue.increment(-1)});
    await batch.commit();
  }
  
  /// Chặn người dùng (Logic mới)
  Future<void> blockUser(String blockerId, String blockedId) async {
    final batch = _firestore.batch();

    // 1. Thêm bản ghi vào collection 'Blocked'
    final blockedRef = _firestore.collection(_blockedCollection).doc();
    batch.set(blockedRef, {
      'blockerId': blockerId,
      'blockedId': blockedId,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Cập nhật status trong collection 'Friend' (nếu là bạn) thành 'blocked'
    final friendQuery = await _firestore
        .collection(_friendCollection)
        .where('user1', whereIn: [blockerId, blockedId])
        .where('user2', whereIn: [blockerId, blockedId])
        .where('status', isEqualTo: 'accepted')
        .limit(1)
        .get();

    if (friendQuery.docs.isNotEmpty) {
      final friendDocId = friendQuery.docs.first.id;
      final friendRef = _firestore.collection(_friendCollection).doc(friendDocId);
      batch.update(friendRef, {'status': 'blocked'});
    }

    // 3. Xóa ID của nhau khỏi mảng 'friends' trong document 'User' (để ẩn khỏi UI)
    final blockerRef = _firestore.collection(_userCollection).doc(blockerId);
    batch.update(blockerRef, {'friends': FieldValue.arrayRemove([blockedId])});

    final blockedUserRef = _firestore.collection(_userCollection).doc(blockedId);
    batch.update(blockedUserRef, {'friends': FieldValue.arrayRemove([blockerId])});

    await batch.commit();
  }

  /// Bỏ chặn người dùng (Logic mới)
  Future<void> unblockUser(String blockerId, String blockedId) async {
    final batch = _firestore.batch();

    // 1. Cập nhật status trong collection 'Blocked' thành 'inactive'
    final blockedQuery = await _firestore
        .collection(_blockedCollection)
        .where('blockerId', isEqualTo: blockerId)
        .where('blockedId', isEqualTo: blockedId)
        .where('status', isEqualTo: 'active')
        .get();

    for (var doc in blockedQuery.docs) {
      batch.update(doc.reference, {
        'status': 'inactive',
        'unblockedAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. Khôi phục lại tình trạng bạn bè nếu trước đó họ là bạn
    final friendQuery = await _firestore
        .collection(_friendCollection)
        .where('user1', whereIn: [blockerId, blockedId])
        .where('user2', whereIn: [blockerId, blockedId])
        .where('status', isEqualTo: 'blocked')
        .limit(1)
        .get();

    if (friendQuery.docs.isNotEmpty) {
      final friendDocId = friendQuery.docs.first.id;
      final friendRef = _firestore.collection(_friendCollection).doc(friendDocId);
      batch.update(friendRef, {'status': 'accepted'});

      // Thêm lại ID của nhau vào mảng 'friends'
      final blockerRef = _firestore.collection(_userCollection).doc(blockerId);
      batch.update(blockerRef, {'friends': FieldValue.arrayUnion([blockedId])});

      final blockedUserRef = _firestore.collection(_userCollection).doc(blockedId);
      batch.update(blockedUserRef, {'friends': FieldValue.arrayUnion([blockerId])});
    }

    await batch.commit();
  }

  /// Lấy danh sách ID những người đang bị chặn
  Stream<List<String>> getBlockedUsers(String blockerId) {
    return _firestore
        .collection(_blockedCollection)
        .where('blockerId', isEqualTo: blockerId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()['blockedId'] as String).toList());
  }
}