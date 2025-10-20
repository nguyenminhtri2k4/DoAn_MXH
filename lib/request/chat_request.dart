
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_chat.dart';

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
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Gửi một tin nhắn
  Future<void> sendMessage(String chatId, MessageModel message) async {
    await _firestore
        .collection('Chat')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    // Cập nhật tin nhắn cuối cùng
    await _firestore.collection('Chat').doc(chatId).update({
      'lastMessage': message.content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Tạo hoặc lấy thông tin phòng chat của nhóm
  Future<String> getOrCreateGroupChat(String groupId, List<String> memberIds) async {
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

  // ==================== THÊM HÀM MỚI TẠI ĐÂY ====================
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
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Thu hồi một tin nhắn
  Future<void> recallMessage(String chatId, String messageId) async {
    await _firestore
        .collection('Chat')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': 'recalled'});
  }

  /// Xóa một tin nhắn (xóa mềm)
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('Chat')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': 'deleted'});
  }

  /// Cập nhật trạng thái của tin nhắn (ví dụ: 'seen')
  Future<void> updateMessageStatus(String chatId, String messageId, String status) async {
    await _firestore
        .collection('Chat')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': status});
  }
}