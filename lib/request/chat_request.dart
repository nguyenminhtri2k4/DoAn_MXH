import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_chat.dart';
import 'package:mangxahoi/model/model_qr_invite.dart';

class ChatRequest {
  static const String _chatCollection = 'Chat';
  static const String _messagesSubCollection = 'messages';
  static const int _maxTimeDiffSeconds = 2;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy stream tin nhắn của một cuộc trò chuyện
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection(_messagesSubCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapMessageSnapshot);
  }

  /// Gửi tin nhắn và cập nhật lastMessage
  Future<void> sendMessage(String chatId, MessageModel message) async {
    final messageMap = message.toMap();
    messageMap['createdAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection(_messagesSubCollection)
        .add(messageMap);

    final lastMessagePreview = _buildMessagePreview(message);

    await _firestore.collection(_chatCollection).doc(chatId).update({
      'lastMessage': lastMessagePreview,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tạo hoặc lấy thông tin phòng chat của nhóm
  Future<String> getOrCreateGroupChat(
    String groupId,
    List<String> memberIds,
  ) async {
    final chatDoc = _firestore.collection(_chatCollection).doc(groupId);
    final docSnapshot = await chatDoc.get();

    if (!docSnapshot.exists) {
      final newChat = ChatModel(
        id: groupId,
        lastMessage: 'Đã tạo nhóm',
        members: memberIds,
        type: 'group',
        updatedAt: DateTime.now(),
      );
      await chatDoc.set(newChat.toMap());
    }
    return groupId;
  }

  /// Lấy hoặc tạo phòng chat 1-1 giữa hai người dùng
  Future<String> getOrCreatePrivateChat(String user1Id, String user2Id) async {
    final ids = [user1Id, user2Id]..sort();
    final chatId = ids.join('_');

    final chatDoc = _firestore.collection(_chatCollection).doc(chatId);
    final docSnapshot = await chatDoc.get();

    if (!docSnapshot.exists) {
      final newChat = ChatModel(
        id: chatId,
        lastMessage: '',
        members: [user1Id, user2Id],
        type: 'private',
        updatedAt: DateTime.now(),
      );
      await chatDoc.set(newChat.toMap());
    }
    return chatId;
  }

  /// Lấy danh sách chat của người dùng
  Stream<List<ChatModel>> getChatsForUser(String userId) {
    return _firestore
        .collection(_chatCollection)
        .where('members', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(_mapChatSnapshot);
  }

  /// Thu hồi tin nhắn và cập nhật lastMessage nếu cần
  Future<void> recallMessage(String chatId, String messageId) async {
    try {
      final messageRef = _getMessageRef(chatId, messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) return;

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final messageTimestamp = (messageData['createdAt'] as Timestamp).toDate();

      await messageRef.update({
        'status': 'recalled',
        'content': '',
        'mediaIds': [],
      });

      await _updateLastMessageIfNeeded(chatId, messageTimestamp);
    } catch (e) {
      _logError('Thu hồi tin nhắn', e);
      rethrow;
    }
  }

  /// Xóa tin nhắn và cập nhật lastMessage nếu cần
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final messageRef = _getMessageRef(chatId, messageId);
      final messageDoc = await messageRef.get();

      if (!messageDoc.exists) return;

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final messageTimestamp = (messageData['createdAt'] as Timestamp).toDate();

      await messageRef.update({'status': 'deleted'});

      await _updateLastMessageIfNeeded(chatId, messageTimestamp);
    } catch (e) {
      _logError('Xóa tin nhắn', e);
      rethrow;
    }
  }

  /// Cập nhật trạng thái của tin nhắn
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    String status,
  ) async {
    await _getMessageRef(chatId, messageId).update({'status': status});
  }

  // ============ PRIVATE METHODS ============

  /// Map snapshot sang danh sách MessageModel
  List<MessageModel> _mapMessageSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Map snapshot sang danh sách ChatModel
  List<ChatModel> _mapChatSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs
        .map((doc) => ChatModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Xây dựng preview của tin nhắn
  String _buildMessagePreview(MessageModel message) {
    if (message.type == 'share_post') {
      return 'Đã chia sẻ một bài viết';
    }

    if (message.type == 'location') {
      return '📍 Đã chia sẻ vị trí';
    }

    if (message.type == 'share_group_qr') {
      return _buildQRPreview(message.content);
    }

    if (message.type == 'call_audio' || message.type == 'call_video') {
      return _buildCallPreview(message.type, message.content);
    }

    if (message.mediaIds.isNotEmpty) {
      return _buildMediaPreview(message.content, message.mediaIds.length);
    }

    return message.content.isNotEmpty
        ? message.content
        : 'Tin nhắn không có nội dung';
  }

  /// Xây dựng preview cho QR mời tham gia nhóm
  String _buildQRPreview(String content) {
    try {
      final qrData = QRInviteData.fromQRString(content);
      return 'Lời mời tham gia nhóm ${qrData.groupName}';
    } catch (e) {
      return 'Đã gửi lời mời nhóm';
    }
  }

  /// Xây dựng preview cho cuộc gọi
  String _buildCallPreview(String callType, String content) {
    if (content == 'missed') return 'Cuộc gọi nhỡ';
    if (content == 'declined') return 'Cuộc gọi đã bị từ chối';

    if (content.startsWith('completed_')) {
      final duration = content.split('_').last;
      final callTypeName = callType == 'call_audio' ? 'Cuộc gọi thoại' : 'Cuộc gọi video';
      return '$callTypeName • $duration';
    }

    return callType == 'call_audio' ? 'Cuộc gọi thoại' : 'Cuộc gọi video';
  }

  /// Xây dựng preview cho media
  String _buildMediaPreview(String content, int mediaCount) {
    if (content.isNotEmpty) {
      return '$content 📷';
    }
    return mediaCount > 1 ? '$mediaCount ảnh/video' : '1 ảnh/video';
  }

  /// Kiểm tra và cập nhật lastMessage nếu tin nhắn là gần nhất
  Future<void> _updateLastMessageIfNeeded(
    String chatId,
    DateTime messageTimestamp,
  ) async {
    final chatDoc = await _firestore.collection(_chatCollection).doc(chatId).get();

    if (!chatDoc.exists) return;

    final chatData = chatDoc.data() as Map<String, dynamic>;
    final lastMessageTime = (chatData['updatedAt'] as Timestamp).toDate();

    final timeDiff = messageTimestamp.difference(lastMessageTime).abs().inSeconds;
    final isLastMessage = messageTimestamp.isAtSameMomentAs(lastMessageTime) ||
        timeDiff <= _maxTimeDiffSeconds;

    if (isLastMessage) {
      await _updateLastMessage(chatId);
    }
  }

  /// Cập nhật lastMessage dựa trên tin nhắn gần nhất không bị xóa
  Future<void> _updateLastMessage(String chatId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection(_chatCollection)
          .doc(chatId)
          .collection(_messagesSubCollection)
          .where('status', whereNotIn: ['recalled', 'deleted'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      String newLastMessage = 'Không có tin nhắn';
      DateTime newUpdatedAt = DateTime.now();

      if (messagesSnapshot.docs.isNotEmpty) {
        final latestMessageDoc = messagesSnapshot.docs.first;
        final latestMessage = latestMessageDoc.data();
        final messageModel = MessageModel.fromMap(
          latestMessage,
          latestMessageDoc.id,
        );

        newLastMessage = _buildMessagePreview(messageModel);
        newUpdatedAt = messageModel.createdAt;
      }

      await _firestore.collection(_chatCollection).doc(chatId).update({
        'lastMessage': newLastMessage,
        'updatedAt': Timestamp.fromDate(newUpdatedAt),
      });

      _logSuccess('Cập nhật lastMessage cho chat $chatId: $newLastMessage');
    } catch (e) {
      _logError('Cập nhật lastMessage', e);
    }
  }

  /// Lấy reference đến tin nhắn
  DocumentReference _getMessageRef(String chatId, String messageId) {
    return _firestore
        .collection(_chatCollection)
        .doc(chatId)
        .collection(_messagesSubCollection)
        .doc(messageId);
  }

  /// Log error
  void _logError(String operation, Object error) {
    print('❌ Lỗi khi $operation: $error');
  }

  /// Log success
  void _logSuccess(String message) {
    print('✅ $message');
  }
}