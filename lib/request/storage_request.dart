
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

  Future<MediaModel?> uploadFile({
    required File file,
    required String type,
    required String uploaderId,
  }) async {
    try {
      final fileName = '${uploaderId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('post_media/$fileName');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

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

  Future<List<String>> uploadFilesAndCreateMedia(List<File> files, String userId) async {
    List<String> mediaIds = [];
    try {
      for (var file in files) {
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

  // <--- HÀM CHO LOCKET --->
  Future<String> uploadLocketImage(XFile image, String userId) async {
    try {
      String fileName = 'locket_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = _storage.ref().child('locket_photos/$fileName');
      
      UploadTask uploadTask = ref.putFile(File(image.path));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print("Error uploading locket image: $e");
      throw Exception("Failed to upload locket image");
    }
  }
  
  // <--- HÀM XÓA ẢNH LOCKET (CHO THÙNG RÁC) --->
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
}