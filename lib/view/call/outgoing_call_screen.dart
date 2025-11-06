
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/viewmodel/outgoing_call_view_model.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/services/sound_service.dart';
import 'package:mangxahoi/constant/app_colors.dart';

class OutgoingCallScreen extends StatefulWidget {
  final CallModel call;
  const OutgoingCallScreen({Key? key, required this.call}) : super(key: key);

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  late OutgoingCallViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OutgoingCallViewModel(
      call: widget.call,
      callService: context.read<CallService>(),
      soundService: context.read<SoundService>(),
    );
    // Gọi init sau khi widget đã được dựng khung đầu tiên
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
        body: Consumer<OutgoingCallViewModel>(
          builder: (context, viewModel, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(
                      viewModel.receiverAvatar.isNotEmpty
                          ? viewModel.receiverAvatar
                          : AppColors.defaultAvatar,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    viewModel.receiverName,
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Đang gọi...",
                    style: TextStyle(fontSize: 18, color: Colors.white54),
                  ),
                  const SizedBox(height: 120),
                  FloatingActionButton(
                    heroTag: "outgoing_end_btn",
                    onPressed: () => viewModel.onCancelCall(context),
                    backgroundColor: Colors.red,
                    elevation: 8,
                    child: const Icon(Icons.call_end, color: Colors.white, size: 32),
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