import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_friend_request.dart';
import 'package:mangxahoi/model/model_friend.dart'; // <<< ĐÃ THÊM IMPORT NÀY
import 'package:mangxahoi/model/model_user.dart';

class FriendRequestManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Khai báo các tên collection
  final String _friendRequestCollection = 'FriendRequest';
  final String _userCollection = 'User';
  final String _friendCollection = 'Friend'; // <<< COLLECTION MỚI ĐÃ KHAI BÁO

  // ==================== A. LOGIC GỬI VÀ HỦY ====================

  /// Gửi lời mời kết bạn.
  Future<bool> sendRequest(String fromUserId, String toUserId) async {
    if (fromUserId == toUserId) return false;

    // 1. Kiểm tra trạng thái hiện tại
    final status = await getFriendshipStatus(fromUserId, toUserId);
    if (status != 'none') {
      return false; // Đã là bạn bè hoặc đã gửi/nhận lời mời
    }

    // 2. Tạo lời mời mới
    final newRequest = FriendRequestModel(
      id: '', // Firestore sẽ tự tạo
      fromUserId: fromUserId,
      toUserId: toUserId,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    try {
      await _firestore.collection(_friendRequestCollection).add(newRequest.toMap());
      print('✅ Gửi lời mời thành công từ $fromUserId đến $toUserId');
      return true;
    } catch (e) {
      print('❌ Lỗi khi gửi lời mời: $e');
      rethrow;
    }
  }

  /// Hủy lời mời đã gửi (sender cancels)
  Future<void> cancelSentRequest(String requestId) async {
    try {
      // Xóa request khỏi collection
      await _firestore.collection(_friendRequestCollection).doc(requestId).delete();
      print('✅ Hủy lời mời thành công: $requestId');
    } catch (e) {
      print('❌ Lỗi khi hủy lời mời: $e');
      rethrow;
    }
  }
  
  // ==================== B. LOGIC LẮNG NGHE VÀ XỬ LÝ ====================

  /// Lắng nghe danh sách lời mời ĐẾN user hiện tại
  Stream<List<FriendRequestModel>> getIncomingRequests(String userId) {
    return _firestore
        .collection(_friendRequestCollection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FriendRequestModel.fromMap(doc.id, doc.data())).toList());
  }

  /// Lắng nghe danh sách lời mời ĐÃ GỬI bởi user hiện tại
  Stream<List<FriendRequestModel>> getSentRequests(String userId) {
    return _firestore
        .collection(_friendRequestCollection)
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FriendRequestModel.fromMap(doc.id, doc.data())).toList());
  }


  /// Chấp nhận lời mời kết bạn (ĐÃ FIX: Cập nhật status request và tạo Friend)
  Future<void> acceptRequest(FriendRequestModel request) async {
    final user1Id = request.fromUserId; // Người gửi
    final user2Id = request.toUserId; // Người chấp nhận
    
    // 1. Chuẩn bị Batch Write để thực hiện nhiều thao tác cùng lúc
    final batch = _firestore.batch();
    
    // 2. Cập nhật trạng thái lời mời thành 'accepted' (KHÔNG xóa)
    final requestRef = _firestore.collection(_friendRequestCollection).doc(request.id);
    batch.update(requestRef, {
      'status': 'accepted', 
      'updatedAt': FieldValue.serverTimestamp()
    });
    
    // 3. Thêm bản ghi Friend mới vào collection 'Friend'
    final newFriend = FriendModel(
      id: '', 
      user1: user1Id,
      user2: user2Id,
      status: 'accepted',
      createdAt: DateTime.now(),
    );
    final friendRef = _firestore.collection(_friendCollection).doc(); 
    batch.set(friendRef, newFriend.toMap());

    // 4. Cập nhật mảng 'friends' và 'followingCount' của cả hai User
    
    // Cập nhật User1 (Người gửi)
    final user1Ref = _firestore.collection(_userCollection).doc(user1Id);
    batch.update(user1Ref, {
      'friends': FieldValue.arrayUnion([user2Id]),
      'followingCount': FieldValue.increment(1), 
    });

    // Cập nhật User2 (Người chấp nhận)
    final user2Ref = _firestore.collection(_userCollection).doc(user2Id);
    batch.update(user2Ref, {
      'friends': FieldValue.arrayUnion([user1Id]),
      'followingCount': FieldValue.increment(1), 
    });

    try {
      await batch.commit();
      print('✅ Chấp nhận lời mời thành công, Request updated và Friend created');
    } catch (e) {
      print('❌ Lỗi khi chấp nhận lời mời và cập nhật bạn bè: $e');
      rethrow;
    }
  }

  /// Từ chối lời mời kết bạn (vẫn dùng xóa request để loại bỏ nhanh khỏi danh sách)
  Future<void> rejectRequest(String requestId) async {
    try {
      // Ở đây ta dùng delete để nhanh chóng xóa khỏi danh sách Stream.
      await _firestore.collection(_friendRequestCollection).doc(requestId).delete();
      print('✅ Từ chối/Xóa lời mời thành công: $requestId');
    } catch (e) {
      print('❌ Lỗi khi từ chối lời mời: $e');
      rethrow;
    }
  }

  // ==================== C. HÀM KIỂM TRA TRẠNG THÁI (CHO SEARCH VIEW) ====================
  
  /// Kiểm tra mối quan hệ giữa hai user
  /// Trả về: 'self', 'friends', 'pending_sent', 'pending_received', 'none'
  Future<String> getFriendshipStatus(String userId1, String userId2) async {
    if (userId1 == userId2) return 'self';
    
    // 1. Kiểm tra đã là bạn bè chưa
    final user1Doc = await _firestore.collection(_userCollection).doc(userId1).get();
    if (!user1Doc.exists) return 'none';
    
    final userModel = UserModel.fromFirestore(user1Doc);
    if (userModel.friends.contains(userId2)) return 'friends';

    // 2. Kiểm tra lời mời đã gửi (từ userId1 đến userId2)
    final sentQuery = await _firestore
        .collection(_friendRequestCollection)
        .where('fromUserId', isEqualTo: userId1)
        .where('toUserId', isEqualTo: userId2)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (sentQuery.docs.isNotEmpty) return 'pending_sent';

    // 3. Kiểm tra lời mời nhận (từ userId2 đến userId1)
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
}