import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'package:mangxahoi/model/model_call.dart';

import 'package:mangxahoi/model/model_user.dart';

import 'package:mangxahoi/services/call_service.dart';

import 'package:mangxahoi/request/user_request.dart';

import 'package:mangxahoi/view/call/ongoing_call_screen.dart';



class OutgoingCallViewModel extends ChangeNotifier {

  final CallService callService;

  final CallModel call;

  

  String receiverName = "Đang tải...";

  String receiverAvatar = "";

  

  StreamSubscription<DocumentSnapshot>? _callStatusSubscription;



  OutgoingCallViewModel({required this.call, required this.callService}) {

    _loadReceiverInfo();

  }



  void _loadReceiverInfo() async {

    String receiverId = call.receiverIds.first; // Đây là Auth UID

    

    // ▼▼▼ SỬA LỖI 5: Đổi tên hàm cho đúng ▼▼▼

    // UserRequest().getUserByAuthUid(receiverId) 

    // thành -> UserRequest().getUserByUid(receiverId)

    UserModel? user = await UserRequest().getUserByUid(receiverId); // Dùng hàm bạn đã cung cấp

    

    if (user != null) {

      receiverName = user.name;

      receiverAvatar = user.avatar.isNotEmpty ? user.avatar.first : "";

      notifyListeners();

    }

  }

  

  void setCallStatusSubscription(StreamSubscription<DocumentSnapshot> subscription) {

    _callStatusSubscription = subscription;

  }



  Future<void> onCancelCall(BuildContext context) async {

    await callService.rejectOrCancelCall(call);

    _callStatusSubscription?.cancel();

    Navigator.pop(context);

  }

  

  void handleNavigation(BuildContext context, CallStatus status) {

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (status == CallStatus.accepted) {

        _callStatusSubscription?.cancel();

        Navigator.pushReplacement(

          context,

          MaterialPageRoute(builder: (_) => OngoingCallScreen(call: call)),

        );

      } else if (status == CallStatus.declined || status == CallStatus.ended) {

        _callStatusSubscription?.cancel();

        if (Navigator.canPop(context)) {

          Navigator.pop(context);

        }

      }

    });

  }



  @override

  void dispose() {

    _callStatusSubscription?.cancel();

    super.dispose();

  }

}