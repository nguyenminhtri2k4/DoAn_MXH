
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class OngoingCallViewModel extends ChangeNotifier {
  final CallService callService;
  final CallModel call;
  final bool isReceiver; // <--- THÊM DÒNG NÀY

  // State
  bool isMuted = false;
  bool isSpeakerOn = true;
  bool isVideoOff = false;
  bool isFrontCamera = true;
  int durationInSeconds = 0;
  String otherUserName = "Đang tải...";
  String otherUserAvatar = "";
  String callStatusText = "Đang kết nối...";

  // Biến nội bộ
  int? _localViewID;
  int? _remoteViewID;
  Widget? _localVideoView;
  Widget? _remoteVideoView;
  String? _remoteStreamID;
  Timer? _timer;
  StreamSubscription? _callStatusSubscription;

  // ▼▼▼ SỬA CONSTRUCTOR ▼▼▼
  OngoingCallViewModel({
    required this.call, 
    required this.callService, 
    this.isReceiver = false // <--- THÊM DÒNG NÀY
  }) {
    isVideoOff = (call.mediaType == CallMediaType.audio);
    isSpeakerOn = true; 
    callService.toggleSpeaker(isSpeakerOn);
  }

  // ▼▼▼ SỬA HÀM INIT ▼▼▼
  void init() {
    _getOtherUserInfo();

    if (call.mediaType == CallMediaType.video) {
      _initVideoViews();
    }
    
    // 1. LUÔN LUÔN lắng nghe sự kiện TRƯỚC
    _initZegoEventHandlers(); 
    
    if (isReceiver) {
      // 2. NẾU LÀ NGƯỜI NHẬN, BÂY GIỜ MỚI GỌI ACCEPTCALL
      print("📞 [ViewModel] Là người nhận, đang gọi acceptCall()...");
      callService.acceptCall(call); 
    } else {
      // 3. NẾU LÀ NGƯỜI GỌI, BẮT ĐẦU ĐẾM GIỜ NGAY
      _startTimer();
    }
  }
  // ▲▲▲ KẾT THÚC SỬA HÀM INIT ▲▲▲

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return; // Đảm bảo chỉ chạy 1 lần
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      durationInSeconds++;
      notifyListeners();
    });
  }

  String get formattedDuration {
    // Nếu chưa bắt đầu, hiển thị trạng thái
    if (durationInSeconds == 0 && callStatusText.isNotEmpty) return callStatusText;
    
    final min = (durationInSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (durationInSeconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  void _getOtherUserInfo() async {
    String otherUserId = (call.callerId == callService.currentUserId)
        ? call.receiverIds.first
        : call.callerId;

    try {
      UserModel? user = await UserRequest().getUserByUid(otherUserId);
      if (user != null) {
        otherUserName = user.name;
        otherUserAvatar = user.avatar.isNotEmpty ? user.avatar.first : "";
      } else {
        otherUserName = "Không tìm thấy";
      }
    } catch (e) {
      otherUserName = "Lỗi tải tên";
    }
    
    notifyListeners(); // Luôn cập nhật UI
  }

  void _initVideoViews() async {
    _localVideoView = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      _localViewID = viewID;
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPreview(canvas: canvas);
    });
    notifyListeners();
  }

  void _initZegoEventHandlers() {
    // Lắng nghe trạng thái phòng
    ZegoExpressEngine.onRoomStateChanged = (String roomID, ZegoRoomStateChangedReason reason, int errorCode, Map<String, dynamic> extendedData) {
      print("🚩 [ZEGO EVENT] onRoomStateChanged: $reason, errorCode: $errorCode");
      if (reason == ZegoRoomStateChangedReason.LoginFailed) {
        callStatusText = "Kết nối thất bại";
        notifyListeners();
      } else if (reason == ZegoRoomStateChangedReason.Logined) { 
        // ▼▼▼ SỬA LOGIC ĐẾM GIỜ ▼▼▼
        // Người gọi đã bắt đầu đếm. Người nhận chỉ đếm khi login thành công.
        if (isReceiver) { 
           _startTimer();
        }
        // ▲▲▲ KẾT THÚC SỬA ▲▲▲
        callStatusText = ""; // Xóa "Đang kết nối..."
        notifyListeners();
      } else if (reason == ZegoRoomStateChangedReason.ReconnectFailed || 
                 reason == ZegoRoomStateChangedReason.KickOut) { 
        callStatusText = "Đã mất kết nối";
        notifyListeners();
      } else if (reason == ZegoRoomStateChangedReason.Logout) {
        callStatusText = "Đã đăng xuất";
        notifyListeners();
      }
    };

    // Lắng nghe stream (video/audio của người kia)
    ZegoExpressEngine.onRoomStreamUpdate = (String roomID, ZegoUpdateType updateType,
        List<ZegoStream> streamList, Map<String, dynamic> extendedData) async {
      
      if (updateType == ZegoUpdateType.Add) {
        print("🚩 [ZEGO EVENT] onRoomStreamUpdate: ADD (Nhận được stream từ người kia)");
        _remoteStreamID = streamList.first.streamID;
        
        if (call.mediaType == CallMediaType.video) {
          _remoteVideoView = await ZegoExpressEngine.instance.createCanvasView((viewID) {
            _remoteViewID = viewID;
            ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
            ZegoExpressEngine.instance.startPlayingStream(_remoteStreamID!, canvas: canvas);
          });
        } else {
          // Nếu là audio call, chỉ cần start playing
          ZegoExpressEngine.instance.startPlayingStream(_remoteStreamID!);
        }
        notifyListeners();
        
      } else if (updateType == ZegoUpdateType.Delete) {
        print("🚩 [ZEGO EVENT] onRoomStreamUpdate: DELETE (Người kia dừng stream)");
        if (_remoteStreamID != null) {
          ZegoExpressEngine.instance.stopPlayingStream(_remoteStreamID!);
          if (_remoteViewID != null) {
            ZegoExpressEngine.instance.destroyCanvasView(_remoteViewID!);
          }
          _remoteVideoView = null;
          _remoteViewID = null;
          _remoteStreamID = null;
          notifyListeners();
        }
      }
    };
  }

  Widget getLocalVideoView() {
    if (_localVideoView != null) {
      return _localVideoView!;
    }
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Icon(Icons.person, color: Colors.white, size: 50),
    );
  }

  Widget getRemoteVideoView() {
    if (_remoteVideoView != null) {
      return _remoteVideoView!;
    }
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              callStatusText, // Hiển thị trạng thái
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  //--- Điều khiển ---
  void onToggleMute() {
    isMuted = !isMuted;
    callService.toggleMute(isMuted);
    notifyListeners();
  }

  void onToggleSpeaker() {
    isSpeakerOn = !isSpeakerOn;
    callService.toggleSpeaker(isSpeakerOn);
    notifyListeners();
  }

  void onToggleVideo() {
    isVideoOff = !isVideoOff;
    ZegoExpressEngine.instance.mutePublishStreamVideo(isVideoOff);
    notifyListeners();
  }

  void onSwitchCamera() {
    isFrontCamera = !isFrontCamera;
    ZegoExpressEngine.instance.useFrontCamera(isFrontCamera);
    notifyListeners();
  }

  Future<void> onEndCall(BuildContext context) async {
    // cleanup() sẽ được gọi bởi dispose() khi Navigator.pop()
    // Chỉ cần gọi service để endCall trên Firestore
    await callService.endCall(call);
    
    // Tự pop màn hình
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void cleanup() {
    print("🧼 [ViewModel] cleanup() được gọi");
    _timer?.cancel();
    _callStatusSubscription?.cancel();

    // Hủy callback
    ZegoExpressEngine.onRoomStateChanged = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;

    // Dừng stream
    if (_remoteStreamID != null) {
      ZegoExpressEngine.instance.stopPlayingStream(_remoteStreamID!);
    }
    
    // Dừng tác vụ Zego
    print("🧼 [ViewModel] Đang gọi stopPublishingStream...");
    ZegoExpressEngine.instance.stopPublishingStream(); 
    
    print("🧼 [ViewModel] Đang gọi stopPreview...");
    ZegoExpressEngine.instance.stopPreview();

    // Destroy views
    if (_localViewID != null) {
      ZegoExpressEngine.instance.destroyCanvasView(_localViewID!);
    }
    if (_remoteViewID != null) {
      ZegoExpressEngine.instance.destroyCanvasView(_remoteViewID!);
    }
    
    // Đăng xuất khỏi phòng Zego
    print("🧼 [ViewModel] Đang logout khỏi phòng: ${call.channelName}");
    ZegoExpressEngine.instance.logoutRoom(call.channelName);

    // ▼▼▼ THÊM DÒNG NÀY: BUỘC RESET LOA SAU KHI LOGOUT ▼▼▼
    // Việc này sẽ gọi setAudioRouteToSpeaker(false) để giải phóng focus cao nhất
    print("🧼 [ViewModel] Đang reset audio route về mặc định...");
    callService.toggleSpeaker(false); 
    // ▲▲▲ KẾT THÚC THÊM DÒNG NÀY ▲▲▲

    // Reset state
    _localViewID = null;
    _localVideoView = null;
    _remoteViewID = null;
    _remoteVideoView = null;
    _remoteStreamID = null;
  }
}