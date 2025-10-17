import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mangxahoi/model/model_media.dart';
import 'package:mangxahoi/request/media_request.dart';

class StorageRequest {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final MediaRequest _mediaRequest = MediaRequest();

  Future<List<File>> pickImages() async {
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
    return pickedFiles.map((file) => File(file.path)).toList();
  }

  Future<File?> pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// Tải file lên Storage, tạo document trong collection Media, và trả về danh sách Media ID
  Future<List<String>> uploadFilesAndCreateMedia(List<File> files, String userId) async {
    List<String> mediaIds = [];
    try {
      for (var file in files) {
        // Bước 1: Tải file lên Storage để lấy URL
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final ref = _storage.ref().child('post_media/$fileName');
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Xác định loại media dựa trên đuôi file
        final fileExtension = file.path.split('.').last.toLowerCase();
        final String mediaType = ['mp4', 'mov', 'avi', 'mkv'].contains(fileExtension) ? 'video' : 'image';
        
        // Tạo đối tượng MediaModel
        final newMedia = MediaModel(
          id: '', // ID sẽ được Firestore tự tạo
          url: downloadUrl,
          type: mediaType,
          uploaderId: userId,
          createdAt: DateTime.now(),
        );

        // Bước 2: Lưu vào collection Media và lấy về ID
        final mediaId = await _mediaRequest.createMedia(newMedia);
        mediaIds.add(mediaId);
      }
      return mediaIds;
    } catch (e) {
      print('Lỗi trong quá trình tải file và tạo media: $e');
      rethrow;
    }
  }
}