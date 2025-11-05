
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

class ChatViewModel extends ChangeNotifier {
  final String chatId;
  final String? currentUserId; // Custom user ID hoặc Document ID
  final ChatRequest _chatRequest = ChatRequest();
  final StorageRequest _storageRequest = StorageRequest();
  late Stream<List<MessageModel>> messagesStream;

  // Text controller
  final TextEditingController messageController = TextEditingController();

  // Media selection
  List<XFile> _selectedMedia = [];
  List<XFile> get selectedMedia => _selectedMedia;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error state
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Call state
  bool isGroup = true;
  UserModel? receiverUser;

  ChatViewModel({required this.chatId, this.currentUserId}) {
    messagesStream = _chatRequest.getMessages(chatId);
    
    if (currentUserId != null) {
      _loadChatInfo();
    }
  }

  // ===== LOAD CHAT INFO =====
  void _loadChatInfo() async {
    print("🔍 [CALL DEBUG] Bắt đầu _loadChatInfo cho chatId: $chatId");
    try {
      final doc = await FirebaseFirestore.instance.collection('Chat').doc(chatId).get();
      print("🔍 [CALL DEBUG] Document exists: ${doc.exists}");
      
      if (doc.exists) {
        final chatData = doc.data() as Map<String, dynamic>;
        print("🔍 [CALL DEBUG] Chat data: $chatData");
        
        // Kiểm tra type
        String chatType = chatData['type'] ?? 'group';
        isGroup = (chatType == 'group');
        print("🔍 [CALL DEBUG] isGroup: $isGroup, chatType: $chatType");

        if (!isGroup && currentUserId != null) {
          // Lấy danh sách members
          List<String> members = List<String>.from(chatData['members'] ?? []);
          print("🔍 [CALL DEBUG] Members: $members");
          print("🔍 [CALL DEBUG] CurrentUserId: $currentUserId");
          
          // Tìm member còn lại (không phải currentUserId)
          String? receiverCustomId = members.firstWhere( 
            (id) => id != currentUserId,
            orElse: () => '', 
          );
          print("🔍 [CALL DEBUG] ReceiverCustomId tìm được: $receiverCustomId");

          if (receiverCustomId.isNotEmpty) {
            // Lấy thông tin user
            receiverUser = await UserRequest().getUserData(receiverCustomId);
            
            if (receiverUser != null) {
              print("✅ [CALL DEBUG] ReceiverUser loaded:");
              print("   - Name: ${receiverUser!.name}");
              print("   - UID: ${receiverUser!.uid}");
              print("   - ID: ${receiverUser!.id}");
            } else {
              print("❌ [CALL DEBUG] Không tìm thấy receiverUser");
            }
          } else {
            print("❌ [CALL DEBUG] ReceiverCustomId rỗng!");
          }
        } else {
          print("⚠️ [CALL DEBUG] Đây là nhóm hoặc currentUserId null");
        }
      } else {
        print("❌ [CALL DEBUG] Document không tồn tại!");
      }
    } catch (e) {
      print("❌ [CALL DEBUG] Lỗi _loadChatInfo: $e");
      _setError("Không thể tải thông tin cuộc trò chuyện.");
    }
    notifyListeners(); 
  }

  // ===== HELPER FUNCTIONS =====
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

  // ===== MEDIA PICKER =====
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
          _setError('Bạn chỉ có thể chọn thêm $remainingSlots tệp. Đã lấy $remainingSlots tệp đầu tiên.');
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

  // ===== MESSAGE ACTIONS =====
  Future<void> markAsSeen(String messageId) async {
    try {
      // Lấy thông tin tin nhắn trước khi cập nhật
      final doc = await FirebaseFirestore.instance
          .collection('Chat')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();
      
      if (!doc.exists) return;
      
      final messageData = doc.data() as Map<String, dynamic>;
      final currentStatus = messageData['status'] as String?;
      
      // CHỈ cập nhật nếu status KHÔNG phải là 'recalled' hoặc 'deleted'
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

  // ===== SEND MESSAGE =====
  Future<void> sendMessage() async {
    final String content = messageController.text.trim();
    
    if (currentUserId == null) {
      _setError("Lỗi: Không tìm thấy người dùng.");
      return;
    }
    
    if (content.isEmpty && _selectedMedia.isEmpty) {
      return;
    }

    _setLoading(true);
    _clearError();

    List<String> mediaIds = [];
    
    try {
      // 1. Upload media nếu có
      if (_selectedMedia.isNotEmpty) {
        final List<File> filesToUpload = _selectedMedia.map((xfile) => File(xfile.path)).toList();
        mediaIds = await _storageRequest.uploadFilesAndCreateMedia(
          filesToUpload,
          currentUserId!,
        );
      }

      // 2. Tạo MessageModel
      final message = MessageModel(
        id: '',
        senderId: currentUserId!,
        content: content,
        createdAt: DateTime.now(),
        mediaIds: mediaIds,
        status: 'sent',
        type: 'text',
      );

      // 3. Gửi tin nhắn
      await _chatRequest.sendMessage(chatId, message);

      // 4. Xóa input
      _selectedMedia.clear();
      messageController.clear();
      
    } catch (e) {
      _setError('Gửi tin nhắn thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ===== CALL FUNCTIONS =====
  Future<void> _startCall(BuildContext context, CallMediaType mediaType) async {
    print("📞 [CALL DEBUG] _startCall được gọi với mediaType: $mediaType");
    print("📞 [CALL DEBUG] isGroup: $isGroup");
    print("📞 [CALL DEBUG] receiverUser: ${receiverUser?.name}");
    
    // Kiểm tra xem đã load xong info chưa
    if (receiverUser == null && !isGroup) { 
      print("❌ [CALL DEBUG] receiverUser = null, không thể gọi");
      _setError("Không thể gọi. Vui lòng thử lại sau giây lát.");
      return;
    }
    
    // Kiểm tra có phải 1-1 không
    if (isGroup) {
      print("❌ [CALL DEBUG] Đây là nhóm, chưa hỗ trợ");
      _setError("Chức năng gọi nhóm chưa được hỗ trợ.");
      return;
    }

    print("📞 [CALL DEBUG] Bắt đầu tạo cuộc gọi...");
    
    try {
      final callService = context.read<CallService>();
      print("📞 [CALL DEBUG] CallService lấy thành công");
      
      // Tạo cuộc gọi
      final call = await callService.makeOneToOneCall(receiverUser!, mediaType);
      print("📞 [CALL DEBUG] Call được tạo: ${call?.id}");

      if (call != null && context.mounted) {
        print("📞 [CALL DEBUG] Điều hướng đến OutgoingCallScreen");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OutgoingCallScreen(call: call),
          ),
        );
      } else {
        print("❌ [CALL DEBUG] Call = null hoặc context không mounted");
        if (call == null) {
          _setError("Không thể tạo cuộc gọi. Vui lòng thử lại.");
        }
      }
    } catch (e) {
      print("❌ [CALL DEBUG] Lỗi khi tạo cuộc gọi: $e");
      _setError("Lỗi khi tạo cuộc gọi: $e");
    }
  }

  void startAudioCall(BuildContext context) {
    print("🎤 [CALL DEBUG] startAudioCall được gọi");
    _startCall(context, CallMediaType.audio);
  }

  void startVideoCall(BuildContext context) {
    print("📹 [CALL DEBUG] startVideoCall được gọi");
    _startCall(context, CallMediaType.video);
  }

  // ===== DISPOSE =====
  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}