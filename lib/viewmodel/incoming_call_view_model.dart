
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:mangxahoi/model/model_call.dart';
// import 'package:mangxahoi/services/call_service.dart';
// import 'package:mangxahoi/view/call/ongoing_call_screen.dart';
// import 'package:mangxahoi/services/sound_service.dart';
// import 'package:mangxahoi/request/chat_request.dart';
// import 'package:mangxahoi/model/model_message.dart';
// import 'package:mangxahoi/services/user_service.dart';
// import 'package:provider/provider.dart';

// class IncomingCallViewModel extends ChangeNotifier {
//   final CallService callService;
//   final CallModel call;
//   final SoundService soundService;

//   bool _isProcessed = false; // Đảm bảo chỉ xử lý 1 hành động (nghe/từ chối/hủy)
//   StreamSubscription<DocumentSnapshot>? _callStatusSubscription;

//   IncomingCallViewModel({
//     required this.call,
//     required this.callService,
//     required this.soundService,
//   });

//   void init(BuildContext context) {
//     _isProcessed = false;
//     soundService.playIncomingCall(); // Bắt đầu đổ chuông
//     _listenToRemoteCancel(context);
//   }

//   // Lắng nghe nếu người GỌI hủy cuộc gọi trước
//   void _listenToRemoteCancel(BuildContext context) {
//     _callStatusSubscription = callService.getCallStatusStream(call.id).listen((snapshot) async {
//       if (!snapshot.exists || !context.mounted) return;

//       Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
//       String status = data['status'];

//       // Nếu trạng thái chuyển sang 'ended' hoặc 'declined' mà mình chưa làm gì -> Đối phương đã hủy
//       if ((status == CallStatus.ended.name || status == CallStatus.declined.name) && !_isProcessed) {
//         _isProcessed = true;
//         await soundService.stopRingtone();
//         // await soundService.playEndCall(); // (Tùy chọn: phát tiếng tút ngắn)

//         if (context.mounted && Navigator.canPop(context)) {
//           Navigator.pop(context);
//         }
//       }
//     });
//   }

//   String get callerName => call.callerName;
//   String get callerAvatar => call.callerAvatar;
//   IconData get mediaIcon =>
//       (call.mediaType == CallMediaType.video) ? Icons.videocam : Icons.call;

//   Future<void> onAcceptCall(BuildContext context) async {
//     if (_isProcessed) return;
//     _isProcessed = true;
//     _callStatusSubscription?.cancel();

//     await soundService.stopRingtone();
//     await callService.acceptCall(call);

//     if (context.mounted) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => OngoingCallScreen(call: call, isReceiver: true),
//         ),
//       );
//     }
//   }

//   // Future<void> onRejectCall(BuildContext context) async {
//   //   if (_isProcessed) return;
//   //   _isProcessed = true;
//   //   _callStatusSubscription?.cancel();

//   //   await soundService.stopRingtone();
//   //   await callService.rejectOrCancelCall(call);

//   //   if (context.mounted && Navigator.canPop(context)) {
//   //     Navigator.pop(context);
//   //   }
//   // }
//   Future<void> onRejectCall(BuildContext context) async {
//     if (_isProcessed) return;
//     _isProcessed = true;
//     _callStatusSubscription?.cancel();

//     await soundService.stopRingtone();

//     // === BẮT ĐẦU LOGIC GỬI TIN NHẮN "TỪ CHỐI" ===
//     try {
//       final chatRequest = Provider.of<ChatRequest>(context, listen: false);
//       // Người từ chối (là user hiện tại) sẽ là người gửi tin nhắn
//       final currentUserId = Provider.of<UserService>(context, listen: false).currentUser?.uid; 

//       if (currentUserId != null) {
//         final callMessage = MessageModel(
//           id: '',
//           senderId: currentUserId, 
//           content: 'declined', // Trạng thái: Từ chối
//           createdAt: DateTime.now(),
//           mediaIds: [],
//           status: 'sent',
//           type: call.mediaType == CallMediaType.audio ? 'call_audio' : 'call_video',
//         );
        
