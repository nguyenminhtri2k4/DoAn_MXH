import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_friend_request.dart';
import 'package:mangxahoi/model/model_friend.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/request/notification_request.dart'; // 🔥 Import NotificationRequest

class FriendRequestManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRequest _userRequest = UserRequest();
  final NotificationRequest _notificationRequest = NotificationRequest(); // 🔥 Khởi tạo NotificationRequest
  
  final String _friendRequestCollection = 'FriendRequest';
  final String _userCollection = 'User';
  final String _friendCollection = 'Friend';
  final String _blockedCollection = 'Blocked';
  // Không cần _notificationCollection ở đây nữa vì NotificationRequest đã lo

  // ==================== HÀM PHỤ TRỢ ====================

  /// Helper: Lấy thông tin User đầy đủ (Tên + Avatar) để tạo thông báo
  Future<Map<String, String>> _getSenderInfo(String userId) async {
    try {
      final UserModel? user = await _userRequest.getUserData(userId);
      if (user != null) {
        final name = user.name.isNotEmpty ? user.name : 'Người dùng';
        final avatar = (user.avatar.isNotEmpty) ? user.avatar.first : '';
        return {'name': name, 'avatar': avatar};
      }
      return {'name': 'Người dùng', 'avatar': ''};
    } catch (e) {
      print('⚠️ Lỗi lấy info user: $e');
      return {'name': 'Người dùng', 'avatar': ''};
    }
  }

  // ==================== LOGIC KẾT BẠN ====================

  Future<void> sendRequest(String fromUserId, String toUserId) async {
    if (fromUserId == toUserId) return;

    // 1. Kiểm tra trạng thái
    final blockStatus = await checkBlockedStatus(fromUserId, toUserId);
    if (blockStatus['isBlocked'] == true) {
      if (blockStatus['blockedBy'] == toUserId) {
        throw Exception("Bạn không thể gửi lời mời do đã bị người này chặn.");
      } else {
        throw Exception("Bạn đã chặn người này. Hãy bỏ chặn để kết bạn.");
      }
    }

    final status = await getFriendshipStatus(fromUserId, toUserId);
    if (status == 'friends') throw Exception("Hai bạn đã là bạn bè.");
    if (status == 'pending_sent') throw Exception("Đã gửi lời mời, đang chờ chấp nhận.");
    if (status == 'pending_received') throw Exception("Người này đã gửi lời mời cho bạn. Hãy kiểm tra.");

    try {
      // 2. Tạo Request
      final requestRef = _firestore.collection(_friendRequestCollection).doc();
      final newRequest = FriendRequestModel(
        id: requestRef.id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      await requestRef.set(newRequest.toMap());

      // 3. Lấy info người gửi
      final senderInfo = await _getSenderInfo(fromUserId);
      final senderName = senderInfo['name']!;
      final senderAvatar = senderInfo['avatar']!;

      // 4. Gửi thông báo (Gọi qua NotificationRequest)
      await _notificationRequest.sendNotification(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: 'friend_request',
        title: 'Lời mời kết bạn',
        content: 'Lời mời kết bạn từ $senderName.',
        targetId: requestRef.id,
        targetType: 'request',
        fromUserName: senderName,
        fromUserAvatar: senderAvatar,
      );

    } catch (e) {
      throw Exception("Lỗi khi gửi lời mời: $e");
    }
  }

  Future<void> acceptRequest(FriendRequestModel request) async {
    final user1Id = request.fromUserId; 
    final user2Id = request.toUserId;
    final batch = _firestore.batch();

    // Update request status
    final requestRef = _firestore.collection(_friendRequestCollection).doc(request.id);
    batch.update(requestRef, {'status': 'accepted', 'updatedAt': FieldValue.serverTimestamp()});

    // Create friend relationship
    final newFriend = FriendModel(
      id: '', user1: user1Id, user2: user2Id, status: 'accepted', createdAt: DateTime.now(),
    );
    final friendRef = _firestore.collection(_friendCollection).doc();
    batch.set(friendRef, newFriend.toMap());

    // Update user friend lists
    final user1Ref = _firestore.collection(_userCollection).doc(user1Id);
    batch.update(user1Ref, {'friends': FieldValue.arrayUnion([user2Id])});

    final user2Ref = _firestore.collection(_userCollection).doc(user2Id);
    batch.update(user2Ref, {'friends': FieldValue.arrayUnion([user1Id])});

    await batch.commit();

    try {
      // Lấy info người chấp nhận
      final accepterInfo = await _getSenderInfo(user2Id);
      final accepterName = accepterInfo['name']!;
      final accepterAvatar = accepterInfo['avatar']!;

      // Gửi thông báo chấp nhận (Gọi qua NotificationRequest)
      await _notificationRequest.sendNotification(
        fromUserId: user2Id,
        toUserId: user1Id,
        type: 'accept_friend',
        title: 'Đã chấp nhận kết bạn',
        content: 'Lời mời kết bạn đã được chấp nhận bởi $accepterName.',
        targetId: user2Id,
        targetType: 'user',
        fromUserName: accepterName,
        fromUserAvatar: accepterAvatar,
      );
    } catch (e) {
      print("Lỗi tạo thông báo accept: $e");
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      final docSnapshot = await _firestore.collection(_friendRequestCollection).doc(requestId).get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final fromUserId = data?['fromUserId'];
        final toUserId = data?['toUserId'];

        await _firestore.collection(_friendRequestCollection).doc(requestId).delete();

        if (fromUserId != null && toUserId != null) {
          // Lấy info người từ chối
          final rejecterInfo = await _getSenderInfo(toUserId);
          final rejecterName = rejecterInfo['name']!;
          final rejecterAvatar = rejecterInfo['avatar']!;

          // Gửi thông báo từ chối (Gọi qua NotificationRequest)
          await _notificationRequest.sendNotification(
            fromUserId: toUserId,
            toUserId: fromUserId,
            type: 'reject_friend',
            title: 'Lời mời bị từ chối',
            content: 'Lời mời kết bạn bị từ chối bởi $rejecterName.',
            targetId: toUserId,
            targetType: 'user',
            fromUserName: rejecterName,
            fromUserAvatar: rejecterAvatar,
          );
        }
      }
    } catch (e) {
      print("Lỗi khi từ chối kết bạn: $e");
      throw Exception("Lỗi khi từ chối kết bạn");
    }
  }

  // ... (Các hàm khác giữ nguyên logic cũ) ...

  Future<void> cancelSentRequest(String requestId) async {
    await _firestore.collection(_friendRequestCollection).doc(requestId).delete();
  }

  Stream<List<FriendRequestModel>> getIncomingRequests(String userId) {
    return _firestore.collection(_friendRequestCollection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(50).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FriendRequestModel.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<FriendRequestModel>> getSentRequests(String userId) {
    return _firestore.collection(_friendRequestCollection)
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(50).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FriendRequestModel.fromMap(doc.id, doc.data())).toList());
  }

  Future<String> getFriendshipStatus(String userId1, String userId2) async {
    if (userId1 == userId2) return 'self';
    final blockedStatus = await checkBlockedStatus(userId1, userId2);
    if (blockedStatus['isBlocked'] == true) return 'blocked';
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

  Future<void> unfriend(String userId1, String userId2) async {
    final batch = _firestore.batch();
    final friendQuery = await _firestore.collection(_friendCollection).where('user1', whereIn: [userId1, userId2]).where('user2', whereIn: [userId1, userId2]).limit(1).get();
    if (friendQuery.docs.isNotEmpty) batch.delete(_firestore.collection(_friendCollection).doc(friendQuery.docs.first.id));
    batch.update(_firestore.collection(_userCollection).doc(userId1), {'friends': FieldValue.arrayRemove([userId2])});
    batch.update(_firestore.collection(_userCollection).doc(userId2), {'friends': FieldValue.arrayRemove([userId1])});
    await batch.commit();
  }

  Future<void> blockUser(String blockerId, String blockedId) async {
    final batch = _firestore.batch();
    final blockedRef = _firestore.collection(_blockedCollection).doc();
    batch.set(blockedRef, {'blockerId': blockerId, 'blockedId': blockedId, 'status': 'active', 'createdAt': FieldValue.serverTimestamp()});
    final friendQuery = await _firestore.collection(_friendCollection).where('user1', whereIn: [blockerId, blockedId]).where('user2', whereIn: [blockerId, blockedId]).limit(1).get();
    if (friendQuery.docs.isNotEmpty) batch.delete(_firestore.collection(_friendCollection).doc(friendQuery.docs.first.id));
    batch.update(_firestore.collection(_userCollection).doc(blockerId), {'friends': FieldValue.arrayRemove([blockedId])});
    batch.update(_firestore.collection(_userCollection).doc(blockedId), {'friends': FieldValue.arrayRemove([blockerId])});
    await batch.commit();
  }

  Future<void> unblockUser(String blockerId, String blockedId) async {
    final blockedQuery = await _firestore.collection(_blockedCollection).where('blockerId', isEqualTo: blockerId).where('blockedId', isEqualTo: blockedId).where('status', isEqualTo: 'active').get();
    final batch = _firestore.batch();
    for (var doc in blockedQuery.docs) batch.delete(doc.reference);
    await batch.commit();
  }

  Stream<List<String>> getBlockedUsers(String blockerId) {
    return _firestore.collection(_blockedCollection).where('blockerId', isEqualTo: blockerId).where('status', isEqualTo: 'active').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()['blockedId'] as String).toList());
  }

  Future<Map<String, dynamic>> checkBlockedStatus(String user1Id, String user2Id) async {
    try {
      final block1 = await _firestore.collection(_blockedCollection).where('blockerId', isEqualTo: user1Id).where('blockedId', isEqualTo: user2Id).where('status', isEqualTo: 'active').limit(1).get();
      if (block1.docs.isNotEmpty) return {'isBlocked': true, 'blockedBy': user1Id};
      final block2 = await _firestore.collection(_blockedCollection).where('blockerId', isEqualTo: user2Id).where('blockedId', isEqualTo: user1Id).where('status', isEqualTo: 'active').limit(1).get();
      if (block2.docs.isNotEmpty) return {'isBlocked': true, 'blockedBy': user2Id};
      return {'isBlocked': false, 'blockedBy': null};
    } catch (e) {
      print('❌ Lỗi kiểm tra chặn: $e');
      return {'isBlocked': false, 'blockedBy': null};
    }
  }

  Future<bool> isUserBlocked(String currentUserId, String targetUserId) async {
    try {
      final blockDoc = await _firestore.collection(_blockedCollection).where('blockerId', isEqualTo: currentUserId).where('blockedId', isEqualTo: targetUserId).where('status', isEqualTo: 'active').limit(1).get();
      return blockDoc.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}