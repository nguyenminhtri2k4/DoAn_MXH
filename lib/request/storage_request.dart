
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mangxahoi/model/model_media.dart';
import 'package:mangxahoi/request/media_request.dart';
// --- IMPORT CHO STORY/AUDIO ---
import 'package:mangxahoi/model/model_audio.dart';
import 'package:mangxahoi/request/audio_request.dart';
// ----------------------------------

class StorageRequest {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final MediaRequest _mediaRequest = MediaRequest();

  // --- HÀM UPLOAD NỘI BỘ (PRIVATE) ---
  /// (Nội bộ) Hàm tải file chung, chỉ trả về URL
  Future<String> _internalUpload(File file, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
  // --- KẾT THÚC HÀM NỘI BỘ ---

  /// Tải lên một file (ảnh/video) cho profile và trả về URL.
  /// [folder] có thể là 'user_avatars' hoặc 'user_backgrounds'.
  Future<String?> uploadProfileImage(File file, String userId, String folder) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      // SỬA: Dùng hàm nội bộ
      return await _internalUpload(file, '$folder/$fileName');
    } catch (e) {
      print('Lỗi khi tải file ($folder): $e');
      return null;
    }
  }

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

  /// Hàm này dùng để upload 1 file và tạo MediaModel (cho Post)
  Future<MediaModel?> uploadFile({
    required File file,
    required String type,
    required String uploaderId,
  }) async {
    try {
      final fileName = '${uploaderId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final String fileTypePath = (type == 'video' ? 'videos' : 'images');
      final path = 'post_media/$uploaderId/$fileTypePath/$fileName';
      
      // SỬA: Dùng hàm nội bộ
      final downloadUrl = await _internalUpload(file, path);

      final newMedia = MediaModel(
        id: '',
        url: downloadUrl,
        type: type,
        uploaderId: uploaderId,
        createdAt: DateTime.now(),
      );

      final mediaId = await _mediaRequest.createMedia(newMedia);

      return MediaModel(
        id: mediaId,
        url: newMedia.url,
        type: newMedia.type,
        uploaderId: newMedia.uploaderId,
        createdAt: newMedia.createdAt
      );
    } catch (e) {
      print('Lỗi khi tải file: $e');
      return null;
    }
  }
  
  /// Hàm này dùng chung cho cả Post và Story (để tạo MediaModel)
  Future<List<String>> uploadFilesAndCreateMedia(List<File> files, String userId, {String type = 'image'}) async {
    List<String> mediaIds = [];
    try {
      for (var file in files) {
        // Tự động phát hiện type nếu không được cung cấp
        final fileExtension = file.path.split('.').last.toLowerCase();
        final String mediaType = ['mp4', 'mov', 'avi', 'mkv'].contains(fileExtension) ? 'video' : 'image';
        
        final media = await uploadFile(
          file: file,
          type: mediaType,
          uploaderId: userId,
        );

        if (media != null) {
          mediaIds.add(media.id);
        }
      }
      return mediaIds;
    } catch (e) {
      print('Lỗi trong quá trình tải nhiều file và tạo media: $e');
      rethrow;
    }
  }

  /// Hàm của Locket
  Future<String> uploadLocketImage(XFile image, String userId) async {
    try {
      String fileName = 'locket_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      String path = 'locket_photos/$fileName';
      
      // SỬA: Dùng hàm nội bộ
      String downloadUrl = await _internalUpload(File(image.path), path);
      return downloadUrl;
    } catch (e) {
      print("Error uploading locket image: $e");
      throw Exception("Failed to upload locket image");
    }
  }
  
  /// Hàm của Locket (xóa file)
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print("StorageRequest: Đã xóa file $imageUrl thành công.");
    } on FirebaseException catch (e) {
      print("Error deleting file from storage: $e");
      if (e.code == 'object-not-found') {
        print("File không tồn tại, có thể đã bị xóa trước đó.");
      } else {
        rethrow; 
      }
    } catch (e) {
      print("Error converting URL to storage reference: $e");
      rethrow;
    }
  }

  /// Hàm mới cho Story (chỉ upload, không tạo MediaModel)
  Future<String> uploadStoryFile(File file, String userId, String type) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = 'story_media/$userId/$type/$fileName';
      // SỬA: Dùng hàm nội bộ
      final downloadUrl = await _internalUpload(file, path);
      return downloadUrl;
    } catch (e) {
       print('Lỗi khi tải file Story: $e');
      rethrow;
    }
  }

  /// Hàm mới cho Audio (upload audio và cover, tạo AudioModel)
  Future<AudioModel> uploadAudioAndCreateAudio({
    required File audioFile,
    File? coverImageFile,
    required String audioName,
    required String uploaderId,
  }) async {
    try {
      // 1. Upload file âm thanh
      String extension = audioFile.path.split('.').last;
      String audioFileName = 'audio/${uploaderId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      // SỬA: Dùng hàm nội bộ
      String audioUrl = await _internalUpload(audioFile, audioFileName);

      String coverUrl = '';
      // 2. Upload ảnh bìa (nếu có)
      if (coverImageFile != null) {
        String coverFileName = 'audio_covers/${uploaderId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
         // SỬA: Dùng hàm nội bộ
        coverUrl = await _internalUpload(coverImageFile, coverFileName);
      }

      // 3. Tạo metadata trong collection 'Audio'
      final audioRequest = AudioRequest(); 
      AudioModel newAudio = await audioRequest.createAudio(
        uploaderId: uploaderId,
        name: audioName,
        audioUrl: audioUrl,
        coverImageUrl: coverUrl,
      );
      
      return newAudio;

    } catch (e) {
      print('Lỗi uploadAudioAndCreateAudio: $e');
      rethrow;
    }
  }
}