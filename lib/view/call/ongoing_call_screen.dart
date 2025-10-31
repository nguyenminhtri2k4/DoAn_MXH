// lib/view/call/ongoing_call_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/viewmodel/ongoing_call_view_model.dart';
import 'package:provider/provider.dart';
// Import Zego để dùng ZegoCanvasView
import 'package:zego_express_engine/zego_express_engine.dart';

class OngoingCallScreen extends StatefulWidget {
  final CallModel call;
  final bool isReceiver;
  const OngoingCallScreen({
    Key? key,
     required this.call, 
     this.isReceiver = false,}) : 
     super(key: key);

  @override
  _OngoingCallScreenState createState() => _OngoingCallScreenState();
}

class _OngoingCallScreenState extends State<OngoingCallScreen> {
  late OngoingCallViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Tạo ViewModel
    _viewModel = OngoingCallViewModel(
      call: widget.call,
      callService: context.read<CallService>(),
      isReceiver: widget.isReceiver,
    );
    // Gọi hàm init
    _viewModel.init();
  }

  @override
  void dispose() {
    // Gọi hàm dọn dẹp
    _viewModel.cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cung cấp ViewModel cho cây widget con
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<OngoingCallViewModel>(
        builder: (context, viewModel, child) {
          
          // Lắng nghe stream để pop
          return StreamBuilder<DocumentSnapshot>(
            stream: viewModel.callService.getCallStatusStream(viewModel.call.id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                CallModel updatedCall = CallModel.fromJson(snapshot.data!.data() as Map<String, dynamic>);
                if (updatedCall.status == CallStatus.ended || updatedCall.status == CallStatus.declined) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  });
                }
              } else if (!snapshot.hasData && snapshot.connectionState != ConnectionState.waiting) {
                // Document bị xóa
                WidgetsBinding.instance.addPostFrameCallback((_) {
                   if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                   }
                });
              }

              return Scaffold(
                backgroundColor: Colors.black,
                body: (viewModel.call.mediaType == CallMediaType.video)
                    ? _buildVideoCallUI(viewModel)
                    : _buildAudioCallUI(viewModel),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildVideoCallUI(OngoingCallViewModel viewModel) {
    return Stack(
      children: [
        // Video người kia (full màn hình)
        Positioned.fill(child: viewModel.getRemoteVideoView()),
        
        // Video của mình (góc nhỏ)
        Positioned(
          top: 60,
          right: 20,
          child: SizedBox(
            width: 100,
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: viewModel.getLocalVideoView(),
            ),
          ),
        ),
        
        // Hàng nút điều khiển
        _buildControls(viewModel),
      ],
    );
  }
  
  // GIAO DIỆN GỌI TIẾNG
  Widget _buildAudioCallUI(OngoingCallViewModel viewModel) {
    return Center(
      child: Column(
        // ▼▼▼ SỬA LỖI ĐÁNH MÁY (lỗi build 6s) ▼▼▼
        mainAxisAlignment: MainAxisAlignment.center,
        // ▲▲▲ KẾT THÚC SỬA ▲▲▲
        children: [
          Text(
            viewModel.otherUserName,
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            viewModel.formattedDuration,
            style: TextStyle(fontSize: 18, color: Colors.white54),
          ),
          SizedBox(height: 50),
          CircleAvatar(
            radius: 70,
            backgroundImage: (viewModel.otherUserAvatar.isNotEmpty) 
                ? NetworkImage(viewModel.otherUserAvatar) 
                : null,
            child: (viewModel.otherUserAvatar.isEmpty)
                ? Icon(Icons.person, size: 70)
                : null,
          ),
          Spacer(),
          _buildControls(viewModel),
        ],
      ),
    );
  }

  // HÀNG NÚT ĐIỀU KHIỂN
  Widget _buildControls(OngoingCallViewModel viewModel) {
    bool isVideoCall = viewModel.call.mediaType == CallMediaType.video;

    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: viewModel.isMuted ? Icons.mic_off : Icons.mic,
            onPressed: viewModel.onToggleMute,
          ),
          _buildControlButton(
            icon: viewModel.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            onPressed: viewModel.onToggleSpeaker,
          ),
          if (isVideoCall)
            _buildControlButton(
              icon: viewModel.isVideoOff ? Icons.videocam_off : Icons.videocam,
              onPressed: viewModel.onToggleVideo,
            ),
          if (isVideoCall)
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              onPressed: viewModel.onSwitchCamera,
            ),
          FloatingActionButton(
            onPressed: () => viewModel.onEndCall(context),
            backgroundColor: Colors.red,
            child: Icon(Icons.call_end, color: Colors.white),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 30),
      onPressed: onPressed,
      padding: EdgeInsets.all(15),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.3)
      ),
    );
  }
  
}

