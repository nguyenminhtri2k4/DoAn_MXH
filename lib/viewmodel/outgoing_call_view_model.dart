
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/view/call/ongoing_call_screen.dart';
import 'package:mangxahoi/services/sound_service.dart';

// === CÁC IMPORT ĐÃ SỬA ===
import 'package:mangxahoi/request/chat_request.dart';
import 'package:mangxahoi/model/model_message.dart';
// ==========================

class OutgoingCallViewModel extends ChangeNotifier {
  final CallService callService;
  final CallModel call;
  final SoundService soundService;

  // === THÊM DÒNG NÀY ===
  final ChatRequest _chatRequest = ChatRequest();
  // ======================

  String receiverName = "Đang tải...";
  String receiverAvatar = "";
  bool _isWaiting = true;

  StreamSubscription<DocumentSnapshot>? _callStatusSubscription;

  OutgoingCallViewModel({
    required this.call,
    required this.callService,
    required this.soundService,
  }) {
    _loadReceiverInfo();
  }

  void init(BuildContext context) {
    _listenToCallStatus(context);
  }

  void _loadReceiverInfo() async {
    String receiverId = call.receiverIds.first;
    UserModel? user = await UserRequest().getUserByUid(receiverId);

    if (user != null) {
      receiverName = user.name;
      receiverAvatar = user.avatar.isNotEmpty ? user.avatar.first : "";
      notifyListeners();
    }
  }

  // === HÀM HELPER GỬI TIN NHẮN (ĐÃ SỬA) ===
  Future<void> _sendCallMessage(String callStatus, String senderId) async {
    try {
      final callMessage = MessageModel(
        id: '',
        senderId: senderId,
        content: callStatus, 
        createdAt: DateTime.now(),
        mediaIds: [],
        status: 'sent',
        type: call.mediaType == CallMediaType.audio ? 'call_audio' : 'call_video',
      );
      
      print("DEBUG [OutgoingCall]: Đang gửi tin nhắn: $callStatus cho chatId: ${call.chatId} bởi $senderId");
      await _chatRequest.sendMessage(call.chatId, callMessage);
    } catch (e) {
      print('Lỗi khi gửi tin nhắn (outgoing): $e');
    }
  }
  // ===================================

  void _listenToCallStatus(BuildContext context) {
    _callStatusSubscription?.cancel();
    _callStatusSubscription = callService.getCallStatusStream(call.id).listen((snapshot) async {
      if (!snapshot.exists || !context.mounted || !_isWaiting) return;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      String status = data['status'];

      if (status == CallStatus.accepted.name) {
        _isWaiting = false;
        _callStatusSubscription?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OngoingCallScreen(call: call)),
        );
      } 
      // === LOGIC SỬA: NẾU BỊ TỪ CHỐI ===
      else if (status == CallStatus.declined.name) {
        if (!_isWaiting) return;
        _isWaiting = false;
        _callStatusSubscription?.cancel();
        await soundService.playEndCall();

        // Gửi tin nhắn 'declined'
        // Người gửi tin nhắn là người nhận (người đã từ chối)
        await _sendCallMessage('declined', call.receiverIds.first); 
        
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } 
      // =================================
      else if (status == CallStatus.ended.name) {
         if (!_isWaiting) return;
        _isWaiting = false;
        _callStatusSubscription?.cancel();
        await soundService.playEndCall();
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  Future<void> onCancelCall(BuildContext context) async {
    if (!_isWaiting) return;
    _isWaiting = false;
    _callStatusSubscription?.cancel();
    soundService.playEndCall(); 

    // Gửi tin nhắn "missed" (do người gọi tự hủy)
    // Người gửi tin nhắn là người gọi (caller)
    await _sendCallMessage('missed', call.callerId); 

    await callService.rejectOrCancelCall(call);

    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _callStatusSubscription?.cancel();
    super.dispose();
  }
}