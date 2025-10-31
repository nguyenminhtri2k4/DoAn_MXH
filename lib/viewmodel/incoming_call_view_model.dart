// lib/viewmodel/incoming_call_view_model.dart
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/view/call/ongoing_call_screen.dart';

class IncomingCallViewModel extends ChangeNotifier {
  final CallService callService;
  final CallModel call;

  IncomingCallViewModel({required this.call, required this.callService});

  String get callerName => call.callerName;
  String get callerAvatar => call.callerAvatar;
  IconData get mediaIcon => (call.mediaType == CallMediaType.video)
      ? Icons.videocam
      : Icons.call;

  // Xử lý khi người dùng chấp nhận
  Future<void> onAcceptCall(BuildContext context) async {
    // 1. KHÔNG GỌI service.acceptCall() ở đây nữa
    
    // 2. Chỉ điều hướng sang OngoingCallScreen
    // Truyền thêm cờ 'isReceiver: true'
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OngoingCallScreen(call: call, isReceiver: true), // <--- SỬA Ở ĐÂY
      ),
    );
  }

  // Xử lý khi người dùng từ chối
  Future<void> onRejectCall(BuildContext context) async {
    await callService.rejectOrCancelCall(call);
    
    // ViewModel điều hướng
    Navigator.pop(context);
  }
}