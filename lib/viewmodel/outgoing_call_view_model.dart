
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/view/call/ongoing_call_screen.dart';
import 'package:mangxahoi/services/sound_service.dart';

class OutgoingCallViewModel extends ChangeNotifier {
  final CallService callService;
  final CallModel call;
  final SoundService soundService;

  String receiverName = "Đang tải...";
  String receiverAvatar = "";
  bool _isWaiting = true; // Cờ để tránh xử lý điều hướng nhiều lần

  StreamSubscription<DocumentSnapshot>? _callStatusSubscription;

  OutgoingCallViewModel({
    required this.call,
    required this.callService,
    required this.soundService,
  }) {
    _loadReceiverInfo();
  }

  // Hàm khởi tạo, gọi từ View để bắt đầu lắng nghe
  void init(BuildContext context) {
    _listenToCallStatus(context);
  }

  void _loadReceiverInfo() async {
    String receiverId = call.receiverIds.first;
    UserModel? user = await UserRequest().getUserByUid(receiverId);

    if (user != null) {
      receiverName = user.name;
      receiverAvatar = user.avatar.isNotEmpty ? user.avatar.first : "";
      notifyListeners();
    }
  }

  void _listenToCallStatus(BuildContext context) {
    _callStatusSubscription?.cancel();
    _callStatusSubscription = callService.getCallStatusStream(call.id).listen((snapshot) async {
      if (!snapshot.exists || !context.mounted || !_isWaiting) return;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      String status = data['status'];

      if (status == CallStatus.accepted.name) {
        _isWaiting = false;
        _callStatusSubscription?.cancel();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OngoingCallScreen(call: call)),
        );
      } else if (status == CallStatus.declined.name || status == CallStatus.ended.name) {
        _isWaiting = false;
        _callStatusSubscription?.cancel();

        await soundService.playEndCall();
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  Future<void> onCancelCall(BuildContext context) async {
    if (!_isWaiting) return;
    _isWaiting = false;
    _callStatusSubscription?.cancel();

    await soundService.playEndCall();
    await callService.rejectOrCancelCall(call);

    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _callStatusSubscription?.cancel();
    super.dispose();
  }
}