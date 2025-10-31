// lib/view/call/incoming_call_screen.dart
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/viewmodel/incoming_call_view_model.dart';
import 'package:provider/provider.dart';

class IncomingCallScreen extends StatelessWidget {
  final CallModel call;
  const IncomingCallScreen({Key? key, required this.call}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Cung cấp ViewModel cho View này
    return ChangeNotifierProvider(
      create: (_) => IncomingCallViewModel(
        call: call,
        callService: context.read<CallService>(),
      ),
      child: Consumer<IncomingCallViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: Colors.grey[800],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(viewModel.callerAvatar),
                  ),
                  SizedBox(height: 20),
                  Text(
                    viewModel.callerName,
                    style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(viewModel.mediaIcon, color: Colors.white54, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Đang gọi đến...",
                        style: TextStyle(fontSize: 16, color: Colors.white54),
                      ),
                    ],
                  ),
                  SizedBox(height: 100),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Nút Từ chối
                      FloatingActionButton(
                        heroTag: "incoming_reject_btn",
                        onPressed: () => viewModel.onRejectCall(context),
                        backgroundColor: Colors.red,
                        child: Icon(Icons.call_end, color: Colors.white),
                      ),
                      // Nút Chấp nhận
                      FloatingActionButton(
                        heroTag: "incoming_accept_btn",
                        onPressed: () => viewModel.onAcceptCall(context),
                        backgroundColor: Colors.green,
                        child: Icon(Icons.call, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}