import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_follow.dart';
// Import để kiểm tra chặn từ FriendRequestManager nếu cần
import 'package:mangxahoi/request/friend_request_manager.dart';

class FollowRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'Follow';
  final String _userCollection = 'User';
  final FriendRequestManager _friendRequestManager = FriendRequestManager();

  /// Theo dõi một người dùng
  Future<void> followUser(String currentUserId, String targetUserId) async {
    // 1. Kiểm tra xem có bị chặn không trước khi cho phép follow
    final blockStatus = await _friendRequestManager.checkBlockedStatus(currentUserId, targetUserId);
    if (blockStatus['isBlocked'] == true) {
      if (blockStatus['blockedBy'] == targetUserId) {
        throw Exception("Bạn không thể theo dõi người này do đã bị chặn.");
      } else {
        throw Exception("Bạn đã chặn người này. Hãy bỏ chặn để theo dõi.");
      }
    }

    final follow = FollowModel(
      followerId: currentUserId,
      followingId: targetUserId,
      createdAt: DateTime.now(),
      status: 'active', // Đặt trạng thái là active
    );

    final batch = _firestore.batch();

    // 2. Thêm/Cập nhật vào collection Follow
    final followDoc = _firestore.collection(_collection).doc('${currentUserId}_$targetUserId');
    batch.set(followDoc, follow.toMap());

    // 3. Tăng followerCount
    final targetUserRef = _firestore.collection(_userCollection).doc(targetUserId);
    batch.update(targetUserRef, {'followerCount': FieldValue.increment(1)});

    // 4. Tăng followingCount
    final currentUserRef = _firestore.collection(_userCollection).doc(currentUserId);
    batch.update(currentUserRef, {'followingCount': FieldValue.increment(1)});

    await batch.commit();
  }

  /// Hủy theo dõi (Xóa hẳn bản ghi hoặc chuyển status thành 'inactive' tuỳ bạn. Ở đây tôi xóa hẳn để đơn giản hoá việc đếm)
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final followDocRef = _firestore.collection(_collection).doc('${currentUserId}_$targetUserId');
    final docSnapshot = await followDocRef.get();

    if (!docSnapshot.exists) return; // Nếu chưa follow thì bỏ qua

    // Nếu muốn giữ history thì update status = 'inactive' thay vì delete,
    // nhưng cần xử lý logic đếm follower cẩn thận hơn.
    // Ở đây tôi giữ nguyên logic xóa để đồng bộ với việc tăng/giảm count.
    final batch = _firestore.batch();
    batch.delete(followDocRef);

    final targetUserRef = _firestore.collection(_userCollection).doc(targetUserId);
    batch.update(targetUserRef, {'followerCount': FieldValue.increment(-1)});

    final currentUserRef = _firestore.collection(_userCollection).doc(currentUserId);
    batch.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});

    await batch.commit();
  }

  /// Kiểm tra xem currentUserId có đang theo dõi targetUserId không (chỉ tính 'active')
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final doc = await _firestore.collection(_collection).doc('${currentUserId}_$targetUserId').get();
    return doc.exists && doc.data()?['status'] == 'active';
  }

  /// Lấy Stream danh sách ID những người đang theo dõi userId (chỉ lấy 'active')
  Stream<List<String>> getFollowers(String userId) {
    return _firestore
        .collection(_collection)
        .where('followingId', isEqualTo: userId)
        .where('status', isEqualTo: 'active') // Chỉ lấy active
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc['followerId'] as String).toList());
  }

  /// Lấy Stream danh sách ID những người mà userId đang theo dõi (chỉ lấy 'active')
  Stream<List<String>> getFollowing(String userId) {
    return _firestore
        .collection(_collection)
        .where('followerId', isEqualTo: userId)
        .where('status', isEqualTo: 'active') // Chỉ lấy active
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc['followingId'] as String).toList());
  }
}