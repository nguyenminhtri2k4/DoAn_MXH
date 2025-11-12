
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/locket_request.dart';
import 'package:mangxahoi/request/user_request.dart'; // ✅ THÊM

class LocketViewModel extends ChangeNotifier {
  final LocketRequest _locketRequest = LocketRequest();
  final UserRequest _userRequest = UserRequest(); // ✅ THÊM
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance; // ✅ THÊM

  List<UserModel> _locketFriends = [];
  Map<String, LocketPhoto> _latestPhotos = {};
  bool _isLoading = true;
  bool _isUploading = false;
  
  // ✅ THÊM: Cache currentUserId
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  List<UserModel> get locketFriends => _locketFriends;
  Map<String, LocketPhoto> get latestPhotos => _latestPhotos;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;

  // ✅ THÊM: Constructor tự động init
  LocketViewModel() {
    _init();
  }

  // ✅ THÊM: Hàm init tự động (giống GroupsViewModel)
  void _init() async {
    print("🔧 [LocketVM] Bắt đầu khởi tạo...");
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        print("⚠️ [LocketVM] Chưa đăng nhập Firebase Auth");
        _isLoading = false;
        notifyListeners();
        return;
      }

      print("🔍 [LocketVM] Đang tìm user với UID: ${firebaseUser.uid}");
      final user = await _userRequest.getUserByUid(firebaseUser.uid);
      
      if (user != null) {
        _currentUserId = user.id;
        print("✅ [LocketVM] Đã lấy currentUserId: $_currentUserId");
        
        // Tự động fetch dữ liệu locket
        await _fetchLocketDataInternal(_currentUserId!);
      } else {
        print("⚠️ [LocketVM] Không tìm thấy user trong Firestore");
        _isLoading = false;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      print("❌ [LocketVM] Lỗi khi init: $e");
      print("❌ [LocketVM] StackTrace: $stackTrace");
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ ĐỔI TÊN: fetchLocketData → _fetchLocketDataInternal (private)
  Future<void> _fetchLocketDataInternal(String userId) async {
    print("🔄 [LocketVM] Bắt đầu fetch dữ liệu cho user $userId");

    try { 
      _locketFriends = await _locketRequest.getLocketFriendsDetails(userId);
      print("✅ [LocketVM] Đã lấy được ${_locketFriends.length} locket friends");

      List<String> friendIds = _locketFriends.map((f) => f.id).toList();
      if (!friendIds.contains(userId)) {
        friendIds.add(userId); 
      }
      print("🔍 [LocketVM] Danh sách ID cần lấy ảnh: $friendIds");

      _latestPhotos = await _locketRequest.getLatestLocketPhotos(friendIds);
      print("✅ [LocketVM] Đã lấy được ${_latestPhotos.length} ảnh mới nhất");

      _isLoading = false;
      notifyListeners();
      print("✅ [LocketVM] Hoàn thành fetch, isLoading=false");
    } catch (e, stackTrace) { 
      print("❌ [LocketVM] LỖI trong fetch: $e");
      print("❌ [LocketVM] StackTrace: $stackTrace");
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ THÊM: Public method để refresh thủ công
  Future<void> refreshLocketData() async {
    if (_currentUserId == null) {
      print("⚠️ [LocketVM] refreshLocketData: currentUserId = null");
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    await _fetchLocketDataInternal(_currentUserId!);
  }

  // ✅ SỬA: Dùng _currentUserId thay vì truyền parameter
  Future<void> pickAndUploadLocket() async {
    if (_currentUserId == null) {
      print("⚠️ [LocketVM] pickAndUploadLocket: currentUserId = null");
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        _isUploading = true;
        notifyListeners();

        print("📤 [LocketVM] Đang upload ảnh cho user $_currentUserId");
        await _locketRequest.uploadLocketPhoto(image, _currentUserId!);
        
        // Refresh dữ liệu sau khi upload
        await _fetchLocketDataInternal(_currentUserId!);

        _isUploading = false;
        notifyListeners();
        print("✅ [LocketVM] Upload hoàn tất");
      }
    } catch (e, stackTrace) {
      _isUploading = false;
      notifyListeners();
      print("❌ [LocketVM] Error picking/uploading locket: $e");
      print("❌ [LocketVM] StackTrace: $stackTrace");
    }
  }

  // ✅ THÊM: Hàm để check xem đã init xong chưa
  bool get isInitialized => _currentUserId != null && !_isLoading;
}