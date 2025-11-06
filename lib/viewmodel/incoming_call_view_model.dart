
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/view/call/ongoing_call_screen.dart';
import 'package:mangxahoi/services/sound_service.dart';

class IncomingCallViewModel extends ChangeNotifier {
  final CallService callService;
  final CallModel call;
  final SoundService soundService;

  bool _isProcessed = false; // Đảm bảo chỉ xử lý 1 hành động (nghe/từ chối/hủy)
  StreamSubscription<DocumentSnapshot>? _callStatusSubscription;

  IncomingCallViewModel({
    required this.call,
    required this.callService,
    required this.soundService,
  });

  void init(BuildContext context) {
    _isProcessed = false;
    soundService.playIncomingCall(); // Bắt đầu đổ chuông
    _listenToRemoteCancel(context);
  }

  // Lắng nghe nếu người GỌI hủy cuộc gọi trước
  void _listenToRemoteCancel(BuildContext context) {
    _callStatusSubscription = callService.getCallStatusStream(call.id).listen((snapshot) async {
      if (!snapshot.exists || !context.mounted) return;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      String status = data['status'];

      // Nếu trạng thái chuyển sang 'ended' hoặc 'declined' mà mình chưa làm gì -> Đối phương đã hủy
      if ((status == CallStatus.ended.name || status == CallStatus.declined.name) && !_isProcessed) {
        _isProcessed = true;
        await soundService.stopRingtone();
        // await soundService.playEndCall(); // (Tùy chọn: phát tiếng tút ngắn)

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