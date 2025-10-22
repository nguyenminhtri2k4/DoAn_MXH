
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/request/chat_request.dart';
import 'package:mangxahoi/request/storage_request.dart';
import 'package:video_player/video_player.dart';
// import 'package:mangxahoi/services/user_service.dart'; // Sẽ lấy userId từ view

class ChatViewModel extends ChangeNotifier {
  final String chatId;
  final String? currentUserId; // Nhận
  final ChatRequest _chatRequest = ChatRequest();
  final StorageRequest _storageRequest = StorageRequest();
  late Stream<List<MessageModel>> messagesStream;

  // --- Logic cũ của bạn ---
  final TextEditingController messageController = TextEditingController();

  // --- Logic mới để gửi media ---
  List<XFile> _selectedMedia = [];
  List<XFile> get selectedMedia => _selectedMedia;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  // -------------------------

  ChatViewModel({required this.chatId, this.currentUserId}) {
    messagesStream = _chatRequest.getMessages(chatId);
  }

  // --- Các hàm xử lý media (mới) ---
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
  // --- Hết hàm media ---


  // --- Các hàm cũ của bạn (từ chat_view.dart) ---
  Future<void> markAsSeen(String messageId) async {
    await _chatRequest.updateMessageStatus(chatId, messageId, 'seen');
  }

  Future<void> recallMessage(String messageId) async {
    await _chatRequest.recallMessage(chatId, messageId);
  }

  Future<void> deleteMessage(String messageId) async {
    await _chatRequest.deleteMessage(chatId, messageId);
  }
  // --- Hết hàm cũ ---

  // --- Hàm sendMessage (Nâng cấp) ---
  Future<void> sendMessage() async {
    final String content = messageController.text.trim();
    
    if (currentUserId == null) {
       _setError("Lỗi: Không tìm thấy người dùng.");
       return;
    }
    
    // Không gửi nếu không có text VÀ không có media
    if (content.isEmpty && _selectedMedia.isEmpty) {
      return;
    }

    _setLoading(true);
    _clearError();

    List<String> mediaIds = [];
    
    try {
      // 1. Tải lên media nếu có
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
        type: 'text', // Giữ là 'text', UI sẽ tự render media
      );

      // 3. Gửi tin nhắn
      await _chatRequest.sendMessage(chatId, message);

      // 4. Xóa text và media đã chọn
      _selectedMedia.clear();
      messageController.clear();
      
    } catch (e) {
      _setError('Gửi tin nhắn thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }
}