//         await chatRequest.sendMessage(call.chatId, callMessage);
//       }
//     } catch (e) {
//       print('Lỗi khi gửi tin nhắn từ chối cuộc gọi: $e');
//     }
//     // === KẾT THÚC LOGIC GỬI TIN NHẮN ===

//     // Gọi service (như cũ)
//     await callService.rejectOrCancelCall(call);

//     if (context.mounted && Navigator.canPop(context)) {
//       Navigator.pop(context);
//     }
//   }

//   @override
//   void dispose() {
//     _callStatusSubscription?.cancel();
//     if (!_isProcessed) {
//       soundService.stopRingtone();
//     }
//     super.dispose();
//   }
// }
// lib/viewmodel/incoming_call_view_model.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/view/call/ongoing_call_screen.dart';
import 'package:mangxahoi/services/sound_service.dart';

// === CÁC IMPORT ĐÃ SỬA ===
import 'package:provider/provider.dart'; // Vẫn cần cho UserService
import 'package:mangxahoi/request/chat_request.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/services/user_service.dart';
// ==========================

class IncomingCallViewModel extends ChangeNotifier {
  final CallService callService;
  final CallModel call;
  final SoundService soundService;

  // === THÊM DÒNG NÀY ===
  final ChatRequest _chatRequest = ChatRequest();
  // ======================

  bool _isProcessed = false; 
  StreamSubscription<DocumentSnapshot>? _callStatusSubscription;

  IncomingCallViewModel({
    required this.call,
    required this.callService,
    required this.soundService,
  });

  void init(BuildContext context) {
    _isProcessed = false;
    soundService.playIncomingCall(); 
    _listenToRemoteCancel(context);
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
      
      print("DEBUG [IncomingCall]: Đang gửi tin nhắn: $callStatus cho chatId: ${call.chatId} bởi $senderId");
      await _chatRequest.sendMessage(call.chatId, callMessage);
    } catch (e) {
      print('Lỗi khi gửi tin nhắn (incoming): $e');
    }
  }
  // ===================================

  // Lắng nghe nếu người GỌI hủy cuộc gọi
  void _listenToRemoteCancel(BuildContext context) {
    _callStatusSubscription = callService.getCallStatusStream(call.id).listen((snapshot) async {
      if (!snapshot.exists || !context.mounted) return;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      String status = data['status'];

      if ((status == CallStatus.ended.name || status == CallStatus.declined.name) && !_isProcessed) {
        _isProcessed = true;
        await soundService.stopRingtone();
        
        // Nếu là 'ended', nghĩa là người gọi đã hủy -> Gửi 'missed'
        // Người gửi tin nhắn là người gọi (caller)
        if (status == CallStatus.ended.name) {
          await _sendCallMessage('missed', call.callerId);
        }
        // (Trường hợp 'declined' đã được xử lý ở OutgoingVM)

        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  String get callerName => call.callerName;
  String get callerAvatar => call.callerAvatar;
  IconData get mediaIcon =>
      (call.mediaType == CallMediaType.video) ? Icons.videocam : Icons.call;

  Future<void> onAcceptCall(BuildContext context) async {
    if (_isProcessed) return;
    _isProcessed = true;
    _callStatusSubscription?.cancel();

    await soundService.stopRingtone();
    await callService.acceptCall(call);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OngoingCallScreen(call: call, isReceiver: true),
        ),
      );
    }
  }

  Future<void> onRejectCall(BuildContext context) async {
    if (_isProcessed) return;
    _isProcessed = true;
    _callStatusSubscription?.cancel();

    await soundService.stopRingtone();

    // Gửi tin nhắn "declined" (do BẠN từ chối)
    // Dùng Provider để lấy ID của người dùng hiện tại (người từ chối)
    final currentUserId = Provider.of<UserService>(context, listen: false).currentUser?.uid;
    if (currentUserId != null) {
      await _sendCallMessage('declined', currentUserId);
    }

    await callService.rejectOrCancelCall(call);

    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _callStatusSubscription?.cancel();
    if (!_isProcessed) {
      soundService.stopRingtone();
    }
    super.dispose();
  }
}