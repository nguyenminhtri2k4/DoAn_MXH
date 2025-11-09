import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mangxahoi/model/model_audio.dart';
import 'package:mangxahoi/request/storage_request.dart';
import 'package:mangxahoi/request/story_request.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import để lấy media URL

enum StoryType { text, image, video }

class CreateStoryViewModel extends ChangeNotifier {
  final StoryRequest _storyRequest = StoryRequest();
  final StorageRequest _storageRequest = StorageRequest();

  StoryType _storyType = StoryType.image;
  StoryType get storyType => _storyType;

  XFile? _selectedMedia;
  XFile? get selectedMedia => _selectedMedia;

  AudioModel? _selectedAudio;
  AudioModel? get selectedAudio => _selectedAudio;

  String _storyContent = '';
  String get storyContent => _storyContent;

  String _backgroundColor = 'Color(0xff3399ff)'; // Màu mặc định
  String get backgroundColor => _backgroundColor;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setStoryType(StoryType type) {
    _storyType = type;
    if (type == StoryType.text) {
      _selectedMedia = null;
    }
    notifyListeners();
  }

  void setStoryContent(String text) {
    _storyContent = text;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color.toString();
    notifyListeners();
  }

  void setSelectedAudio(AudioModel? audio) {
    _selectedAudio = audio;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> pickMedia(ImageSource source, StoryType type) async {
    final ImagePicker picker = ImagePicker();
    _selectedMedia = null; // Xóa media cũ
    _errorMessage = null;

    try {
      if (type == StoryType.image) {
        _selectedMedia = await picker.pickImage(source: source);
      } else {
        _selectedMedia = await picker.pickVideo(source: source);
      }
      
      if (_selectedMedia != null) {
        _storyType = type;
      }
    } catch (e) {
      _errorMessage = "Lỗi chọn media: $e";
    }
    notifyListeners();
  }

  Future<bool> postStory(BuildContext context) async {
    _setLoading(true);
    _errorMessage = null;

    final String? currentUserId = context.read<UserService>().currentUser?.id;
    if (currentUserId == null) {
      _errorMessage = "Không tìm thấy người dùng";
      _setLoading(false);
      return false;
    }
    
    // Kiểm tra điều kiện
    if (_storyType == StoryType.text && _storyContent.trim().isEmpty) {
       _errorMessage = "Vui lòng nhập nội dung cho story";
      _setLoading(false);
      return false;
    }
    if ((_storyType == StoryType.image || _storyType == StoryType.video) && _selectedMedia == null) {
       _errorMessage = "Vui lòng chọn ảnh hoặc video";
      _setLoading(false);
      return false;
    }

    try {
      String mediaUrl = '';
      String mediaType = 'text'; // Mặc định là text

      if (_storyType == StoryType.image || _storyType == StoryType.video) {
        if (_selectedMedia != null) {
          // Upload media lên Storage
          final file = File(_selectedMedia!.path);
          mediaType = _storyType == StoryType.image ? 'image' : 'video';
          
          final mediaIds = await _storageRequest.uploadFilesAndCreateMedia(
            [file], 
            currentUserId, 
            type: mediaType
          );
          
          if(mediaIds.isNotEmpty) {
            // Lấy URL từ media
             final mediaDoc = await FirebaseFirestore.instance
              .collection('Media')
              .doc(mediaIds.first)
              .get();
             mediaUrl = mediaDoc.data()?['url'] ?? '';
          } else {
            throw Exception("Upload media thất bại");
          }
        }
      }

      // Tạo Story
      await _storyRequest.createStory(
        authorId: currentUserId,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        content: _storyContent,
        backgroundColor: _backgroundColor,
        audio: _selectedAudio,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "Đăng story thất bại: $e";
      _setLoading(false);
      return false;
    }
  }
}