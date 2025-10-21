// lib/viewmodel/locket_view_model.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/locket_request.dart';

class LocketViewModel extends ChangeNotifier {
  final LocketRequest _locketRequest = LocketRequest();
  final ImagePicker _picker = ImagePicker();

  List<UserModel> _locketFriends = [];
  Map<String, LocketPhoto> _latestPhotos = {};
  bool _isLoading = true;
  bool _isUploading = false;

  List<UserModel> get locketFriends => _locketFriends;
  Map<String, LocketPhoto> get latestPhotos => _latestPhotos;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;

  Future<void> fetchLocketData(String currentUserId) async {
    print("LocketVM: Bắt đầu fetchLocketData cho user $currentUserId");
    _isLoading = true;
    notifyListeners();

    try { 
      _locketFriends = await _locketRequest.getLocketFriendsDetails(currentUserId);
      print("LocketVM: Đã lấy được ${_locketFriends.length} locket friends.");

      List<String> friendIds = _locketFriends.map((f) => f.id).toList();
      if (!friendIds.contains(currentUserId)) {
          friendIds.add(currentUserId); 
      }
      print("LocketVM: Danh sách ID cần lấy ảnh: $friendIds");

      _latestPhotos = await _locketRequest.getLatestLocketPhotos(friendIds);
      print("LocketVM: Đã lấy được ${_latestPhotos.length} ảnh mới nhất.");

      _isLoading = false;
      notifyListeners();
      print("LocketVM: Hoàn thành fetchLocketData, isLoading=false");
    } catch (e, stackTrace) { 
      print("LocketVM: LỖI trong fetchLocketData: $e");
      print("LocketVM: StackTrace: $stackTrace");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickAndUploadLocket(String currentUserId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        _isUploading = true;
        notifyListeners();

        await _locketRequest.uploadLocketPhoto(image, currentUserId);
        await fetchLocketData(currentUserId); 

        _isUploading = false;
        notifyListeners();
      }
    } catch (e) {
      _isUploading = false;
      notifyListeners();
      print("Error picking/uploading locket: $e");
    }
  }
}