
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/view/call/ongoing_call_screen.dart';
import 'package:mangxahoi/services/sound_service.dart';

class IncomingCallViewModel extends ChangeNotifier {
  final CallService callService;
  final CallModel call;
  final SoundService soundService;

  // Cờ để ngăn việc pop/dừng âm thanh nhiều lần
  bool _isPopping = false;

  IncomingCallViewModel({
    required this.call,
    required this.callService,
    required this.soundService,
  }) {
    // Tự động phát nhạc chuông khi ViewModel được tạo
    _init(); 
  }

  void _init() {
    _isPopping = false;
    // Tên hàm 'playRingtone' này là từ file sound_service chúng ta đã làm
    soundService.playIncomingCall(); 
  }

  String get callerName => call.callerName;
  String get callerAvatar => call.callerAvatar;
  IconData get mediaIcon => (call.mediaType == CallMediaType.video)
      ? Icons.videocam
      : Icons.call;

  // Xử lý khi người dùng chấp nhận
  Future<void> onAcceptCall(BuildContext context) async {
    if (_isPopping) return;
    _isPopping = true;
    
    await soundService.stopRingtone();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OngoingCallScreen(call: call, isReceiver: true),
      ),
    );
  }

  // Xử lý khi người dùng từ chối
  Future<void> onRejectCall(BuildContext context) async {
    if (_isPopping) return;
    _isPopping = true;

    await soundService.stopRingtone(); 
    await soundService.playEndCall();  
    
    await callService.rejectOrCancelCall(call);
    
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // ▼▼▼ HÀM SỬA LỖI: Xử lý khi người gọi dập máy ▼▼▼
  Future<void> onCallEndedRemotely(BuildContext context) async {
    // Tránh gọi pop nhiều lần
    if (_isPopping) return; 
    _isPopping = true;

    await soundService.stopRingtone();
    await soundService.playEndCall(); // Phát âm thanh "tút tút"
    
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // Đảm bảo dừng nhạc chuông nếu ViewModel bị hủy bất ngờ
  @override
  void dispose() {
    // Chỉ dừng nếu chưa bị dừng bởi 1 trong 3 hàm trên
    if (!_isPopping) {
      soundService.stopRingtone();
    }
    super.dispose();
  }
}