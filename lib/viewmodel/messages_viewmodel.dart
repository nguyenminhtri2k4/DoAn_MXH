
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
  bool _isDisposed = false; // BIẾN DUY NHẤT CẦN THIẾT!!!

  bool get isLoading => _isLoading;
  Stream<List<ChatModel>>? get chatsStream => _chatsStream;
  String? get currentUserDocId => _currentUserDocId;

  MessagesViewModel() {
    _isLoading = true;
  }

  Future<void> initialize() async {
    if (_isDisposed) return;

    _isLoading = true;
    _notifySafely();

    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        _isLoading = false;
        _notifySafely();
        return;
      }

      final user = await _userRequest
          .getUserByUid(firebaseUser.uid)
          .timeout(const Duration(seconds: 15));

      if (_isDisposed) return; // KIỂM TRA SAU AWAIT!!!

      if (user != null) {
        _currentUserDocId = user.id;
        _chatsStream = _chatRequest.getChatsForUser(_currentUserDocId!);
      }
    } catch (e) {
      print('Lỗi khởi tạo MessagesViewModel: $e');
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _notifySafely();
      }
    }
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners(); // CHỈ DÙNG _isDisposed LÀ ĐỦ!!!
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // XÓA HOẶC COMMENT DÒNG NÀY ĐI – KHÔNG CẦN THIẾT!!!
  // @override
  // bool get mounted => super.mounted && !_isDisposed;
}