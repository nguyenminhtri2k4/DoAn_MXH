// lib/viewmodel/messages_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_chat.dart';
import 'package:mangxahoi/request/chat_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/request/user_request.dart';

class MessagesViewModel extends ChangeNotifier {
  final ChatRequest _chatRequest = ChatRequest();
  final UserRequest _userRequest = UserRequest();
  final _auth = FirebaseAuth.instance;

  String? _currentUserDocId;
  bool _isLoading = true;
  Stream<List<ChatModel>>? _chatsStream;

  bool get isLoading => _isLoading;
  Stream<List<ChatModel>>? get chatsStream => _chatsStream;
  String? get currentUserDocId => _currentUserDocId;

  MessagesViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final user = await _userRequest.getUserByUid(firebaseUser.uid);
      if (user != null) {
        _currentUserDocId = user.id;
        _chatsStream = _chatRequest.getChatsForUser(_currentUserDocId!);
      }
    }
    _isLoading = false;
    notifyListeners();
  }
}