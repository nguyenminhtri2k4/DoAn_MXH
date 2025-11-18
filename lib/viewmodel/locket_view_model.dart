
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/locket_request.dart';
import 'package:mangxahoi/request/user_request.dart';

class LocketViewModel extends ChangeNotifier {
  final LocketRequest _locketRequest = LocketRequest();
  final UserRequest _userRequest = UserRequest();
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserModel> _locketFriends = [];
  Map<String, LocketPhoto> _latestPhotos = {};
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isDisposed = false;
  
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  List<UserModel> get locketFriends => _locketFriends;
  Map<String, LocketPhoto> get latestPhotos => _latestPhotos;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;

  LocketViewModel() {
    _init();
  }

  @override
  void dispose() {
    print('🔧 [LocketViewModel] Disposing...');
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void _init() async {
    if (_isDisposed) return;
    
    print("🔧 [LocketVM] Bắt đầu khởi tạo...");
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        print("⚠️ [LocketVM] Chưa đăng nhập Firebase Auth");
        if (!_isDisposed) {
          _isLoading = false;
          notifyListeners();
        }
        return;
      }

      print("🔍 [LocketVM] Đang tìm user với UID: ${firebaseUser.uid}");
      final user = await _userRequest.getUserByUid(firebaseUser.uid);
      
      if (_isDisposed) return;
      
      if (user != null) {
        _currentUserId = user.id;
        print("✅ [LocketVM] Đã lấy currentUserId: $_currentUserId");
        
        await _fetchLocketDataInternal(_currentUserId!);
      } else {
        print("⚠️ [LocketVM] Không tìm thấy user trong Firestore");
        if (!_isDisposed) {
          _isLoading = false;
          notifyListeners();
        }
      }
    } catch (e, stackTrace) {
      print("❌ [LocketVM] Lỗi khi init: $e");
      print("❌ [LocketVM] StackTrace: $stackTrace");
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchLocketDataInternal(String userId) async {
    if (_isDisposed) return;
    
    print("🔄 [LocketVM] Bắt đầu fetch dữ liệu cho user $userId");

    try { 
      _locketFriends = await _locketRequest.getLocketFriendsDetails(userId);
      
      if (_isDisposed) return;
      
      print("✅ [LocketVM] Đã lấy được ${_locketFriends.length} locket friends");

      List<String> friendIds = _locketFriends.map((f) => f.id).toList();
      if (!friendIds.contains(userId)) {
        friendIds.add(userId); 
      }
      print("🔍 [LocketVM] Danh sách ID cần lấy ảnh: $friendIds");

      _latestPhotos = await _locketRequest.getLatestLocketPhotos(friendIds);
      
      if (_isDisposed) return;
      
      print("✅ [LocketVM] Đã lấy được ${_latestPhotos.length} ảnh mới nhất");

      _isLoading = false;
      notifyListeners();
      print("✅ [LocketVM] Hoàn thành fetch, isLoading=false");
    } catch (e, stackTrace) { 
      print("❌ [LocketVM] LỖI trong fetch: $e");
      print("❌ [LocketVM] StackTrace: $stackTrace");
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshLocketData() async {
    if (_currentUserId == null || _isDisposed) {
      print("⚠️ [LocketVM] refreshLocketData: currentUserId = null hoặc disposed");
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    await _fetchLocketDataInternal(_currentUserId!);
  }

  Future<void> pickAndUploadLocket() async {
    if (_currentUserId == null || _isDisposed) {
      print("⚠️ [LocketVM] pickAndUploadLocket: currentUserId = null hoặc disposed");
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (_isDisposed) return;

      if (image != null) {
        _isUploading = true;
        notifyListeners();

        print("📤 [LocketVM] Đang upload ảnh cho user $_currentUserId");
        await _locketRequest.uploadLocketPhoto(image, _currentUserId!);
        
        if (_isDisposed) return;
        
        await _fetchLocketDataInternal(_currentUserId!);

        if (!_isDisposed) {
          _isUploading = false;
          notifyListeners();
          print("✅ [LocketVM] Upload hoàn tất");
        }
      }
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        _isUploading = false;
        notifyListeners();
      }
      print("❌ [LocketVM] Error picking/uploading locket: $e");
      print("❌ [LocketVM] StackTrace: $stackTrace");
    }
  }

  bool get isInitialized => _currentUserId != null && !_isLoading && !_isDisposed;
}