// lib/viewmodel/chat_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/request/chat_request.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatViewModel extends ChangeNotifier {
  final String chatId;
  final ChatRequest _chatRequest = ChatRequest();
  final _auth = FirebaseAuth.instance;

  late Stream<List<MessageModel>> messagesStream;
  final TextEditingController messageController = TextEditingController();

  String? get currentUserId => _auth.currentUser?.uid;

  ChatViewModel({required this.chatId}) {
    messagesStream = _chatRequest.getMessages(chatId);
  }

  Future<void> sendMessage() async {
    if (messageController.text.isEmpty || currentUserId == null) return;

    final message = MessageModel(
      id: '',
      content: messageController.text,
      createdAt: DateTime.now(),
      senderId: currentUserId!,
      mediaIds: [],
      status: 'sent'
    );

    await _chatRequest.sendMessage(chatId, message);
    messageController.clear();
  }
}