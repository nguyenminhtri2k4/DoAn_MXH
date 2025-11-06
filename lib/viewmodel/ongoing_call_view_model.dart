
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class OngoingCallViewModel extends ChangeNotifier {
  final CallService callService;
  final CallModel call;
  final bool isReceiver;

  bool isMuted = false;
  bool isSpeakerOn = true; // Mặc định luôn là TRUE để dễ test
  bool isVideoOff = false;
  bool isFrontCamera = true;

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

    // 1. Cấu hình ban đầu
    if (call.mediaType == CallMediaType.audio) {
      isVideoOff = true;
      ZegoExpressEngine.instance.enableCamera(false);
    }

    // 2. Bật loa ngoài ngay lập tức
    isSpeakerOn = true;
    ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);

    // 3. Lắng nghe sự kiện thay đổi đường dẫn âm thanh để "ép" lại nếu cần
    ZegoExpressEngine.onAudioRouteChange = (ZegoAudioRoute audioRoute) {
      debugPrint("🔊 [ZEGO EVENT] Audio Route changed to: $audioRoute");
      // Nếu hệ thống tự chuyển về Receiver (loa trong), ta ép lại về Speaker (loa ngoài)
      if (audioRoute == ZegoAudioRoute.Receiver && isSpeakerOn) {
         debugPrint("🔊 [ZEGO] Hệ thống tự chuyển về loa trong, đang ép bật lại loa ngoài...");
         ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);
      }
    };

    ZegoExpressEngine.onRoomStreamUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
      if (updateType == ZegoUpdateType.Add) {
        _remoteStreamID = streamList.first.streamID;
        debugPrint("🔌 [ZEGO] Phát hiện stream mới: $_remoteStreamID");

        // Luôn start playing bất kể là video hay audio
        ZegoExpressEngine.instance.startPlayingStream(_remoteStreamID!);

        // "Spam" lệnh bật loa ngoài để đảm bảo nó có hiệu lực sau khi stream bắt đầu
        Future.delayed(const Duration(milliseconds: 500), () => ZegoExpressEngine.instance.setAudioRouteToSpeaker(true));
        Future.delayed(const Duration(seconds: 2), () => ZegoExpressEngine.instance.setAudioRouteToSpeaker(true));

      } else if (updateType == ZegoUpdateType.Delete) {
         _remoteStreamID = null;
      }
    };

    _listenToCallStatus(context);
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

      if (status == CallStatus.ended.name || status == CallStatus.declined.name) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      notifyListeners();
    });
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
    // Đảm bảo streamID đã có trước khi tạo view
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

  Future<void> onEndCall(BuildContext context) async {
    _callStatusSubscription?.cancel();
    await callService.endCall(call);
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void cleanup() {
    _timer?.cancel();
    _callStatusSubscription?.cancel();
    
    // Hủy các listener
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onAudioRouteChange = null;

    ZegoExpressEngine.instance.stopPreview();
    ZegoExpressEngine.instance.stopPublishingStream();
    if (_remoteStreamID != null) {
       ZegoExpressEngine.instance.stopPlayingStream(_remoteStreamID!);
    }
    ZegoExpressEngine.instance.logoutRoom(call.channelName);
    
    // Tắt loa ngoài khi thoát để tránh ảnh hưởng app khác
    ZegoExpressEngine.instance.setAudioRouteToSpeaker(false);
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }
}