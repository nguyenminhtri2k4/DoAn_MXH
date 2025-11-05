
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // <--- Thêm import này
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/utils/zegocloud_config.dart';
import 'package:mangxahoi/view/call/incoming_call_screen.dart';
import 'package:permission_handler/permission_handler.dart'; 
import 'package:zego_express_engine/zego_express_engine.dart'; 
import 'package:uuid/uuid.dart';
import 'package:mangxahoi/constant/app_colors.dart';

class CallService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _callsCollection => _firestore.collection('calls');

  String? currentUserId; // Auth UID
  UserModel? _currentUser;

  StreamSubscription<QuerySnapshot>? _incomingCallSubscription;
  CallModel? _currentCall;

  final GlobalKey<NavigatorState> navigatorKey;

  CallService({required this.navigatorKey});

  Future<void> init(UserService userService) async {
    print("🔧 [SERVICE DEBUG] ========================================");
    print("🔧 [SERVICE DEBUG] CallService.init() được gọi");
    _currentUser = userService.currentUser; 
    
    if (_currentUser == null) {
      print("❌ [SERVICE DEBUG] userService.currentUser = null");
      print("🔧 [SERVICE DEBUG] ========================================");
      return;
    }
    
    currentUserId = _currentUser!.uid;
    print("✅ [SERVICE DEBUG] CallService đã init:");
    print("   - currentUserId (Auth UID): $currentUserId");
    print("   - currentUser.name: ${_currentUser!.name}");
    
    await _initZegoEngine();
    
    print("🔧 [SERVICE DEBUG] Đang gọi listenForIncomingCalls()...");
    listenForIncomingCalls();
    print("🔧 [SERVICE DEBUG] ========================================");
  }

  Future<void> _initZegoEngine() async {
    print("🔧 [SERVICE DEBUG] Đang init ZegoEngine...");
    print("🔧 [SERVICE DEBUG] AppID: ${ZegoCloudConfig.appId}");
    print("🔧 [SERVICE DEBUG] Đang chạy trên Web? $kIsWeb");
    
    try {
      ZegoEngineProfile profile;

      // Logic kiểm tra nền tảng
      if (kIsWeb) {
        // 1. CHO WEB: KHÔNG CÓ appSign
        // Cú pháp: ZegoEngineProfile(appID, scenario)
        profile = ZegoEngineProfile(
          ZegoCloudConfig.appId,
          ZegoScenario.General,
        );
      } else {
        // 2. CHO ANDROID/iOS: BẮT BUỘC CÓ appSign (dưới dạng tham số TÊN)
        
        // ▼▼▼ SỬA LỖI 1: SỬA LỖI CÚ PHÁP SAI THỨ TỰ THAM SỐ ▼▼▼
        // Đưa tham số vị trí (Positional) ZegoScenario.General LÊN TRƯỚC
        // tham số tên (Named) appSign.
        profile = ZegoEngineProfile(
          ZegoCloudConfig.appId,     // Tham số vị trí 1
          ZegoScenario.General,      // Tham số vị trí 2
          appSign: ZegoCloudConfig.appSign, // Tham số tên (SAU CÙNG)
        );
        // ▲▲▲ KẾT THÚC SỬA LỖI 1 ▲▲▲
      }
      
      await ZegoExpressEngine.createEngineWithProfile(profile);
      print("✅ [SERVICE DEBUG] ZegoEngine đã init thành công!");

    } catch (e) {
      print("❌ [SERVICE DEBUG] Lỗi init ZegoEngine: $e");
      rethrow;
    }
  }

  // Sửa hàm _joinRoom để hỗ trợ Token cho Web
  Future<void> _joinRoom(String channelName, CallMediaType mediaType) async {
    print("📞 [SERVICE DEBUG] ========================================");
    print("📞 [SERVICE DEBUG] _joinRoom được gọi");
    
    if (currentUserId == null || _currentUser == null) {
      print("❌ [SERVICE DEBUG] currentUserId hoặc _currentUser null");
      return;
    }
    
    String validUserId = currentUserId!;
    if (validUserId.length > 64) {
      validUserId = validUserId.substring(0, 64);
    }
    
    String validChannelName = channelName;
    if (validChannelName.length > 128) {
      validChannelName = validChannelName.substring(0, 128);
    }
    
    print("📞 [SERVICE DEBUG] Validated params:");
    print("   - userId: $validUserId (${validUserId.length} chars)");
    print("   - userName: ${_currentUser!.name}");
    print("   - channelName: $validChannelName (${validChannelName.length} chars)");
    
    ZegoUser user = ZegoUser(validUserId, _currentUser!.name); 
    bool isVideoCall = (mediaType == CallMediaType.video);
    
    // Tạo config
    ZegoRoomConfig config = ZegoRoomConfig.defaultConfig();
    
    // Nếu là Web, chúng ta BẮT BUỘC phải tạo và dùng Token
    // (ZegoCloudConfig.generateToken là hàm giả định, bạn cần thay thế bằng logic tạo token thật)
    if (kIsWeb) {
       print("📞 [SERVICE DEBUG] Đang chạy trên Web, cần tạo Token...");
       // BẠN CẦN IMPLEMENT HÀM NÀY NẾU MUỐN CHẠY WEB
       // String token = ZegoCloudConfig.generateToken(validUserId, validChannelName); 
       // if (token != null) {
       //   config.token = token;
       //   print("📞 [SERVICE DEBUG] Đã gán Token cho Web");
       // } else {
       //   print("❌ [SERVICE DEBUG] KHÔNG CÓ TOKEN CHO WEB, login sẽ thất bại.");
       // }
    }
    
    try {
      print("📞 [SERVICE DEBUG] Đang gọi loginRoom...");
      await ZegoExpressEngine.instance.loginRoom(validChannelName, user, config: config);
      print("✅ [SERVICE DEBUG] loginRoom đã gọi (chờ callback)");
      
      await ZegoExpressEngine.instance.muteMicrophone(false);
      print("   ✓ Unmute mic");
      
      await ZegoExpressEngine.instance.enableCamera(isVideoCall);
      print("   ✓ Camera: $isVideoCall");
      
      await ZegoExpressEngine.instance.mutePublishStreamVideo(!isVideoCall);
      print("   ✓ Video stream: ${!isVideoCall ? 'muted' : 'unmuted'}");
      
      String streamID = '${validUserId}_stream';
      print("📞 [SERVICE DEBUG] Đang start publishing stream: $streamID");
      await ZegoExpressEngine.instance.startPublishingStream(streamID);
      
      print("✅ [SERVICE DEBUG] Join room hoàn tất!");
      print("📞 [SERVICE DEBUG] ========================================");
    } catch (e) {
      print("❌ [SERVICE DEBUG] LỖI khi join room: $e");
      print("📞 [SERVICE DEBUG] ========================================");
      rethrow; // Ném lỗi ra để makeOneToOneCall bắt được
    }
  }
  
  void listenForIncomingCalls() {
    if (currentUserId == null || currentUserId!.isEmpty) {
      print("⚠️ [SERVICE DEBUG] Không thể listen vì currentUserId null");
      return;
    }

    print("🔧 [SERVICE DEBUG] Bắt đầu listen cuộc gọi đến cho: $currentUserId");
    _incomingCallSubscription?.cancel();
    
    _incomingCallSubscription = _callsCollection
        .where('receiverIds', arrayContains: currentUserId)
        .where('status', isEqualTo: CallStatus.pending.name)
        .snapshots()
        .listen((snapshot) {
      print("📞 [LISTEN DEBUG] Nhận được ${snapshot.docs.length} cuộc gọi pending");
      
      if (snapshot.docs.isNotEmpty) {
        var callDoc = snapshot.docs.first;
        var callData = callDoc.data() as Map<String, dynamic>;
        
        CallModel incomingCall = CallModel.fromJson(callData);
        print("📞 [LISTEN DEBUG] Incoming call ID: ${incomingCall.id}");

        if (_currentCall == null) {
          _currentCall = incomingCall;
          _showIncomingCallScreen(incomingCall);
        }
      }
    }, onError: (error) {
      print("❌ [LISTEN DEBUG] Lỗi khi listen: $error");
    });
  }

  void _showIncomingCallScreen(CallModel call) {
    print("📞 [SERVICE DEBUG] Hiển thị IncomingCallScreen");
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(call: call),
      ),
    );
  }

  // ▼▼▼ SỬA LỖI 2: ĐẢO NGƯỢC THỨ TỰ LOGIC (ZEGO TRƯỚC, FIRESTORE SAU) ▼▼▼
