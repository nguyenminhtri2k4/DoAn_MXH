
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/viewmodel/ongoing_call_view_model.dart';
import 'package:provider/provider.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:mangxahoi/constant/app_colors.dart'; // Giả sử bạn có file này
import 'dart:async'; // Thêm import này

class OngoingCallScreen extends StatefulWidget {
  final CallModel call;
  final bool isReceiver;
  const OngoingCallScreen({
    Key? key,
    required this.call,
    this.isReceiver = false,
  }) : super(key: key);

  @override
  _OngoingCallScreenState createState() => _OngoingCallScreenState();
}

class _OngoingCallScreenState extends State<OngoingCallScreen> {
  late OngoingCallViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OngoingCallViewModel(
      call: widget.call,
      callService: context.read<CallService>(),
      isReceiver: widget.isReceiver,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.init(context);
    });

    ZegoExpressEngine.onRoomStateChanged = (String roomID, ZegoRoomStateChangedReason reason, int errorCode, Map<String, dynamic> extendedData) {
      if (errorCode != 0 && mounted) {
         debugPrint("⚠️ [ONGOING] Zego Error: $errorCode, Reason: $reason");
         // Tự động thoát nếu login fail (lỗi 1002001)
         if (reason == ZegoRoomStateChangedReason.LoginFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi kết nối: $errorCode"), backgroundColor: Colors.red),
            );
            Navigator.pop(context);
         }
      }
    };
  }

  @override
  void dispose() {
    ZegoExpressEngine.onRoomStateChanged = null;
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<OngoingCallViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  (viewModel.call.mediaType == CallMediaType.video)
                      ? _buildVideoCallUI(viewModel)
                      : _buildAudioCallUI(viewModel),
                  
                  _buildControls(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ▼▼▼ SỬA LỖI 3: Dùng FutureBuilder ▼▼▼
  Widget _buildVideoCallUI(OngoingCallViewModel viewModel) {
    return Stack(
      children: [
        // Video người kia (full màn hình)
        Positioned.fill(
          child: FutureBuilder<Widget?>(
            future: viewModel.getRemoteVideoView(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                return snapshot.data!;
              }
              // Hiển thị loading khi đang chờ video
              return Container(
                color: Colors.black,
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              );
            },
          ),
        ),
        // Video của mình (góc nhỏ)
        Positioned(
          top: 20, right: 20,
          child: SizedBox(
            width: 100, height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<Widget?>(
                future: viewModel.getLocalVideoView(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                    return snapshot.data!;
                  }
                  return Container(color: Colors.grey[800]);
                },
              ),
            ),
          ),
        ),
        // Thời gian gọi
        Positioned(
          top: 20, left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(viewModel.formattedDuration, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
  // ▲▲▲ KẾT THÚC SỬA ▲▲▲

  Widget _buildAudioCallUI(OngoingCallViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          CircleAvatar(
            radius: 80,
            backgroundImage: viewModel.otherUserAvatar.isNotEmpty
                ? NetworkImage(viewModel.otherUserAvatar)
                : const NetworkImage(AppColors.defaultAvatar), // Thêm avatar mặc định
            backgroundColor: Colors.grey[800],
          ),
          const SizedBox(height: 24),
          Text(
            viewModel.otherUserName,
            style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.formattedDuration,
            style: const TextStyle(fontSize: 20, color: Colors.white70),
          ),
          const Spacer(flex: 3),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildControls(OngoingCallViewModel viewModel) {
    bool isVideoCall = viewModel.call.mediaType == CallMediaType.video;
    return Positioned(
      bottom: 30, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: viewModel.isMuted ? Icons.mic_off : Icons.mic,
            onPressed: viewModel.onToggleMute,
            isActive: !viewModel.isMuted,
          ),
          _buildControlButton(
            icon: viewModel.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            onPressed: viewModel.onToggleSpeaker,
            isActive: viewModel.isSpeakerOn,
          ),
          if (isVideoCall) ...[
             _buildControlButton(
              icon: viewModel.isVideoOff ? Icons.videocam_off : Icons.videocam,
              onPressed: viewModel.onToggleVideo,
              isActive: !viewModel.isVideoOff,
            ),
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              onPressed: viewModel.onSwitchCamera,
            ),
          ],
          FloatingActionButton(
            // ▼▼▼ SỬA LỖI 4: Thêm Hero Tag ▼▼▼
            heroTag: "ongoing_end_btn",
            onPressed: () => viewModel.onEndCall(context),
            backgroundColor: Colors.red,
            elevation: 8,
            child: const Icon(Icons.call_end, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed, bool isActive = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: isActive ? Colors.black : Colors.white, size: 28),
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}