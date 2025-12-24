
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/request/chat_request.dart';
import 'package:mangxahoi/request/storage_request.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/model/model_call.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/view/call/outgoing_call_screen.dart';
import 'package:mangxahoi/request/friend_request_manager.dart';
import 'package:mangxahoi/services/smartreply.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';

class ChatViewModel extends ChangeNotifier {
  final String chatId;
  final String? currentUserId;
  final ChatRequest _chatRequest = ChatRequest();
  final StorageRequest _storageRequest = StorageRequest();
  final FriendRequestManager _friendRequestManager = FriendRequestManager();
  bool _isGeneratingReplies = false;           // ← THÊM DÒNG NÀY
String? _lastProcessedMessageIdForGeneration; // ← (tùy chọn, càng tốt hơn)

  late Stream<List<MessageModel>> messagesStream;

  final TextEditingController messageController = TextEditingController();

  List<XFile> _selectedMedia = [];
  List<XFile> get selectedMedia => _selectedMedia;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool isGroup = true;
  UserModel? receiverUser;

  // Trạng thái chặn
  bool isBlocked = false;
  String? blockedBy;

  // Smart Reply Service
  late SmartReplyService _smartReplyService;
  List<String> get smartReplies => _smartReplyService.smartReplies;
  
  // Biến flag để tránh gọi generateReplies liên tục
  //bool _isGeneratingReplies = false;

  ChatViewModel({required this.chatId, this.currentUserId}) {
    messagesStream = _chatRequest.getMessages(chatId);

    // Khởi tạo Smart Reply Service
    _smartReplyService = SmartReplyService(currentUserId: currentUserId);

    if (currentUserId != null) {
      _loadChatInfo();
    }
  }

  void _loadChatInfo() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Chat').doc(chatId).get();