//   Future<CallModel?> makeOneToOneCall(UserModel receiverUser, CallMediaType mediaType) async {
//     print("📞 [SERVICE DEBUG] makeOneToOneCall được gọi");
    
//     if (_currentUser == null || currentUserId == null) {
//       print("❌ [SERVICE DEBUG] currentUser hoặc currentUserId = null");
//       return null;
//     }
    
//     if (receiverUser.uid.isEmpty) {
//       print("❌ [SERVICE DEBUG] receiverUser.uid rỗng");
//       return null;
//     }
    
//     print("📞 [SERVICE DEBUG] Đang xin quyền...");
//     await _handlePermissions(mediaType);

//     String callId = Uuid().v4();
//     String channelName = "call_$callId";
    
//     CallModel call = CallModel(
//       id: callId,
//       callerId: currentUserId!,
//       callerName: _currentUser!.name,
//       callerAvatar: _currentUser!.avatar.isNotEmpty ? _currentUser!.avatar.first : '',
//       receiverIds: [receiverUser.uid],
//       status: CallStatus.pending,
//       callType: CallType.oneToOne,
//       mediaType: mediaType,
//       channelName: channelName,
//       createdAt: Timestamp.now(),
//     );

//     _currentCall = call;
    
//     try {
//       // BƯỚC 1: NGƯỜI GỌI JOIN PHÒNG ZEGO TRƯỚC
//       print("📞 [SERVICE DEBUG] Người gọi đang join room (Zego)...");
//       await _joinRoom(call.channelName, call.mediaType);
//       print("✅ [SERVICE DEBUG] Join room (Zego) thành công");
      
