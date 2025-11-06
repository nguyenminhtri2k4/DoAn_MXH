
// import 'package:cloud_firestore/cloud_firestore.dart'; // <--- THÊM IMPORT NÀY
// import 'package:flutter/material.dart';
// import 'package:mangxahoi/model/model_call.dart';
// import 'package:mangxahoi/services/call_service.dart';
// import 'package:mangxahoi/viewmodel/incoming_call_view_model.dart';
// import 'package:provider/provider.dart';
// import 'package:mangxahoi/constant/app_colors.dart';
// import 'package:mangxahoi/services/sound_service.dart';

// // ▼▼▼ TRẢ VỀ STATELESSWIDGET ▼▼▼
// class IncomingCallScreen extends StatelessWidget {
//   final CallModel call;
//   const IncomingCallScreen({Key? key, required this.call}) : super(key: key);

//   // (Xóa initState và dispose)

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => IncomingCallViewModel(
//         call: call, // Lấy call từ widget
//         callService: context.read<CallService>(),
//         soundService: context.read<SoundService>(),
//       ),
//       child: Consumer<IncomingCallViewModel>(
//         builder: (context, viewModel, child) {
          
//           // ▼▼▼ THÊM LẠI STREAMBUILDER ĐỂ SỬA LỖI ▼▼▼
//           return StreamBuilder<DocumentSnapshot>(
//             stream: viewModel.callService.getCallStatusStream(viewModel.call.id),
//             builder: (context, snapshot) {
              
//               if (snapshot.hasData && snapshot.data!.data() != null) {
//                 CallModel updatedCall = CallModel.fromJson(
//                     snapshot.data!.data() as Map<String, dynamic>);

//                 // NẾU CUỘC GỌI BỊ HỦY (không còn là 'pending')
//                 if (updatedCall.status != CallStatus.pending) {
//                   // Gọi hàm xử lý trong ViewModel để đóng màn hình
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     viewModel.onCallEndedRemotely(context);
//                   });
//                 }
//               }

//               // GIAO DIỆN GỐC (GIỮ NGUYÊN)
//               return Scaffold(
//                 backgroundColor: Colors.grey[800],
//                 body: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       CircleAvatar(
//                         radius: 50,
//                         backgroundImage: NetworkImage(
//                           viewModel.callerAvatar.isNotEmpty
//                               ? viewModel.callerAvatar
//                               : AppColors.defaultAvatar,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Text(
//                         viewModel.callerName,
//                         style: const TextStyle(
//                           fontSize: 24,
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(viewModel.mediaIcon, color: Colors.white54, size: 18),
//                           const SizedBox(width: 8),
//                           const Text(
//                             "Đang gọi đến...",
//                             style: TextStyle(fontSize: 16, color: Colors.white54),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 100),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           FloatingActionButton(
//                             heroTag: "incoming_reject_btn",
//                             onPressed: () => viewModel.onRejectCall(context),
//                             backgroundColor: Colors.red,
//                             child: const Icon(Icons.call_end, color: Colors.white),
//                           ),
//                           FloatingActionButton(
//                             heroTag: "incoming_accept_btn",
//                             onPressed: () => viewModel.onAcceptCall(context),
//                             backgroundColor: Colors.green,
//                             child: const Icon(Icons.call, color: Colors.white),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             // ▲▲▲ KẾT THÚC SỬA STREAMBUILDER ▲▲▲
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/viewmodel/incoming_call_view_model.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/services/sound_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final CallModel call;
  const IncomingCallScreen({Key? key, required this.call}) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  late IncomingCallViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = IncomingCallViewModel(
      call: widget.call,
      callService: context.read<CallService>(),
      soundService: context.read<SoundService>(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.init(context);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        body: Consumer<IncomingCallViewModel>(
          builder: (context, viewModel, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(
                      viewModel.callerAvatar.isNotEmpty
                          ? viewModel.callerAvatar
                          : AppColors.defaultAvatar,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    viewModel.callerName,
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(viewModel.mediaIcon, color: Colors.white54, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Cuộc gọi đến...",
                        style: TextStyle(fontSize: 18, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 120),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Nút từ chối
                      FloatingActionButton(
                        heroTag: "incoming_reject_btn",
                        onPressed: () => viewModel.onRejectCall(context),
                        backgroundColor: Colors.red,
                        elevation: 8,
                        child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                      ),
                      // Nút chấp nhận
                      FloatingActionButton(
                        heroTag: "incoming_accept_btn",
                        onPressed: () => viewModel.onAcceptCall(context),
                        backgroundColor: Colors.green,
                        elevation: 8,
                        child: const Icon(Icons.call, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}