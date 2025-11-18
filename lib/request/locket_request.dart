
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/storage_request.dart';
import 'package:mangxahoi/request/user_request.dart'; 

class LocketRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageRequest _storageRequest = StorageRequest();
  final UserRequest _userRequest = UserRequest();
  final String _userCollection = 'User'; 
  final String _locketCollection = 'locket_photos';

  Future<void> addLocketFriend(String currentUserId, String friendId) async {
    try {
      await _firestore.collection(_userCollection).doc(currentUserId).update({
        'locketFriends': FieldValue.arrayUnion([friendId])
      });
    } catch (e) {
      print("Error adding locket friend: $e");
    }
  }

  Future<void> removeLocketFriend(String currentUserId, String friendId) async {
    try {
      await _firestore.collection(_userCollection).doc(currentUserId).update({
        'locketFriends': FieldValue.arrayRemove([friendId])
      });
    } catch (e) {
      print("Error removing locket friend: $e");
    }
  }

  Future<void> uploadLocketPhoto(XFile image, String userId) async {
    try {
      String imageUrl = await _storageRequest.uploadLocketImage(image, userId);
      LocketPhoto newPhoto = LocketPhoto(
        id: '',
        userId: userId,
        imageUrl: imageUrl,
        timestamp: Timestamp.now(),
        // Đảm bảo model_locket_photo.dart của bạn có 2 trường này
        status: 'active', 
        deletedAt: null,
      );
      await _firestore.collection(_locketCollection).add(newPhoto.toMap());
    } catch (e) {
      print("Error uploading locket photo: $e");
    }
  }

  Future<List<UserModel>> getLocketFriendsDetails(String currentUserId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection(_userCollection).doc(currentUserId).get();
      if (!userDoc.exists) return [];

      UserModel currentUser = UserModel.fromFirestore(userDoc);
      List<String> friendIds = currentUser.locketFriends;
      if (friendIds.isEmpty) return [];

      List<Future<UserModel?>> futures = friendIds.map((id) => _userRequest.getUserData(id)).toList();
      final List<UserModel?> results = await Future.wait(futures);
      
      return results.whereType<UserModel>().toList();
    } catch (e) {
      print("Error getting locket friends details: $e");
      return [];
    }
  }

  Future<Map<String, LocketPhoto>> getLatestLocketPhotos(List<String> friendIds) async {
    if (friendIds.isEmpty) return {};

    try {
      List<Future<MapEntry<String, LocketPhoto>?>> futures = friendIds.map((id) async {
        try {
          QuerySnapshot photoSnap = await _firestore
              .collection(_locketCollection)
              .where('userId', isEqualTo: id)
              .where('status', isEqualTo: 'active') // CHỈ LẤY ẢNH ACTIVE
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (photoSnap.docs.isNotEmpty) {
            return MapEntry(id, LocketPhoto.fromFirestore(photoSnap.docs.first));
          }
          return null;
        } catch (e) {
          print("Error fetching latest photo for user $id: $e");
          return null;
        }
      }).toList();

      final List<MapEntry<String, LocketPhoto>?> results = await Future.wait(futures);
      return Map.fromEntries(results.whereType<MapEntry<String, LocketPhoto>>());
    } catch (e) {
      print("Error getting latest locket photos: $e");
      return {};
    }
  }

  // HÀM LẤY LỊCH SỬ LOCKET (dùng cho cả MyLocketHistoryView và LocketViewerView)
  Future<List<LocketPhoto>> getMyLocketHistory(String userId) async {
    try {
      QuerySnapshot photoSnap = await _firestore
          .collection(_locketCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active') // CHỈ LẤY ẢNH ACTIVE
          .orderBy('timestamp', descending: true)
          .get();

      if (photoSnap.docs.isEmpty) return [];
      
      return photoSnap.docs.map((doc) => LocketPhoto.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error getting my locket history: $e");
      return [];
    }
  }

  // === CÁC HÀM XÓA VÀ THÙNG RÁC (ĐÃ THÊM LẠI) ===

  // 1. Xóa mềm (dùng ở HistoryView và ViewerView)
  Future<void> deleteLocketPhotoSoft(String photoId) async {
    try {
      await _firestore.collection(_locketCollection).doc(photoId).update({
        'status': 'deleted',
        'deletedAt': Timestamp.now(),
      });
    } catch (e) {
      print("Error soft deleting locket photo: $e");
      rethrow;
    }
  }

  // 2. Lấy ảnh đã xóa (dùng ở TrashView)
  Stream<List<LocketPhoto>> getDeletedLocketPhotos(String userId) {
    try {
      return _firestore
          .collection(_locketCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'deleted')
          .orderBy('deletedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return [];
            }
            return snapshot.docs.map((doc) => LocketPhoto.fromFirestore(doc)).toList();
          });
    } catch (e) {
      print("Error getting deleted locket photos stream: $e");
      return Stream.value([]);
    }
  }

  // 3. Khôi phục (dùng ở TrashView)
  Future<void> restoreLocketPhoto(String photoId) async {
    try {
      await _firestore.collection(_locketCollection).doc(photoId).update({
        'status': 'active',
        'deletedAt': null, // Xóa dấu thời gian đã xóa
      });
    } catch (e) {
      print("Error restoring locket photo: $e");
      rethrow;
    }
  }

  // 4. Xóa vĩnh viễn (dùng ở TrashView)
  Future<void> deleteLocketPhotoPermanently(String photoId, String imageUrl) async {
    try {
      // 1. Xóa ảnh khỏi Storage
      await _storageRequest.deleteImage(imageUrl);
      
      // 2. Xóa tài liệu khỏi Firestore
      await _firestore.collection(_locketCollection).doc(photoId).delete();
    } catch (e) {
      print("Error permanently deleting locket photo: $e");
      rethrow;
    }
  }
}