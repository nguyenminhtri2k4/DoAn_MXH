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
      );
      await _firestore.collection(_locketCollection).add(newPhoto.toMap());
    } catch (e) {
      print("Error uploading locket photo: $e");
    }
  }

  // *** HÀM ĐÃ ĐƯỢC TỐI ƯU (load song song) ***
  Future<List<UserModel>> getLocketFriendsDetails(String currentUserId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection(_userCollection).doc(currentUserId).get();
      if (!userDoc.exists) {
        print("LocketRequest: Không tìm thấy user $currentUserId");
        return [];
      }

      UserModel currentUser = UserModel.fromFirestore(userDoc);
      List<String> friendIds = currentUser.locketFriends;

      if (friendIds.isEmpty) {
        print("LocketRequest: Không có locket friends.");
        return [];
      }

      // Tạo danh sách các Future để gọi song song
      List<Future<UserModel?>> futures = friendIds.map((id) {
        // Giả sử UserRequest có hàm getUserData(docId)
        return _userRequest.getUserData(id); 
      }).toList();

      final List<UserModel?> results = await Future.wait(futures);
      final List<UserModel> friendsDetails = results.whereType<UserModel>().toList();
      print("LocketRequest: Tải xong chi tiết ${friendsDetails.length} locket friends.");
      return friendsDetails;

    } catch (e) {
      print("Error getting locket friends details (optimized): $e");
      return [];
    }
  }

  // *** HÀM ĐÃ ĐƯỢC TỐI ƯU (load song song) ***
  Future<Map<String, LocketPhoto>> getLatestLocketPhotos(List<String> friendIds) async {
    if (friendIds.isEmpty) return {};

    try {
      List<Future<MapEntry<String, LocketPhoto>?>> futures = friendIds.map((id) async {
        try {
          QuerySnapshot photoSnap = await _firestore
              .collection(_locketCollection)
              .where('userId', isEqualTo: id)
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
      final Map<String, LocketPhoto> latestPhotos = Map.fromEntries(
        results.whereType<MapEntry<String, LocketPhoto>>()
      );
      
      print("LocketRequest: Tải xong ${latestPhotos.length} ảnh mới nhất.");
      return latestPhotos;

    } catch (e) {
      print("Error getting latest locket photos (optimized): $e");
      return {};
    }
  }

  // HÀM LẤY LỊCH SỬ LOCKET CỦA BẢN THÂN
  Future<List<LocketPhoto>> getMyLocketHistory(String userId) async {
    try {
      QuerySnapshot photoSnap = await _firestore
          .collection(_locketCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      if (photoSnap.docs.isEmpty) {
        return [];
      }
      
      return photoSnap.docs.map((doc) => LocketPhoto.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error getting my locket history: $e");
      return [];
    }
  }
}