
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mangxahoi/model/model_audio.dart';
import 'package:mangxahoi/request/storage_request.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:provider/provider.dart';

class UploadAudioViewModel extends ChangeNotifier {
  final StorageRequest _storageRequest = StorageRequest();

  File? _audioFile;
  File? get audioFile => _audioFile;

  File? _coverFile;
  File? get coverFile => _coverFile;

  final TextEditingController nameController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> pickAudioFile() async {
    _errorMessage = null;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio, // Chỉ cho phép chọn file audio
      );
      if (result != null) {
        _audioFile = File(result.files.single.path!);
        
        // Tự động điền tên file vào Tên âm thanh (bỏ phần mở rộng)
        String fileName = result.files.single.name;
        // Xử lý trường hợp tên file không có phần mở rộng
        int dotIndex = fileName.lastIndexOf('.');
        if (dotIndex != -1) {
          nameController.text = fileName.substring(0, dotIndex);
        } else {
          nameController.text = fileName;
        }
        
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Lỗi chọn file: $e";
      notifyListeners();
    }
  }

  Future<void> pickCoverImage() async {
    _errorMessage = null;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _coverFile = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Lỗi chọn ảnh: $e";
      notifyListeners();
    }
  }

  Future<AudioModel?> uploadAudio(BuildContext context) async {
    if (_audioFile == null) {
      _errorMessage = "Vui lòng chọn một file âm thanh";
      notifyListeners();
      return null;
    }
    if (nameController.text.trim().isEmpty) {
      _errorMessage = "Vui lòng nhập tên cho âm thanh";
      notifyListeners();
      return null;
    }

    final String? uploaderId = context.read<UserService>().currentUser?.id;
    if (uploaderId == null) {
      _errorMessage = "Lỗi xác thực người dùng";
      notifyListeners();
      return null;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final newAudio = await _storageRequest.uploadAudioAndCreateAudio(
        audioFile: _audioFile!,
        coverImageFile: _coverFile,
        audioName: nameController.text.trim(),
        uploaderId: uploaderId,
      );
      _setLoading(false);
      return newAudio;
    } catch (e) {
      _errorMessage = "Tải lên thất bại: $e";
      _setLoading(false);
      return null;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}