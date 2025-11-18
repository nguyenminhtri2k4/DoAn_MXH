import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_story.dart';
import 'package:mangxahoi/model/model_audio.dart';

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
    AudioModel? audio, // Nhận cả AudioModel cho tiện
  }) async {
    try {
      final newStory = StoryModel(
        id: '',
        authorId: authorId,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        content: content,
        backgroundColor: backgroundColor,
        createdAt: DateTime.now(), // Sẽ được ghi đè bởi serverTimestamp
        views: [],
        // Thêm dữ liệu audio
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

  /// Lấy tất cả story của 1 user
  // Sửa lại hàm getStoriesForUser để lấy story của bạn bè trong 24h

Stream<List<StoryModel>> getStoriesForUser(String currentUserId) async* {
  try {
    // Bước 1: Lấy danh sách bạn bè từ collection Friends
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

    // Lấy danh sách ID bạn bè
    final Set<String> friendIds = {};
    
    for (var doc in friendsQuery1.docs) {
      friendIds.add(doc.data()['user2']);
    }
    
    for (var doc in friendsQuery2.docs) {
      friendIds.add(doc.data()['user1']);
    }

    // Thêm chính mình vào để xem story của bản thân
    friendIds.add(currentUserId);

    if (friendIds.isEmpty) {
      yield [];
      return;
    }

    // Bước 2: Lấy story của bạn bè trong 24h
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    final List<String> friendIdsList = friendIds.toList();

    // Firestore giới hạn whereIn tối đa 10 items, nên chia batch
    final List<StoryModel> allStories = [];

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

    // Sắp xếp lại theo thời gian
    allStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield allStories;

    // Bước 3: Lắng nghe real-time (chỉ cho 10 người đầu tiên)
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
  
  // (Bạn có thể thêm các hàm getStories, deleteStory, ... sau)
}