//       // BƯỚC 2: NẾU ZEGO THÀNH CÔNG, MỚI LƯU LÊN FIRESTORE (ĐỂ GỬI TÍN HIỆU)
//       print("📞 [SERVICE DEBUG] Đang lưu call vào Firestore...");
//       await _callsCollection.doc(call.id).set(call.toJson());
//       print("✅ [SERVICE DEBUG] Call đã lưu (Firestore) thành công");
      
//       // BƯỚC 3: Trả về call để ChatViewModel điều hướng
//       return call;

//     } catch (e) {
//       // BƯỚC 4: NẾU ZEGO THẤT BẠI (ở Bước 1)
//       print("❌ [SERVICE DEBUG] Lỗi makeOneToOneCall (Zego thất bại): $e");
//       _cleanUp(); // Dọn dẹp _currentCall vì cuộc gọi thất bại
//       return null; // Trả về null, sẽ KHÔNG ghi gì lên Firestore
//     }
//   }
  // ▲▲▲ KẾT THÚC SỬA LỖI 2 ▲▲▲
  // lib/services/call_service.dart - SỬA LẠI

Future<CallModel?> makeOneToOneCall(UserModel receiverUser, CallMediaType mediaType) async {
  print("📞 [SERVICE DEBUG] makeOneToOneCall được gọi");
  
  if (_currentUser == null || currentUserId == null) {
    print("❌ [SERVICE DEBUG] currentUser hoặc currentUserId = null");
    return null;
  }
  
  if (receiverUser.uid.isEmpty) {
    print("❌ [SERVICE DEBUG] receiverUser.uid rỗng");
    return null;
  }
  
  print("📞 [SERVICE DEBUG] Đang xin quyền...");
  await _handlePermissions(mediaType);

  String callId = Uuid().v4();
  String channelName = "call_$callId";
  
  // ▼▼▼ THÊM LINK MẶC ĐỊNH CỦA BẠN VÀO ĐÂY ▼▼▼

  CallModel call = CallModel(
    id: callId,
    callerId: currentUserId!,
    callerName: _currentUser!.name,
    
    // ▼▼▼ SỬA DÒNG NÀY ▼▼▼
    // Đảm bảo không bao giờ gửi link rỗng ""
    callerAvatar: _currentUser!.avatar.isNotEmpty 
        ? _currentUser!.avatar.first 
        : AppColors.defaultAvatar,
    // ▲▲▲ KẾT THÚC SỬA ▲▲▲

    receiverIds: [receiverUser.uid],
    status: CallStatus.pending,
    callType: CallType.oneToOne,
    mediaType: mediaType,
    channelName: channelName,
    createdAt: Timestamp.now(),
  );

  _currentCall = call;
  
  try {
    // (Toàn bộ phần try/catch giữ nguyên)
    print("📞 [SERVICE DEBUG] Người gọi đang join room (Zego)...");
    await _joinRoom(call.channelName, call.mediaType);
    print("✅ [SERVICE DEBUG] Join room (Zego) thành công");
    
    print("📞 [SERVICE DEBUG] Đang lưu call vào Firestore...");
    await _callsCollection.doc(call.id).set(call.toJson());
    print("✅ [SERVICE DEBUG] Call đã lưu (Firestore) thành công");
    
    return call;

  } catch (e) {
    print("❌ [SERVICE DEBUG] Lỗi makeOneToOneCall (Zego thất bại): $e");
    _cleanUp(); 
    return null; 
  }
}

  Future<void> acceptCall(CallModel call) async {
    print("📞 [SERVICE DEBUG] ========================================");
    print("📞 [SERVICE DEBUG] acceptCall được gọi");
    
    try {
      _currentCall = call.copyWith(status: CallStatus.accepted);
      print("📞 [SERVICE DEBUG] Đang update status sang accepted...");
      await _callsCollection
          .doc(call.id)
          .update({'status': CallStatus.accepted.name});
      print("✅ [SERVICE DEBUG] Đã update status");

      print("📞 [SERVICE DEBUG] Người nhận đang join room...");
      await _joinRoom(call.channelName, call.mediaType);
      print("✅ [SERVICE DEBUG] acceptCall hoàn tất");
      print("📞 [SERVICE DEBUG] ========================================");
    } catch (e) {
      print("❌ [SERVICE DEBUG] Lỗi acceptCall: $e");
      rethrow;
    }
  }

  Future<void> rejectOrCancelCall(CallModel call) async {
    print("📞 [SERVICE DEBUG] rejectOrCancelCall được gọi");
    CallStatus newStatus = (call.callerId == currentUserId) 
        ? CallStatus.ended
        : CallStatus.declined;

    await _callsCollection.doc(call.id).update({'status': newStatus.name});
    _cleanUp();
  }

  Future<void> endCall(CallModel call) async {
    print("📞 [SERVICE DEBUG] endCall được gọi");
    try {
      print("📞 [SERVICE DEBUG] Đang stop publishing...");
      await ZegoExpressEngine.instance.stopPublishingStream();
      
      print("📞 [SERVICE DEBUG] Đang stop preview...");
      await ZegoExpressEngine.instance.stopPreview();
      
      print("📞 [SERVICE DEBUG] Đang logout room...");
      await ZegoExpressEngine.instance.logoutRoom(call.channelName);
      
      print("📞 [SERVICE DEBUG] Đang update Firestore...");
      await _callsCollection.doc(call.id).update({'status': CallStatus.ended.name});
      
      _cleanUp();
      print("✅ [SERVICE DEBUG] endCall hoàn tất");
    } catch (e) {
      print("❌ [SERVICE DEBUG] Lỗi endCall: $e");
    }
  }

  Stream<DocumentSnapshot> getCallStatusStream(String callId) {
    return _callsCollection.doc(callId).snapshots();
  }

  void _cleanUp() {
    _currentCall = null;
  }

  Future<void> _handlePermissions(CallMediaType mediaType) async {
    if (kIsWeb) return; 

    print("📞 [SERVICE DEBUG] Đang xin quyền ${mediaType.name}...");
    try {
      if (mediaType == CallMediaType.video) {
        final statuses = await [Permission.microphone, Permission.camera].request();
        print("✅ [SERVICE DEBUG] Permissions: mic=${statuses[Permission.microphone]}, cam=${statuses[Permission.camera]}");
      } else {
        final status = await Permission.microphone.request();
        print("✅ [SERVICE DEBUG] Permission: mic=$status");
      }
    } catch (e) {
      print("❌ [SERVICE DEBUG] Lỗi xin quyền: $e");
    }
  }

  void toggleMute(bool isMuted) {
    print("📞 [SERVICE DEBUG] toggleMute: $isMuted");
    ZegoExpressEngine.instance.muteMicrophone(isMuted);
  }

  void toggleSpeaker(bool useSpeaker) {
    print("📞 [SERVICE DEBUG] toggleSpeaker: $useSpeaker");
    ZegoExpressEngine.instance.setAudioRouteToSpeaker(useSpeaker);
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    super.dispose();
  }
}