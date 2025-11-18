
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

// === CÁC IMPORT ĐÃ SỬA ===
import 'package:mangxahoi/request/chat_request.dart'; // Import trực tiếp
import 'package:mangxahoi/model/model_message.dart';  // Import trực tiếp
// (Không cần Provider cho ChatRequest/UserService)
// ==========================

class OngoingCallViewModel extends ChangeNotifier {
  final CallService callService;
  final CallModel call;
  final bool isReceiver;

  // === THÊM DÒNG NÀY ===
  final ChatRequest _chatRequest = ChatRequest();
  // ======================

  bool isMuted = false;
  bool isSpeakerOn = true; 
  bool isVideoOff = false;
  bool isFrontCamera = true;
  
  bool _isCallEnded = false; // Cờ quan trọng để tránh gửi 2 lần

  Timer? _timer;
  int _seconds = 0;
  StreamSubscription<DocumentSnapshot>? _callStatusSubscription;

  String _otherUserName = "Đang tải...";
  String _otherUserAvatar = "";
  String? _remoteStreamID;

  OngoingCallViewModel({
    required this.call,
    required this.callService,
    this.isReceiver = false,
  });

  void init(BuildContext context) {
    _loadOtherUserInfo();
    _startTimer();
    _listenToCallStatus(context); // Cần context cho Navigator

    if (call.mediaType == CallMediaType.audio) {
      isVideoOff = true;
      ZegoExpressEngine.instance.enableCamera(false);
    }
    isSpeakerOn = true;
    ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);

    ZegoExpressEngine.onAudioRouteChange = (ZegoAudioRoute audioRoute) {
      debugPrint("🔊 [ZEGO EVENT] Audio Route changed to: $audioRoute");
      if (audioRoute == ZegoAudioRoute.Receiver && isSpeakerOn) {
         debugPrint("🔊 [ZEGO] Hệ thống tự chuyển về loa trong, đang ép bật lại loa ngoài...");
         ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);
      }
    };

    ZegoExpressEngine.onRoomStreamUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
      if (updateType == ZegoUpdateType.Add) {
        _remoteStreamID = streamList.first.streamID;
        debugPrint("🔌 [ZEGO] Phát hiện stream mới: $_remoteStreamID");
        ZegoExpressEngine.instance.startPlayingStream(_remoteStreamID!);
        Future.delayed(const Duration(milliseconds: 500), () => ZegoExpressEngine.instance.setAudioRouteToSpeaker(true));
        Future.delayed(const Duration(seconds: 2), () => ZegoExpressEngine.instance.setAudioRouteToSpeaker(true));
      } else if (updateType == ZegoUpdateType.Delete) {
         _remoteStreamID = null;
         debugPrint("🔌 [ZEGO] Stream đã bị xóa (người kia cúp máy).");
      }
    };
  }

  void _loadOtherUserInfo() async {
    if (isReceiver) {
      _otherUserName = call.callerName;
      _otherUserAvatar = call.callerAvatar;
      notifyListeners();
    } else {
      try {
        String receiverId = call.receiverIds.first;
        UserModel? user = await UserRequest().getUserByUid(receiverId);
        if (user != null) {
          _otherUserName = user.name;
          _otherUserAvatar = user.avatar.isNotEmpty ? user.avatar.first : "";
        } else {
          _otherUserName = "Người dùng";
        }
      } catch (e) {
        _otherUserName = "Lỗi tải tên";
      }
      notifyListeners();
    }
  }

  void _listenToCallStatus(BuildContext context) {
    _callStatusSubscription = callService.getCallStatusStream(call.id).listen((snapshot) {
      if (!snapshot.exists || !context.mounted) return;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      String status = data['status'];

      // === LOGIC SỬA: NẾU NGƯỜI KIA CÚP MÁY ===
      if ((status == CallStatus.ended.name || status == CallStatus.declined.name) && !_isCallEnded) {
        print("DEBUG [OngoingCall]: Người kia đã cúp máy (status: $status).");
        _isCallEnded = true; 
        _stopTimer();

        // Gửi tin nhắn "completed"
        // Người gửi tin nhắn là người kia (người đã cúp máy)
        String remoteUserId = isReceiver ? call.callerId : call.receiverIds.first;
        _sendCallMessage('completed_$formattedDuration', remoteUserId);

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
      // ======================================
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String get formattedDuration {
    int minutes = _seconds ~/ 60;
    int remainingSeconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String get otherUserName => _otherUserName;
  String get otherUserAvatar => _otherUserAvatar;

  Future<Widget?> getLocalVideoView() async {
     return ZegoExpressEngine.instance.createCanvasView((viewID) {
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPreview(canvas: canvas);
    });
  }
  Future<Widget?> getRemoteVideoView() async {
    String streamID = _remoteStreamID ?? '${isReceiver ? call.callerId : call.receiverIds.first}_stream';
    return ZegoExpressEngine.instance.createCanvasView((viewID) {
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    });
  }

  void onToggleMute() {
    isMuted = !isMuted;
    callService.toggleMute(isMuted);
    notifyListeners();
  }
  void onToggleSpeaker() {
    isSpeakerOn = !isSpeakerOn;
    debugPrint("🔊 [ViewModel] Người dùng toggle loa: $isSpeakerOn");
    ZegoExpressEngine.instance.setAudioRouteToSpeaker(isSpeakerOn);
    notifyListeners();
  }
  void onToggleVideo() {
    isVideoOff = !isVideoOff;
    ZegoExpressEngine.instance.enableCamera(!isVideoOff);
    ZegoExpressEngine.instance.mutePublishStreamVideo(isVideoOff);
    notifyListeners();
  }
  void onSwitchCamera() {
    isFrontCamera = !isFrontCamera;
    ZegoExpressEngine.instance.useFrontCamera(isFrontCamera);
    notifyListeners();
  }

  // === HÀM HELPER GỬI TIN NHẮN (ĐÃ SỬA) ===
  Future<void> _sendCallMessage(String callStatus, String senderId) async {
    try {
      final String callType = call.mediaType == CallMediaType.audio ? 'call_audio' : 'call_video';
      
      final callMessage = MessageModel(
        id: '',
        senderId: senderId, 
        content: callStatus,
        createdAt: DateTime.now(),
        mediaIds: [],
        status: 'sent',
        type: callType,
      );
      
      print("DEBUG [OngoingCall]: Đang gửi tin nhắn: $callStatus cho chatId: ${call.chatId} bởi $senderId");
      // Sử dụng _chatRequest (instance của class), không dùng Provider
      await _chatRequest.sendMessage(call.chatId, callMessage); 
    } catch (e) {
      print('Lỗi khi gửi tin nhắn thông báo cuộc gọi: $e');
    }
  }
  // ===================================

  Future<void> onEndCall(BuildContext context) async {
    if (_isCallEnded) return; 
    _isCallEnded = true; 
    
    _callStatusSubscription?.cancel();
    _stopTimer(); 

    // Gửi tin nhắn "completed" (do MÌNH nhấn cúp)
    final currentUserId = callService.currentUserId; // Lấy ID từ CallService
    if (currentUserId != null) {
      await _sendCallMessage('completed_$formattedDuration', currentUserId);
    }
    
    await callService.endCall(call);
    
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void cleanup() {
    _timer?.cancel();
    _callStatusSubscription?.cancel();
    
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onAudioRouteChange = null;

    ZegoExpressEngine.instance.stopPreview();
    ZegoExpressEngine.instance.stopPublishingStream();
    if (_remoteStreamID != null) {
       ZegoExpressEngine.instance.stopPlayingStream(_remoteStreamID!);
    }
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }
}