      if (doc.exists) {
        final chatData = doc.data() as Map<String, dynamic>;
        String chatType = chatData['type'] ?? 'group';
        isGroup = (chatType == 'group');

        if (!isGroup && currentUserId != null) {
          List<String> members = List<String>.from(chatData['members'] ?? []);
          String? receiverCustomId = members.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );

          if (receiverCustomId.isNotEmpty) {
            receiverUser = await UserRequest().getUserData(receiverCustomId);
            if (receiverUser != null) {
              await _checkBlockedStatus();
            }
          }
        }
      }
    } catch (e) {
      print("❌ Lỗi _loadChatInfo: $e");
      _setError("Không thể tải thông tin cuộc trò chuyện.");
    }
    notifyListeners();
  }

  Future<void> pickFile() async {
  _clearError();
  // Giới hạn số lượng tệp (nếu muốn dùng chung logic tối đa 3 tệp với media)
  if (_selectedMedia.length >= 3) {
    _setError('Bạn chỉ có thể chọn tối đa 3 tệp.');
    return;
  }

  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Cho phép chọn mọi định dạng file
      allowMultiple: false, 
    );

    if (result != null && result.files.single.path != null) {
      PlatformFile file = result.files.first;

      // Kiểm tra dung lượng (100MB = 100 * 1024 * 1024 bytes)
      const int maxFileSize = 100 * 1024 * 1024;
      if (file.size > maxFileSize) {
        _setError('Dung lượng file không được vượt quá 100MB.');
        return;
      }

      // Chuyển đổi PlatformFile sang XFile để tương thích với danh sách _selectedMedia hiện có
      // Lưu ý: Logic gửi của bạn đang dùng XFile để upload qua _storageRequest
      _selectedMedia.add(XFile(file.path!));
      notifyListeners();
    }
  } catch (e) {
    _setError('Lỗi khi chọn file: $e');
  }
}

  Future<void> _checkBlockedStatus() async {
    if (currentUserId == null || receiverUser == null) return;
    try {
      final status = await _friendRequestManager.checkBlockedStatus(
          currentUserId!, receiverUser!.id);
      isBlocked = status['isBlocked'];
      blockedBy = status['blockedBy'];
      notifyListeners();
    } catch (e) {
      print("⚠️ Lỗi kiểm tra chặn trong ChatViewModel: $e");
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> pickImages() async {
    _clearError();
    if (_selectedMedia.length >= 3) {
      _setError('Bạn chỉ có thể chọn tối đa 3 tệp.');
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        int remainingSlots = 3 - _selectedMedia.length;
        if (pickedFiles.length > remainingSlots) {
          _setError('Bạn chỉ có thể chọn thêm $remainingSlots tệp.');
          _selectedMedia.addAll(pickedFiles.take(remainingSlots));
        } else {
          _selectedMedia.addAll(pickedFiles);
        }
        notifyListeners();
      }
    } catch (e) {
      _setError('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> pickVideo() async {
    _clearError();
    if (_selectedMedia.length >= 3) {
      _setError('Bạn chỉ có thể chọn tối đa 3 tệp.');
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedVideo = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedVideo != null) {
        _setLoading(true);
        final videoFile = File(pickedVideo.path);
        final VideoPlayerController controller = VideoPlayerController.file(videoFile);
        await controller.initialize();
        final durationInSeconds = controller.value.duration.inSeconds;
        await controller.dispose();
        _setLoading(false);

        if (durationInSeconds > 30) {
          _setError('Video không được vượt quá 30 giây.');
          return;
        }
        _selectedMedia.add(pickedVideo);
        notifyListeners();
      }
    } catch (e) {
      _setLoading(false);
      _setError('Lỗi khi chọn video: $e');
    }
  }

  void removeMedia(XFile file) {
    _selectedMedia.remove(file);
    notifyListeners();
  }

  Future<void> markAsSeen(String messageId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Chat')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();
      if (!doc.exists) return;
      final messageData = doc.data() as Map<String, dynamic>;
      final currentStatus = messageData['status'] as String?;
      if (currentStatus != 'recalled' && currentStatus != 'deleted') {
        await _chatRequest.updateMessageStatus(chatId, messageId, 'seen');
      }
    } catch (e) {
      print('❌ Lỗi khi đánh dấu tin nhắn đã xem: $e');
    }
  }

  Future<void> recallMessage(String messageId) async {
    await _chatRequest.recallMessage(chatId, messageId);
  }

  Future<void> deleteMessage(String messageId) async {
    await _chatRequest.deleteMessage(chatId, messageId);
  }

  Future<void> sendMessage() async {
  if (isBlocked) {
    _setError("Bạn không thể gửi tin nhắn do đang bị chặn.");
    return;
  }
  final String content = messageController.text.trim();
  if (currentUserId == null) {
    _setError("Lỗi: Không tìm thấy người dùng.");
    return;
  }
  if (content.isEmpty && _selectedMedia.isEmpty) return;

  _setLoading(true);
  _clearError();
  List<String> mediaIds = [];
  
  try {
    if (_selectedMedia.isNotEmpty) {
      final List<File> filesToUpload = _selectedMedia.map((xfile) => File(xfile.path)).toList();
      mediaIds = await _storageRequest.uploadFilesAndCreateMedia(filesToUpload, currentUserId!);
    }
    
    // ✅ TẠO MESSAGE VỚI DateTime.now() (CHỈ ĐỂ HIỂN THỊ TẠM)
    final message = MessageModel(
      id: '',
      senderId: currentUserId!,
      content: content,
      createdAt: DateTime.now(), // ← Sẽ bị ghi đè bởi server timestamp
      mediaIds: mediaIds,
      status: 'sent',
      type: 'text',
    );
    
    // ✅ GỌI sendMessage() - BÊN TRONG SẼ DÙNG FieldValue.serverTimestamp()
    await _chatRequest.sendMessage(chatId, message);
    
    _selectedMedia.clear();
    messageController.clear();
  } catch (e) {
    _setError('Gửi tin nhắn thất bại: $e');
  } finally {
    _setLoading(false);
  }
}

  // ============================================================
  // SMART REPLY
  // ============================================================

  // CẬP NHẬT HÀM NÀY
  Future<void> generateReplies(List<MessageModel> messages, bool isGeminiEnabled) async {
    
    // 1. KIỂM TRA ĐIỀU KIỆN NGAY ĐẦU HÀM
    if (!isGeminiEnabled) {
      // Nếu user tắt tính năng, đảm bảo xóa sạch gợi ý cũ (nếu có) để không hiển thị rác
      if (_smartReplyService.smartReplies.isNotEmpty) {
        _smartReplyService.clearReplies();
        notifyListeners();
      }
      return; // Dừng lại, không gọi AI
    }

    // 2. Các logic kiểm tra cũ (giữ nguyên)
    if (messages.isEmpty) return;
    final lastMessage = messages.first;

    if (lastMessage.senderId == currentUserId || 
        lastMessage.id == _lastProcessedMessageIdForGeneration || 
        isGroup || 
        isBlocked) {
      return;
    }

    // 3. Bắt đầu tạo gợi ý (giữ nguyên)
    _isGeneratingReplies = true;
    _lastProcessedMessageIdForGeneration = lastMessage.id;

    try {
      await _smartReplyService.generateReplies(
        messages: messages,
        isGroup: isGroup,
        isBlocked: isBlocked,
      );
    } finally {
      _isGeneratingReplies = false;
      notifyListeners();
    }
  }

  void selectReply(String replyText) {
    messageController.text = replyText;
    messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: replyText.length),
    );
    
    _smartReplyService.clearReplies();
    notifyListeners();
  }

  // ============================================================
  // CUỘC GỌI
  // ============================================================

  Future<void> _startCall(BuildContext context, CallMediaType mediaType) async {
    if (isBlocked) {
      _setError("Không thể thực hiện cuộc gọi.");
      return;
    }
    if (receiverUser == null && !isGroup) {
      _setError("Không thể gọi. Vui lòng thử lại sau giây lát.");
      return;
    }
    if (isGroup) {
      _setError("Chức năng gọi nhóm chưa được hỗ trợ.");
      return;
    }
    try {
      final callService = context.read<CallService>();
      final call = await callService.makeOneToOneCall(receiverUser!, mediaType, chatId);
      if (call != null && context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OutgoingCallScreen(call: call)));
      } else if (call == null) {
        _setError("Không thể tạo cuộc gọi. Vui lòng thử lại.");
      }
    } catch (e) {
      _setError("Lỗi khi tạo cuộc gọi: $e");
    }
  }

  // ============================================================
  // Google map - CHIA SẺ VỊ TRÍ HIỆN TẠI
  // ============================================================
  Future<void> sendCurrentLocation() async {
    if (isBlocked) {
      _setError("Bạn không thể gửi tin nhắn do đang bị chặn.");
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // 1. Kiểm tra quyền và dịch vụ vị trí
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Dịch vụ vị trí chưa được bật.');
        _setLoading(false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Quyền truy cập vị trí bị từ chối.');
          _setLoading(false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt.');
        _setLoading(false);
        return;
      }

      // 2. Lấy vị trí hiện tại
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Tạo nội dung tin nhắn dạng "latitude,longitude"
      String locationContent = "${position.latitude},${position.longitude}";

      // 4. Tạo MessageModel
      final message = MessageModel(
        id: '',
        senderId: currentUserId!,
        content: locationContent, // Lưu tọa độ vào content
        createdAt: DateTime.now(),
        mediaIds: [],
        status: 'sent',
        type: 'location', // Đặt loại tin nhắn mới là location
      );

      // 5. Gửi tin nhắn
      await _chatRequest.sendMessage(chatId, message);

    } catch (e) {
      _setError('Lỗi khi chia sẻ vị trí: $e');
    } finally {
      _setLoading(false);
    }
  }

  void startAudioCall(BuildContext context) => _startCall(context, CallMediaType.audio);
  void startVideoCall(BuildContext context) => _startCall(context, CallMediaType.video);

  @override
  void dispose() {
    messageController.dispose();
    _smartReplyService.dispose();
    super.dispose();
  }
}