
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_story.dart';
import 'package:mangxahoi/model/model_audio.dart';
import 'package:mangxahoi/model/model_story_view.dart';

class StoryRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Story';

  /// Tạo một Story mới
  Future<void> createStory({
    required String authorId,
    String mediaUrl = '',
    String mediaType = 'image',
    String content = '',
    String backgroundColor = '',
    AudioModel? audio, // Nhận cả AudioModel để lấy thông tin âm thanh
  }) async {
    try {
      final newStory = StoryModel(
        id: '',
        authorId: authorId,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        content: content,
        backgroundColor: backgroundColor,
        createdAt: DateTime.now(),
        views: [],
        // Thêm dữ liệu audio từ AudioModel
        audioId: audio?.id,
        audioUrl: audio?.url,
        audioName: audio?.name,
        audioCoverUrl: audio?.coverImageUrl,
      );

      await _firestore.collection(_collectionName).add(newStory.toMap());
    } catch (e) {
      print('Lỗi khi tạo Story: $e');
      rethrow;
    }
  }

  /// Ghi nhận lượt xem story vào subcollection 'views' và mảng 'views' ở document gốc
  Future<void> markStoryAsViewed(String storyId, String viewerId) async {
    try {
      final viewRef = _firestore
          .collection(_collectionName)
          .doc(storyId)
          .collection('views')
          .doc(viewerId);

      final doc = await viewRef.get();
      if (!doc.exists) {
        // Chỉ tạo mới nếu chưa xem, tránh ghi đè viewedAt của lần xem đầu tiên
        await viewRef.set({
          'viewerId': viewerId,
          'reactionType': '', // Ban đầu chưa có reaction
          'viewedAt': FieldValue.serverTimestamp(),
        });
        
        // Cập nhật mảng views ở document gốc để đếm nhanh số lượng người xem
        await _firestore.collection(_collectionName).doc(storyId).update({
          'views': FieldValue.arrayUnion([viewerId])
        });
      }
    } catch (e) {
      print('Lỗi markStoryAsViewed: $e');
    }
  }

  /// Thả hoặc cập nhật reaction cho một story cụ thể
  Future<void> reactToStory(String storyId, String viewerId, String reactionType) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(storyId)
          .collection('views')
          .doc(viewerId)
          .update({
        'reactionType': reactionType,
        'viewedAt': FieldValue.serverTimestamp(), // Cập nhật thời gian tương tác mới nhất
      });
    } catch (e) {
      print('Lỗi reactToStory: $e');
    }
  }

  /// Lấy danh sách người xem story kèm reaction (Real-time) sử dụng StoryViewModel
  Stream<List<StoryViewModel>> getStoryViewers(String storyId) {
    return _firestore
        .collection(_collectionName)
        .doc(storyId)
        .collection('views')
        .orderBy('viewedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryViewModel.fromMap(doc.data()))
            .toList());
  }

  /// Lấy Story của bản thân và bạn bè trong vòng 24 giờ qua
  Stream<List<StoryModel>> getStoriesForUser(String currentUserId) async* {
    try {
      // Bước 1: Lấy danh sách bạn bè đã chấp nhận (status: accepted) từ collection Friends
      final friendsQuery1 = await _firestore
          .collection('Friends')
          .where('user1', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final friendsQuery2 = await _firestore
          .collection('Friends')
          .where('user2', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final Set<String> friendIds = {};
      
      for (var doc in friendsQuery1.docs) {
        friendIds.add(doc.data()['user2']);
      }
      
      for (var doc in friendsQuery2.docs) {
        friendIds.add(doc.data()['user1']);
      }

      // Thêm chính mình vào danh sách để xem story cá nhân
      friendIds.add(currentUserId);

      if (friendIds.isEmpty) {
        yield [];
        return;
      }

      // Bước 2: Lấy story của danh sách friendIds trong 24h qua
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      final List<String> friendIdsList = friendIds.toList();
      final List<StoryModel> allStories = [];

      // Firestore giới hạn whereIn tối đa 10 items, nên xử lý theo từng batch
      for (int i = 0; i < friendIdsList.length; i += 10) {
        final batch = friendIdsList.skip(i).take(10).toList();

        final snapshot = await _firestore
            .collection(_collectionName)
            .where('authorId', whereIn: batch)
            .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffTime))
            .orderBy('createdAt', descending: true)
            .get();

        allStories.addAll(
          snapshot.docs.map((doc) => StoryModel.fromFirestore(doc))
        );
      }

      // Sắp xếp lại toàn bộ kết quả theo thời gian mới nhất
      allStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield allStories;

      // Bước 3: Lắng nghe thay đổi real-time (tối ưu cho 10 người đầu tiên)
      if (friendIdsList.length <= 10) {
        yield* _firestore
            .collection(_collectionName)
            .where('authorId', whereIn: friendIdsList)
            .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffTime))
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => StoryModel.fromFirestore(doc))
                .toList());
      }
    } catch (e) {
      print('Lỗi khi lấy story bạn bè: $e');
      yield [];
    }
  }

  /// Xóa một story
  Future<void> deleteStory(String storyId) async {
    try {
      await _firestore.collection(_collectionName).doc(storyId).delete();
    } catch (e) {
      print('Lỗi khi xóa story: $e');
      rethrow;
    }
  }
}