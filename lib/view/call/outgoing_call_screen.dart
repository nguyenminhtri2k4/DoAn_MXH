// lib/view/call/outgoing_call_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/viewmodel/outgoing_call_view_model.dart';
import 'package:provider/provider.dart';

class OutgoingCallScreen extends StatelessWidget {
  final CallModel call;
  const OutgoingCallScreen({Key? key, required this.call}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OutgoingCallViewModel(
        call: call,
        callService: context.read<CallService>(),
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[800],
        body: Consumer<OutgoingCallViewModel>(
          builder: (context, viewModel, child) {
            
            // Lắng nghe stream trạng thái ngay trong build
            return StreamBuilder<DocumentSnapshot>(
              stream: viewModel.callService.getCallStatusStream(viewModel.call.id),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  CallModel updatedCall = CallModel.fromJson(snapshot.data!.data() as Map<String, dynamic>);
                  // ViewModel xử lý điều hướng
                  viewModel.handleNavigation(context, updatedCall.status);
                }

                // Giao diện
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: (viewModel.receiverAvatar.isNotEmpty) 
                            ? NetworkImage(viewModel.receiverAvatar) 
                            : null,
                        child: (viewModel.receiverAvatar.isEmpty)
                            ? Icon(Icons.person, size: 50)
                            : null,
                      ),
                      SizedBox(height: 20),
                      Text(
                        viewModel.receiverName,
                        style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Đang gọi...",
                        style: TextStyle(fontSize: 16, color: Colors.white54),
                      ),
                      SizedBox(height: 100),
                      FloatingActionButton(
                        onPressed: () => viewModel.onCancelCall(context), // Hủy cuộc gọi
                        backgroundColor: Colors.red,
                        child: Icon(Icons.call_end, color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}