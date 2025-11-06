
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

class ChatViewModel extends ChangeNotifier {
  final String chatId;
  final String? currentUserId;
  final ChatRequest _chatRequest = ChatRequest();
  final StorageRequest _storageRequest = StorageRequest();
  final FriendRequestManager _friendRequestManager = FriendRequestManager();

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

  ChatViewModel({required this.chatId, this.currentUserId}) {
    messagesStream = _chatRequest.getMessages(chatId);

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
      final message = MessageModel(
        id: '',
        senderId: currentUserId!,
        content: content,
        createdAt: DateTime.now(),
        mediaIds: mediaIds,
        status: 'sent',
        type: 'text',
      );
      await _chatRequest.sendMessage(chatId, message);
      _selectedMedia.clear();
      messageController.clear();
    } catch (e) {
      _setError('Gửi tin nhắn thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }

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
      final call = await callService.makeOneToOneCall(receiverUser!, mediaType);
      if (call != null && context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OutgoingCallScreen(call: call)));
      } else if (call == null) {
        _setError("Không thể tạo cuộc gọi. Vui lòng thử lại.");
      }
    } catch (e) {
      _setError("Lỗi khi tạo cuộc gọi: $e");
    }
  }

  void startAudioCall(BuildContext context) => _startCall(context, CallMediaType.audio);
  void startVideoCall(BuildContext context) => _startCall(context, CallMediaType.video);

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}