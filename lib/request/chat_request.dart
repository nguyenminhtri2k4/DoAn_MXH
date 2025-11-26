
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_chat.dart';
import 'package:mangxahoi/model/model_qr_invite.dart';

class ChatRequest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy stream tin nhắn của một cuộc trò chuyện
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('Chat')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    // Use server timestamp for createdAt to avoid relying on client device clocks
    final messageMap = message.toMap();
    // Override any client-side createdAt with server timestamp
    messageMap['createdAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('Chat')
        .doc(chatId)
        .collection('messages')
        .add(messageMap);

    // Tạo preview cho lastMessage
    String lastMessagePreview;

    if (message.type == 'share_post') {
      lastMessagePreview = 'Đã chia sẻ một bài viết';
    }
    else if (message.type == 'location') {
      lastMessagePreview = '📍 Đã chia sẻ vị trí';
    }
    // === THÊM LOGIC MỚI ===
    else if (message.type == 'share_group_qr') {
      try {
        final qrData = QRInviteData.fromQRString(message.content);
        lastMessagePreview = 'Lời mời tham gia nhóm ${qrData.groupName}';
      } catch (e) {
        lastMessagePreview = 'Đã gửi lời mời nhóm';
      }
    } else if (message.type == 'call_audio' || message.type == 'call_video') {
      if (message.content == 'missed') {
        lastMessagePreview = 'Cuộc gọi nhỡ';
      } else if (message.content == 'declined') {
        lastMessagePreview = 'Cuộc gọi đã bị từ chối';
      } else if (message.content.startsWith('completed_')) {
        final duration = message.content.split('_').last; // Lấy "mm:ss"
        lastMessagePreview =
            (message.type == 'call_audio'
                ? 'Cuộc gọi thoại'
                : 'Cuộc gọi video') +
            ' • $duration';
      } else {
        lastMessagePreview =
            message.type == 'call_audio' ? 'Cuộc gọi thoại' : 'Cuộc gọi video';
      }
    }
    // === KẾT THÚC LOGIC MỚI ===
    else if (message.mediaIds.isNotEmpty) {
      final mediaCount = message.mediaIds.length;
      if (message.content.isNotEmpty) {
        lastMessagePreview = '${message.content} 📷';
      } else {
        lastMessagePreview =
            mediaCount > 1 ? '$mediaCount ảnh/video' : '1 ảnh/video';
      }
    } else {
      lastMessagePreview =
          message.content.isNotEmpty
              ? message.content
              : 'Tin nhắn không có nội dung';
    }

    // Cập nhật tin nhắn cuối cùng
    await _firestore.collection('Chat').doc(chatId).update({
      'lastMessage': lastMessagePreview, // <-- DÙNG PREVIEW MỚI
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Tạo hoặc lấy thông tin phòng chat của nhóm
  Future<String> getOrCreateGroupChat(
    String groupId,
    List<String> memberIds,
  ) async {
    final chatDoc = _firestore.collection('Chat').doc(groupId);
    final docSnapshot = await chatDoc.get();

    if (!docSnapshot.exists) {
      // Nếu chưa có, tạo phòng chat mới
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
    // Sắp xếp ID để đảm bảo ID phòng chat là duy nhất cho cặp người dùng này
    final ids = [user1Id, user2Id]..sort();
    final chatId = ids.join('_');

    final chatDoc = _firestore.collection('Chat').doc(chatId);
    final docSnapshot = await chatDoc.get();

    if (!docSnapshot.exists) {
      // Nếu phòng chat chưa tồn tại, tạo mới
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

  Stream<List<ChatModel>> getChatsForUser(String userId) {
    return _firestore
        .collection('Chat')
        .where('members', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  /// Thu hồi tin nhắn và cập nhật lastMessage nếu cần
  Future<void> recallMessage(String chatId, String messageId) async {
    try {
      final messageRef = _firestore
          .collection('Chat')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      final chatRef = _firestore.collection('Chat').doc(chatId);

      // 1. Lấy thông tin tin nhắn hiện tại
      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) return;

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final messageTimestamp = (messageData['createdAt'] as Timestamp).toDate();

      // 2. Thu hồi tin nhắn
      await messageRef.update({
        'status': 'recalled',
        'content': '', // Xóa nội dung
        'mediaIds': [], // Xóa media
      });

      // 3. Kiểm tra xem có phải tin nhắn cuối cùng không
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) return;

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final lastMessageTime = (chatData['updatedAt'] as Timestamp).toDate();

      // Nếu là tin nhắn cuối cùng (thời gian gần khớp), cập nhật lastMessage
      if (messageTimestamp.isAtSameMomentAs(lastMessageTime) ||
          messageTimestamp.difference(lastMessageTime).abs().inSeconds < 2) {
        await _updateLastMessage(chatId);
      }
    } catch (e) {
      print('❌ Lỗi khi thu hồi tin nhắn: $e');
      rethrow;
    }
  }

  /// Xóa tin nhắn và cập nhật lastMessage nếu cần
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final messageRef = _firestore
          .collection('Chat')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      final chatRef = _firestore.collection('Chat').doc(chatId);

      // 1. Lấy thông tin tin nhắn hiện tại
      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) return;

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final messageTimestamp = (messageData['createdAt'] as Timestamp).toDate();

      // 2. Xóa tin nhắn
      await messageRef.update({'status': 'deleted'});

      // 3. Kiểm tra xem có phải tin nhắn cuối cùng không
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) return;

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final lastMessageTime = (chatData['updatedAt'] as Timestamp).toDate();

      // Nếu là tin nhắn cuối cùng, cập nhật lastMessage
      if (messageTimestamp.isAtSameMomentAs(lastMessageTime) ||
          messageTimestamp.difference(lastMessageTime).abs().inSeconds < 2) {
        await _updateLastMessage(chatId);
      }
    } catch (e) {
      print('❌ Lỗi khi xóa tin nhắn: $e');
      rethrow;
    }
  }

  Future<void> _updateLastMessage(String chatId) async {
    try {
      // Lấy tin nhắn gần nhất không bị recalled/deleted
      final messagesSnapshot =
          await _firestore
              .collection('Chat')
              .doc(chatId)
              .collection('messages')
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

        // === SAO CHÉP LOGIC PREVIEW TỪ HÀM SENDMESSAGE ===
        if (messageModel.type == 'share_post') {
          newLastMessage = 'Đã chia sẻ một bài viết';
        }
        else if (messageModel.type == 'location') {
          newLastMessage = '📍 Đã chia sẻ vị trí';
          }
        else if (messageModel.type == 'share_group_qr') {
          try {
            final qrData = QRInviteData.fromQRString(messageModel.content);
            newLastMessage = 'Lời mời tham gia nhóm ${qrData.groupName}';
          } catch (e) {
            newLastMessage = 'Đã gửi lời mời nhóm';
          }
        } else if (messageModel.type == 'call_audio' ||
            messageModel.type == 'call_video') {
          if (messageModel.content == 'missed') {
            newLastMessage = 'Cuộc gọi nhỡ';
          } else if (messageModel.content == 'declined') {
            newLastMessage = 'Cuộc gọi đã bị từ chối';
          } else if (messageModel.content.startsWith('completed_')) {
            final duration = messageModel.content.split('_').last;
            newLastMessage =
                (messageModel.type == 'call_audio'
                    ? 'Cuộc gọi thoại'
                    : 'Cuộc gọi video') +
                ' • $duration';
          } else {
            newLastMessage =
                messageModel.type == 'call_audio'
                    ? 'Cuộc gọi thoại'
                    : 'Cuộc gọi video';
          }
        } else if (messageModel.mediaIds.isNotEmpty) {
          final mediaCount = messageModel.mediaIds.length;
          if (messageModel.content.isNotEmpty) {
            newLastMessage = '${messageModel.content} 📷';
          } else {
            newLastMessage =
                mediaCount > 1 ? '$mediaCount ảnh/video' : '1 ảnh/video';
          }
        } else {
          newLastMessage =
              messageModel.content.isNotEmpty
                  ? messageModel.content
                  : 'Tin nhắn không có nội dung';
        }
        // === KẾT THÚC SAO CHÉP ===

        newUpdatedAt = messageModel.createdAt;
      }

      // Cập nhật Chat document
      await _firestore.collection('Chat').doc(chatId).update({
        'lastMessage': newLastMessage,
        'updatedAt': Timestamp.fromDate(newUpdatedAt),
      });

      print('✅ Đã cập nhật lastMessage cho chat $chatId: $newLastMessage');
    } catch (e) {
      print('❌ Lỗi khi cập nhật lastMessage: $e');
    }
  }

  /// Cập nhật trạng thái của tin nhắn (ví dụ: 'seen')
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    String status,
  ) async {
    await _firestore
        .collection('Chat')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': status});
  }
}
