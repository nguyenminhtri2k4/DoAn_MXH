import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/request/notification_request.dart';
import 'package:mangxahoi/request/user_request.dart';

class PostActivityRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRequest _userRequest = UserRequest();
  final NotificationRequest _notificationRequest = NotificationRequest();

  final String _postCollection = 'Post';
  final String _reactionSubcollection = 'reactions';
  final String _commentSubcollection = 'comments';

  // ==================== HÀM PHỤ TRỢ ====================

  /// Helper: Lấy thông tin User (Tên + Avatar)
  Future<Map<String, String>> _getUserInfo(String userId) async {
    try {
      final user = await _userRequest.getUserData(userId);
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

  /// Helper: Kiểm tra chặn & lấy info chủ bài
  Future<Map<String, dynamic>?> _getPostOwnerInfo(String postId, String actorId) async {
    try {
      final postDoc = await _firestore.collection(_postCollection).doc(postId).get();
      if (!postDoc.exists) return null;

      final ownerId = postDoc.data()?['authorId'];
      if (ownerId == null || ownerId == actorId) return null; // Tự tương tác -> bỏ qua

      // TODO: Kiểm tra chặn nếu cần
      // final isBlocked = await _checkBlocked(actorId, ownerId);
      // if (isBlocked) return null;

      return {'ownerId': ownerId, 'postId': postId};
    } catch (e) {
      print('⚠️ Lỗi lấy info chủ bài: $e');
      return null;
    }
  }

  // ==================== REACTION ====================

  /// Khi user reaction (like, love, haha...) bài viết
  Future<void> onReactionAdded({
    required String postId,
    required String userId,
    required String reactionType,
  }) async {
    try {
      print('📌 [PostActivity] onReactionAdded: $reactionType bởi $userId');

      // 1. Lấy info chủ bài
      final postInfo = await _getPostOwnerInfo(postId, userId);
      if (postInfo == null) {
        print('ℹ️ Không gửi thông báo (tự tương tác hoặc bài không tồn tại)');
        return;
      }

      final ownerId = postInfo['ownerId'] as String;

      // 2. Lấy info người reaction
      final actorInfo = await _getUserInfo(userId);
      final actorName = actorInfo['name']!;
      final actorAvatar = actorInfo['avatar']!;

      // 3. Tạo nội dung thông báo
      final emojiMap = {
        'like': 'thích',
        'love': 'yêu thích',
        'haha': 'haha',
        'wow': 'wow',
        'sad': 'buồn',
        'angry': 'tức giận',
      };
      final emotionText = emojiMap[reactionType] ?? 'thả cảm xúc';
      final content = '$actorName đã $emotionText bài viết của bạn.';

      // 4. Gửi thông báo qua NotificationRequest
      await _notificationRequest.sendNotification(
        fromUserId: userId,
        toUserId: ownerId,
        type: 'reaction',
        title: actorName,
        content: content,
        targetId: postId,
        targetType: 'post', // ✅ Quan trọng: để điều hướng đến PostDetailView
        fromUserName: actorName,
        fromUserAvatar: actorAvatar,
      );

      print('✅ Thông báo reaction đã gửi');
    } catch (e) {
      print('❌ Lỗi onReactionAdded: $e');
    }
  }

  /// Khi user bỏ reaction
  Future<void> onReactionRemoved({
    required String postId,
    required String userId,
  }) async {
    try {
      print('📌 [PostActivity] onReactionRemoved bởi $userId');
      // Không cần gửi thông báo khi bỏ reaction
    } catch (e) {
      print('❌ Lỗi onReactionRemoved: $e');
    }
  }

  // ==================== COMMENT ====================

  /// Khi user comment bài viết
  Future<void> onCommentAdded({
    required String postId,
    required String userId,
    required String commentText,
  }) async {
    try {
      print('📌 [PostActivity] onCommentAdded bởi $userId');

      // 1. Lấy info chủ bài
      final postInfo = await _getPostOwnerInfo(postId, userId);
      if (postInfo == null) {
        print('ℹ️ Không gửi thông báo (tự tương tác hoặc bài không tồn tại)');
        return;
      }

      final ownerId = postInfo['ownerId'] as String;

      // 2. Lấy info người comment
      final actorInfo = await _getUserInfo(userId);
      final actorName = actorInfo['name']!;
      final actorAvatar = actorInfo['avatar']!;

      // 3. Tạo nội dung thông báo
      final previewText = commentText.length > 50
          ? '${commentText.substring(0, 50)}...'
          : commentText;

      final content = '$actorName: "$previewText"';

      // 4. Gửi thông báo
      await _notificationRequest.sendNotification(
        fromUserId: userId,
        toUserId: ownerId,
        type: 'comment',
        title: 'Bình luận mới',
        content: content,
        targetId: postId,
        targetType: 'post', // ✅ Quan trọng: để điều hướng đến PostDetailView
        fromUserName: actorName,
        fromUserAvatar: actorAvatar,
      );

      print('✅ Thông báo comment đã gửi');
    } catch (e) {
      print('❌ Lỗi onCommentAdded: $e');
    }
  }

  /// Khi user reply comment (comment con)
  Future<void> onReplyAdded({
    required String postId,
    required String userId,
    required String parentCommentAuthorId,
    required String replyText,
  }) async {
    try {
      print('📌 [PostActivity] onReplyAdded bởi $userId');

      // Kiểm tra không tự reply
      if (userId == parentCommentAuthorId) {
        print('ℹ️ Không gửi thông báo (tự reply)');
        return;
      }

      // Lấy info người reply
      final actorInfo = await _getUserInfo(userId);
      final actorName = actorInfo['name']!;
      final actorAvatar = actorInfo['avatar']!;

      // Tạo nội dung thông báo
      final previewText = replyText.length > 50
          ? '${replyText.substring(0, 50)}...'
          : replyText;

      final content = '$actorName: "$previewText"';

      // Gửi thông báo cho tác giả comment cha
      await _notificationRequest.sendNotification(
        fromUserId: userId,
        toUserId: parentCommentAuthorId,
        type: 'reply',
        title: 'Trả lời mới',
        content: content,
        targetId: postId,
        targetType: 'post',
        fromUserName: actorName,
        fromUserAvatar: actorAvatar,
      );

      print('✅ Thông báo reply đã gửi');
    } catch (e) {
      print('❌ Lỗi onReplyAdded: $e');
    }
  }

  /// Khi user xóa comment
  Future<void> onCommentDeleted({
    required String postId,
  }) async {
    try {
      print('📌 [PostActivity] onCommentDeleted');
      // Không cần gửi thông báo khi xóa comment
    } catch (e) {
      print('❌ Lỗi onCommentDeleted: $e');
    }
  }
}