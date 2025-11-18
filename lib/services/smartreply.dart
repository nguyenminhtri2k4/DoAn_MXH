import 'package:flutter/foundation.dart';
import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:mangxahoi/model/model_message.dart';

class SmartReplyService {
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

  // Current user ID
  final String? currentUserId;

  SmartReplyService({this.currentUserId}) {
    // Khởi tạo Gemini AI
    try {
      _geminiModel = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: _geminiApiKey,
      );
      if (kDebugMode) print('✅ [Gemini] Đã khởi tạo Gemini AI (gemini-2.0-flash-exp)');
    } catch (e) {
      if (kDebugMode) print('⚠️ [Gemini] Không thể khởi tạo: $e');
    }
  }

  // ============================================================
  // SMART REPLY - HỖ TRỢ TIẾNG VIỆT VỚI GEMINI AI
  // ============================================================

  Future<List<String>> generateReplies({
    required List<MessageModel> messages,
    required bool isGroup,
    required bool isBlocked,
  }) async {
    if (kDebugMode) {
      print('🔍 [SmartReply] generateReplies được gọi với ${messages.length} tin nhắn');
      print('🔍 [SmartReply] isGroup: $isGroup, isBlocked: $isBlocked');
    }

    // 1. Chỉ hoạt động với chat 1-1 và không bị chặn
    if (isGroup) {
      if (kDebugMode) print('⚠️ [SmartReply] Bỏ qua vì đây là group chat');
      if (_smartReplies.isNotEmpty) {
        _smartReplies = [];
      }
      return _smartReplies;
    }

    if (isBlocked) {
      if (kDebugMode) print('⚠️ [SmartReply] Bỏ qua vì bị chặn');
      if (_smartReplies.isNotEmpty) {
        _smartReplies = [];
      }
      return _smartReplies;
    }

    if (messages.isEmpty) {
      if (kDebugMode) print('⚠️ [SmartReply] Không có tin nhắn');
      return _smartReplies;
    }

    final lastMessage = messages.first;
    if (lastMessage.id == _lastProcessedMessageId) {
      if (kDebugMode) print('⚠️ [SmartReply] Tin nhắn đã được xử lý: ${lastMessage.id}');
      return _smartReplies;
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
      }
      return _smartReplies;
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

    return _smartReplies;
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

    if (kDebugMode) print('🎨 [SmartReply] Đã tạo ${_smartReplies.length} gợi ý');
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

    if (kDebugMode) print('🎨 [SmartReply] Đã tạo ${_smartReplies.length} gợi ý');
  }

  // ============================================================
  // XÓA GỢI Ý
  // ============================================================

  void clearReplies() {
    _smartReplies = [];
    _lastProcessedMessageId = null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _smartReply.close();
  }
}