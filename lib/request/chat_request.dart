// lib/request/chat_request.dart
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
}