
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

// === IMPORT CHO SMART REPLY ===
import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
// ===============================

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

  // === BIẾN CHO SMART REPLY ===
  
  // Gemini API Key
  static const String _geminiApiKey = 'AIzaSyDVjQT-ETmjX4ZvXqas3bnFzju5UXOANlE';
  
  // Gemini Model
  GenerativeModel? _geminiModel;
  
  // ML Kit Smart Reply (fallback)
  final SmartReply _smartReply = SmartReply();
  
  // Danh sách gợi ý
  List<String> _smartReplies = [];
  List<String> get smartReplies => _smartReplies;

  // Tránh xử lý lặp
  String? _lastProcessedMessageId;

  // ================================

  ChatViewModel({required this.chatId, this.currentUserId}) {
    messagesStream = _chatRequest.getMessages(chatId);

    // Khởi tạo Gemini AI
    try {
      _geminiModel = GenerativeModel(
        model: 'gemini-2.5-flash', // Model mới nhất của Google
        apiKey: _geminiApiKey,
      );
      if (kDebugMode) print('✅ [Gemini] Đã khởi tạo Gemini AI (gemini-2.5-flash)');
    } catch (e) {
      if (kDebugMode) print('⚠️ [Gemini] Không thể khởi tạo: $e');
    }

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

  // ============================================================
  // SMART REPLY - HỖ TRỢ TIẾNG VIỆT VỚI GEMINI AI
  // ============================================================

  Future<void> generateReplies(List<MessageModel> messages) async {
    if (kDebugMode) {
      print('🔍 [SmartReply] generateReplies được gọi với ${messages.length} tin nhắn');
      print('🔍 [SmartReply] isGroup: $isGroup, isBlocked: $isBlocked');
    }

    // 1. Chỉ hoạt động với chat 1-1 và không bị chặn
    if (isGroup) {
      if (kDebugMode) print('⚠️ [SmartReply] Bỏ qua vì đây là group chat');
      if (_smartReplies.isNotEmpty) {
        _smartReplies = [];
        notifyListeners();
      }
      return;
    }

    if (isBlocked) {
      if (kDebugMode) print('⚠️ [SmartReply] Bỏ qua vì bị chặn');
      if (_smartReplies.isNotEmpty) {
        _smartReplies = [];
        notifyListeners();
      }
      return;
    }

    if (messages.isEmpty) {
      if (kDebugMode) print('⚠️ [SmartReply] Không có tin nhắn');
      return;
    }

    final lastMessage = messages.first;
    if (lastMessage.id == _lastProcessedMessageId) {
      if (kDebugMode) print('⚠️ [SmartReply] Tin nhắn đã được xử lý: ${lastMessage.id}');
      return;
    }

    if (kDebugMode) {
      print('📩 [SmartReply] Tin nhắn cuối:');
      print('   - ID: ${lastMessage.id}');
      print('   - Content: ${lastMessage.content}');
      print('   - SenderId: ${lastMessage.senderId}');
      print('   - CurrentUserId: $currentUserId');
    }

    // 2. Chỉ tạo gợi ý nếu tin nhắn cuối là từ người khác
    if (lastMessage.senderId == currentUserId) {
      if (kDebugMode) print('⚠️ [SmartReply] Tin nhắn cuối là của mình, xóa gợi ý');
      if (_smartReplies.isNotEmpty) {
        _smartReplies = [];
        notifyListeners();
      }
      return;
    }
    
    _lastProcessedMessageId = lastMessage.id;
    if (kDebugMode) print('✅ [SmartReply] Bắt đầu xử lý tin nhắn mới');

    // 3. Thử Gemini AI trước (hỗ trợ tiếng Việt)
    if (_geminiModel != null) {
      await _generateRepliesWithGemini(messages);
    } else {
      // Fallback: ML Kit (chỉ tiếng Anh)
      await _generateRepliesWithMLKit(messages);
    }
  }

  // ============================================================
  // GEMINI AI - HỖ TRỢ TIẾNG VIỆT
  // ============================================================

  Future<void> _generateRepliesWithGemini(List<MessageModel> messages) async {
    try {
      if (kDebugMode) print('🤖 [Gemini] Bắt đầu tạo gợi ý với Gemini AI...');

      // Lấy 10 tin nhắn gần nhất
      final recentMessages = messages.take(10).toList().reversed.toList();
      final conversationText = recentMessages
          .where((m) => 
              m.content.isNotEmpty && 
              m.type == 'text' &&
              m.status != 'recalled' && 
              m.status != 'deleted')
          .map((m) {
            final speaker = m.senderId == currentUserId ? 'Tôi' : 'Bạn';
            return '$speaker: ${m.content}';
          })
          .join('\n');

      if (conversationText.isEmpty) {
        if (kDebugMode) print('⚠️ [Gemini] Không có tin nhắn văn bản hợp lệ');
        _smartReplies = [];
        notifyListeners();
        return;
      }

      if (kDebugMode) print('📝 [Gemini] Hội thoại:\n$conversationText');

      // Tạo prompt
      final prompt = '''
Dựa vào cuộc hội thoại sau, hãy đề xuất 3 câu trả lời ngắn gọn và tự nhiên (tối đa 8 từ mỗi câu).
Câu trả lời phải phù hợp với ngữ cảnh và văn phong của người dùng.

Trả về ĐÚNG định dạng JSON này, KHÔNG thêm markdown hay giải thích:
{"replies": ["câu trả lời 1", "câu trả lời 2", "câu trả lời 3"]}

Hội thoại:
$conversationText
''';

      // Gọi API Gemini
      final content = [Content.text(prompt)];
      final response = await _geminiModel!.generateContent(content);
      
      if (kDebugMode) print('📥 [Gemini] Nhận được response');

      final responseText = response.text ?? '';
      if (responseText.isEmpty) {
        if (kDebugMode) print('⚠️ [Gemini] Response rỗng, chuyển sang ML Kit');
        await _generateRepliesWithMLKit(messages);
        return;
      }

      if (kDebugMode) print('📄 [Gemini] Raw response: $responseText');

      // Parse JSON
      final jsonText = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      try {
        final jsonResult = jsonDecode(jsonText);
        _smartReplies = List<String>.from(jsonResult['replies'] ?? []);

        if (_smartReplies.isEmpty) {
          if (kDebugMode) print('⚠️ [Gemini] Không có gợi ý, chuyển sang ML Kit');
          await _generateRepliesWithMLKit(messages);
          return;
        }

        if (kDebugMode) {
          print('✅ [Gemini] Thành công! ${_smartReplies.length} gợi ý');
          print('📋 [Gemini] Gợi ý: $_smartReplies');
        }

      } catch (jsonError) {
        if (kDebugMode) {
          print('❌ [Gemini] Lỗi parse JSON: $jsonError');
          print('📄 [Gemini] Text cần parse: $jsonText');
        }
        await _generateRepliesWithMLKit(messages);
        return;
      }

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [Gemini] Lỗi: $e');
        print('📍 [Gemini] StackTrace: $stackTrace');
      }
      
      // Fallback sang ML Kit
      if (kDebugMode) print('🔄 [Gemini] Chuyển sang ML Kit...');
      await _generateRepliesWithMLKit(messages);
      return;
    }

    notifyListeners();
    if (kDebugMode) print('🎨 [SmartReply] UI được cập nhật với ${_smartReplies.length} gợi ý');
  }

  // ============================================================
  // ML KIT - FALLBACK CHO TIẾNG ANH
  // ============================================================

  Future<void> _generateRepliesWithMLKit(List<MessageModel> messages) async {
    if (kDebugMode) print('🤖 [ML Kit] Bắt đầu tạo gợi ý với ML Kit...');

    _smartReply.clearConversation();
    
    final reversedMessages = messages.reversed.toList();
    final recentMessages = reversedMessages.take(20).toList();
    
    int addedCount = 0;
    for (var message in recentMessages) {
      if (message.content.isEmpty) continue;
      if (message.status == 'recalled' || message.status == 'deleted') continue;
      if (message.type == 'call_audio' || 
          message.type == 'call_video' || 
          message.type == 'share_post' ||
          message.type == 'share_group_qr') continue;
      
      final timestamp = message.createdAt.millisecondsSinceEpoch;
      final isLocalUser = message.senderId == currentUserId;
      
      if (isLocalUser) {
        _smartReply.addMessageToConversationFromLocalUser(
          message.content, 
          timestamp
        );
      } else {
        _smartReply.addMessageToConversationFromRemoteUser(
          message.content, 
          timestamp, 
          message.senderId
        );
      }
      
      addedCount++;
    }

    if (kDebugMode) print('📝 [ML Kit] Đã thêm $addedCount tin nhắn');

    if (addedCount < 2) {
      if (kDebugMode) print('⚠️ [ML Kit] Cần ít nhất 2 tin nhắn');
      _smartReplies = [];
      notifyListeners();
      return;
    }

    try {
      if (kDebugMode) print('🔄 [ML Kit] Đang gọi suggestReplies()...');
      
      final result = await _smartReply.suggestReplies();

      if (kDebugMode) {
        print('📊 [ML Kit] Kết quả:');
        print('   - Status: ${result.status}');
        print('   - Suggestions: ${result.suggestions}');
      }

      if (result.status == SmartReplySuggestionResultStatus.success) {
        _smartReplies = result.suggestions;
        if (kDebugMode) print('✅ [ML Kit] Thành công! ${_smartReplies.length} gợi ý');
      } else if (result.status == SmartReplySuggestionResultStatus.notSupportedLanguage) {
        _smartReplies = [];
        if (kDebugMode) print('⚠️ [ML Kit] Ngôn ngữ không được hỗ trợ');
      } else {
        _smartReplies = [];
        if (kDebugMode) print('⚠️ [ML Kit] Không có gợi ý');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [ML Kit] Lỗi: $e');
        print('📍 [ML Kit] StackTrace: $stackTrace');
      }
      _smartReplies = [];
    }

    notifyListeners();
    if (kDebugMode) print('🎨 [SmartReply] UI được cập nhật với ${_smartReplies.length} gợi ý');
  }

  // ============================================================
  // CHỌN GỢI Ý
  // ============================================================

  void selectReply(String replyText) {
    messageController.text = replyText;
    messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: replyText.length),
    );
    
    _smartReplies = [];
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

  void startAudioCall(BuildContext context) => _startCall(context, CallMediaType.audio);
  void startVideoCall(BuildContext context) => _startCall(context, CallMediaType.video);

  @override
  void dispose() {
    messageController.dispose();
    _smartReply.close();
    super.dispose();
  }
}