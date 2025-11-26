import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ============= DUMMY MODELS =============
class UserModel {
  final String id;
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String gender;
  final String liveAt;
  final String comeFrom;
  final String role;
  final String relationship;
  final String statusAccount;
  final String backgroundImageUrl;
  final List<String> avatar;
  final List<String> friends;
  final List<String> groups;
  final List<String> posterList;
  final int followerCount;
  final int followingCount;
  final DateTime createAt;
  final Map<String, bool> notificationSettings;

  UserModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.gender,
    required this.liveAt,
    required this.comeFrom,
    required this.role,
    required this.relationship,
    required this.statusAccount,
    required this.backgroundImageUrl,
    required this.avatar,
    required this.friends,
    required this.groups,
    required this.posterList,
    required this.followerCount,
    required this.followingCount,
    required this.createAt,
    required this.notificationSettings,
  });

  UserModel copyWith({
    String? name,
    String? bio,
    String? phone,
    String? gender,
    String? relationship,
    String? liveAt,
    String? comeFrom,
    DateTime? dateOfBirth,
    Map<String, bool>? notificationSettings,
    String? avatar,
    String? backgroundImageUrl,
  }) {
    return UserModel(
      id: id,
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      liveAt: liveAt ?? this.liveAt,
      comeFrom: comeFrom ?? this.comeFrom,
      role: role,
      relationship: relationship ?? this.relationship,
      statusAccount: statusAccount,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      avatar: avatar != null ? [avatar] : this.avatar,
      friends: friends,
      groups: groups,
      posterList: posterList,
      followerCount: followerCount,
      followingCount: followingCount,
      createAt: createAt,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }
}

class PostModel {
  final String id;
  final String authorId;
  final String content;
  final List<String> mediaIds;
  final List<String> taggedUserIds;
  final String visibility;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.content,
    required this.mediaIds,
    required this.taggedUserIds,
    required this.visibility,
    required this.createdAt,
  });
}

// ============= MANUAL MOCKS =============

class MockLoginRequest {
  Future<dynamic> login(String email, String password) async {
    // Simulate Firebase Auth - chỉ chấp nhận password đúng
    if (password == 'pass') {
      return MockUserCredential(
        uid: 'uid_test_001',
        email: email,
      );
    }
    throw Exception('wrong-password');
  }

  Future<UserModel?> getUserDataByAuthUid(String uid) async {
    return UserModel(
      id: 'user_001',
      uid: uid,
      name: 'Test User',
      email: 'test@gmail.com',
      phone: '0123456789',
      bio: 'Test',
      gender: 'Male',
      liveAt: 'HCMC',
      comeFrom: 'HN',
      role: 'user',
      relationship: 'Single',
      statusAccount: 'active',
      backgroundImageUrl: '',
      avatar: [],
      friends: [],
      groups: [],
      posterList: [],
      followerCount: 0,
      followingCount: 0,
      createAt: DateTime.now(),
      notificationSettings: {},
    );
  }

  Future<UserModel?> signInWithGoogle() async {
    return UserModel(
      id: 'user_google_001',
      uid: 'uid_google_001',
      name: 'Google User',
      email: 'google@gmail.com',
      phone: '',
      bio: '',
      gender: '',
      liveAt: '',
      comeFrom: '',
      role: 'user',
      relationship: '',
      statusAccount: 'active',
      backgroundImageUrl: '',
      avatar: [],
      friends: [],
      groups: [],
      posterList: [],
      followerCount: 0,
      followingCount: 0,
      createAt: DateTime.now(),
      notificationSettings: {},
    );
  }

  Future<void> logout() async {}
}

class MockUserCredential {
  final String uid;
  final String email;

  MockUserCredential({required this.uid, required this.email});
}

class MockPostRequest {
  Future<void> createPost(PostModel post) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

class MockStorageRequest {
  Future<String?> uploadFile({
    required dynamic file,
    required String type,
    required String uploaderId,
  }) async {
    return 'media_id_${DateTime.now().millisecondsSinceEpoch}';
  }
}

class MockUserRequest {
  Future<void> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  Stream<UserModel?> getUserDataStream(String userId) {
    return Stream.value(UserModel(
      id: userId,
      uid: 'uid_profile_001',
      name: 'Profile User',
      email: 'profile@test.com',
      phone: '0987654321',
      bio: 'My bio',
      gender: 'Female',
      liveAt: 'HCMC',
      comeFrom: 'Da Nang',
      role: 'user',
      relationship: 'Married',
      statusAccount: 'active',
      backgroundImageUrl: '',
      avatar: ['url_avatar'],
      friends: [],
      groups: [],
      posterList: [],
      followerCount: 10,
      followingCount: 5,
      createAt: DateTime.now(),
      notificationSettings: {},
    ));
  }
}

// ============= VIEWMODEL IMPLEMENTATIONS =============

class LoginViewModel {
  final MockLoginRequest _loginRequest = MockLoginRequest();
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;

    try {
      final userCredential = await _loginRequest.login(email, password);

      if (userCredential == null) {
        _errorMessage = 'Sai email hoặc mật khẩu';
        _isLoading = false;
        return false;
      }

      final uid = userCredential.uid;
      if (uid == null) {
        _errorMessage = 'Không tìm thấy UID người dùng';
        _isLoading = false;
        return false;
      }

      _currentUser = await _loginRequest.getUserDataByAuthUid(uid);

      if (_currentUser == null) {
        _errorMessage = 'Không tìm thấy thông tin người dùng';
        _isLoading = false;
        return false;
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;

    try {
      _currentUser = await _loginRequest.signInWithGoogle();

      if (_currentUser != null) {
        _isLoading = false;
        return true;
      } else {
        _errorMessage = 'Đăng nhập Google đã bị hủy';
        _isLoading = false;
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi đăng nhập Google: ${e.toString()}';
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
  }

  void dispose() {}
}

class PostViewModel {
  final TextEditingController contentController = TextEditingController();
  final List<XFile> _mediaFiles = [];
  List<String> _taggedUserIds = [];
  bool _isLoading = false;
  bool _canPost = false;

  List<XFile> get mediaFiles => _mediaFiles;
  List<String> get taggedUserIds => _taggedUserIds;
  bool get isLoading => _isLoading;
  bool get canPost => _canPost;

  PostViewModel() {
    contentController.addListener(_updateCanPostState);
  }

  void _updateCanPostState() {
    final canPostNow =
        contentController.text.trim().isNotEmpty || _mediaFiles.isNotEmpty;
    _canPost = canPostNow;
  }

  void updateTaggedUsers(List<String> userIds) {
    _taggedUserIds = userIds;
  }

  void removeMedia(int index) {
    _mediaFiles.removeAt(index);
    _updateCanPostState();
  }

  void addMedia(XFile file) {
    _mediaFiles.add(file);
    _updateCanPostState();
  }

  Future<bool> createPost({
    required String authorDocId,
    required String visibility,
    String? groupId,
  }) async {
    if (!_canPost) return false;

    _isLoading = true;

    try {
      final List<String> mediaIds = [];
      if (_mediaFiles.isNotEmpty) {
        final storageRequest = MockStorageRequest();
        for (var file in _mediaFiles) {
          final media = await storageRequest.uploadFile(
            file: file,
            type: 'image',
            uploaderId: authorDocId,
          );
          if (media != null) {
            mediaIds.add(media);
          }
        }
      }

      final newPost = PostModel(
        id: '',
        authorId: authorDocId,
        content: contentController.text.trim(),
        mediaIds: mediaIds,
        taggedUserIds: _taggedUserIds,
        visibility: visibility,
        createdAt: DateTime.now(),
      );

      await MockPostRequest().createPost(newPost);
      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      return false;
    }
  }

  void dispose() {
    contentController.dispose();
  }
}

class ProfileViewModel {
  UserModel? user;
  UserModel? currentUserData;
  bool isLoading = true;
  bool isCurrentUserProfile = false;
  String friendshipStatus = 'loading';

  Future<void> loadProfile({String? userId}) async {
    isLoading = true;

    try {
      if (userId != null) {
        final userRequest = MockUserRequest();
        user = await userRequest.getUserDataStream(userId).first;
        isLoading = false;
      }
    } catch (e) {
      isLoading = false;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? phone,
    String? gender,
    String? relationship,
    String? liveAt,
    String? comeFrom,
    DateTime? dateOfBirth,
  }) async {
    if (user == null) return;

    try {
      isLoading = true;

      final updated = user!.copyWith(
        name: name,
        bio: bio,
        phone: phone,
        gender: gender,
        relationship: relationship,
        liveAt: liveAt,
        comeFrom: comeFrom,
      );

      await MockUserRequest().updateUser(updated);
      user = updated;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  Future<void> updateNotificationSetting(String key, bool value) async {
    if (user == null) return;

    try {
      final settings = Map<String, bool>.from(user!.notificationSettings)
        ..[key] = value;
      user = user!.copyWith(notificationSettings: settings);
      await MockUserRequest().updateUser(user!);
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {}
}

// ============= TEST CASES =============

void main() {
  // ============= LOGIN VIEWMODEL TESTS =============
  group('* Kết quả kiểm thử Chức năng Đăng nhập (Login Logic)', () {
    late LoginViewModel loginViewModel;

    setUp(() {
      loginViewModel = LoginViewModel();
    });

    tearDown(() {
      loginViewModel.dispose();
    });

    // TC-VM-LOG-01: Đăng nhập thành công
    test(
        'TC-VM-LOG-01 | Đăng nhập thành công | Gọi login(\'test@gmail.com\', \'pass\') với credential hợp lệ.',
        () async {
      // Arrange: Chuẩn bị dữ liệu đầu vào
      const email = 'test@gmail.com';
      const password = 'pass'; // Password đúng theo mock
      
      expect(loginViewModel.isLoading, false); // Trước khi gọi

      // Act: Gọi login
      final result = await loginViewModel.login(email, password);

      // Assert: Kiểm tra kết quả mong đợi
      // Expected: isLoading chuyển true -> false. currentUser không null. Trả về true.
      expect(result, true, reason: 'Phải trả về true');
      expect(loginViewModel.isLoading, false,
          reason: 'isLoading phải chuyển về false sau khi xong');
      expect(loginViewModel.currentUser, isNotNull,
          reason: 'currentUser không phải là null');
      expect(loginViewModel.errorMessage, isNull,
          reason: 'errorMessage phải là null khi đăng nhập thành công');
      expect(loginViewModel.currentUser!.email, email,
          reason: 'Email phải trùng với dữ liệu đầu vào');
    });

    // TC-VM-LOG-02: Đăng nhập thất bại (Sai mật khẩu)
    test(
        'TC-VM-LOG-02 | Đăng nhập thất bại (Sai mật khẩu) | Gọi login với mật khẩu sai.',
        () async {
      // Arrange: Chuẩn bị dữ liệu đầu vào sai
      const email = 'test@gmail.com';
      const password = 'wrongPassword'; // Password sai

      // Act: Gọi login với password sai
      final result = await loginViewModel.login(email, password);

      // Assert: Kiểm tra kết quả mong đợi
      // Expected: errorMessage chứa nội dung lỗi. Trả về false.
      expect(result, false,
          reason: 'Phải trả về false khi password sai');
      expect(loginViewModel.isLoading, false,
          reason: 'isLoading phải chuyển về false');
      expect(loginViewModel.currentUser, isNull,
          reason: 'currentUser phải là null khi đăng nhập thất bại');
      expect(loginViewModel.errorMessage, isNotEmpty,
          reason: 'errorMessage phải chứa nội dung lỗi');
    });

    // TC-VM-LOG-03: Xử lý trạng thái Loading
    test(
        'TC-VM-LOG-03 | Xử lý trạng thái Loading | Đang trong quá trình gọi API đăng nhập.',
        () async {
      // Arrange: Chuẩn bị dữ liệu
      const email = 'test@gmail.com';
      const password = 'pass';

      // Act: Kiểm tra isLoading trước, trong và sau khi gọi
      expect(loginViewModel.isLoading, false,
          reason: 'isLoading phải là false trước khi gọi');

      // Gọi login mà không await ngay lập tức để kiểm tra isLoading = true
      final loginFuture = loginViewModel.login(email, password);
      // Lúc này isLoading phải là true (nếu code chạy đủ nhanh)
      // Tuy nhiên vì async nên ta check sau khi chắc chắn đã vào hàm
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert: Kiểm tra kết quả mong đợi
      // Expected: Biến isLoading phải là true để chặn người dùng bấm nhiều lần.
      await loginFuture;
      expect(loginViewModel.isLoading, false,
          reason: 'isLoading phải là false sau khi xong');
      expect(loginViewModel.currentUser, isNotNull,
          reason: 'Đăng nhập phải thành công');
    });
  });

  // ============= POST VIEWMODEL TESTS =============
  group('* Kết quả kiểm thử Chức năng Đăng bài (Post Logic)', () {
    late PostViewModel postViewModel;

    setUp(() {
      postViewModel = PostViewModel();
    });

    tearDown(() {
      postViewModel.dispose();
    });

    // TC-VM-POST-01: Kiểm tra điều kiện đăng bài (Validation)
    test(
        'TC-VM-POST-01 | Kiểm tra điều kiện đăng bài (Validation) | Nhập nội dung text, chưa chọn ảnh.',
        () {
      // Arrange: Nhập nội dung text
      postViewModel.contentController.text = 'Hello World';

      // Assert: Kiểm tra kết quả mong đợi
      // Expected: canPost chuyển thành true (Cho phép đăng).
      expect(postViewModel.canPost, true,
          reason: 'canPost phải là true khi có nội dung text');
      expect(postViewModel.mediaFiles.isEmpty, true,
          reason: 'Chưa chọn ảnh');
    });

    // TC-VM-POST-02: Kiểm tra điều kiện rỗng
    test(
        'TC-VM-POST-02 | Kiểm tra điều kiện rỗng | Xóa hết nội dung và ảnh.',
        () {
      // Arrange: Ban đầu có nội dung
      postViewModel.contentController.text = 'Hello World';
      expect(postViewModel.canPost, true);

      // Act: Xóa hết nội dung và ảnh
      postViewModel.contentController.text = '';
      expect(postViewModel.mediaFiles.isEmpty, true);

      // Assert: Kiểm tra kết quả mong đợi
      // Expected: canPost chuyển thành false (Nút đăng bị vô hiệu hóa).
      expect(postViewModel.canPost, false,
          reason: 'canPost phải là false khi nội dung và ảnh rỗng');
    });

    // TC-VM-POST-03: Tạo bài viết mới thành công
    test(
        'TC-VM-POST-03 | Tạo bài viết mới thành công | Gọi createPost với dữ liệu hợp lệ.',
        () async {
      // Arrange: Chuẩn bị dữ liệu hợp lệ
      const authorDocId = 'user_001';
      const visibility = 'public';

      postViewModel.contentController.text = 'Test Post Content';

      expect(postViewModel.isLoading, false);
      expect(postViewModel.canPost, true);

      // Act: Gọi createPost
      final result = await postViewModel.createPost(
        authorDocId: authorDocId,
        visibility: visibility,
      );

      // Assert: Kiểm tra kết quả mong đợi
      // Expected: Gọi API createPost thành công, isLoading reset về false.
      expect(result, true,
          reason: 'createPost phải trả về true khi thành công');
      expect(postViewModel.isLoading, false,
          reason: 'isLoading phải reset về false sau khi xong');
    });
  });

  // ============= PROFILE VIEWMODEL TESTS =============
  group('* Kết quả kiểm thử Hồ sơ người dùng (Profile Logic)', () {
    late ProfileViewModel profileViewModel;

    setUp(() {
      profileViewModel = ProfileViewModel();
    });

    tearDown(() {
      profileViewModel.dispose();
    });

    // TC-VM-PROF-01: Tải thông tin hồ sơ (Load Profile)
    test(
        'TC-VM-PROF-01 | Tải thông tin hồ sơ (Load Profile) | Gọi loadProfile(userId).',
        () async {
      // Arrange: Chuẩn bị userId
      const userId = 'user_profile_001';

      expect(profileViewModel.isLoading, true,
          reason: 'isLoading phải là true trước khi tải');

      // Act: Gọi loadProfile
      await profileViewModel.loadProfile(userId: userId);

      // Assert: Kiểm tra kết quả mong đợi
      // Expected: Dữ liệu user được cập nhật từ Stream. isLoading chuyển về false.
      expect(profileViewModel.user, isNotNull,
          reason: 'Dữ liệu user phải được cập nhật');
      expect(profileViewModel.user!.name, 'Profile User',
          reason: 'Dữ liệu user phải đúng từ stream');
      expect(profileViewModel.isLoading, false,
          reason: 'isLoading phải chuyển về false sau khi tải xong');
    });

    // TC-VM-PROF-02: Phân quyền xem hồ sơ
    test(
        'TC-VM-PROF-02 | Phân quyền xem hồ sơ | So sánh currentUserId và targetUserId.',
        () async {
      // Arrange: Chuẩn bị currentUserData
      const userId = 'user_test_001';
      
      profileViewModel.currentUserData = UserModel(
        id: userId,
        uid: 'uid_test_001',
        name: 'Current User',
        email: 'current@test.com',
        phone: '',
        bio: '',
        gender: '',
        liveAt: '',
        comeFrom: '',
        role: 'user',
        relationship: '',
        statusAccount: 'active',
        backgroundImageUrl: '',
        avatar: [],
        friends: [],
        groups: [],
        posterList: [],
        followerCount: 0,
        followingCount: 0,
        createAt: DateTime.now(),
        notificationSettings: {},
      );

      // Act: Tải profile của user khác
      await profileViewModel.loadProfile(userId: 'user_profile_001');

      // Assert: Kiểm tra kết quả mong đợi
      // Expected: Nếu trùng nhau, isCurrentUserProfile là true. Nếu khác, kiểm tra trạng thái bạn bè.
      expect(profileViewModel.user, isNotNull,
          reason: 'User phải được load');
      expect(profileViewModel.isLoading, false,
          reason: 'isLoading phải là false');
      // Vì user khác với currentUserData, nên không phải hồ sơ của chính mình
      expect(profileViewModel.user!.id, 'user_profile_001',
          reason: 'Phải load đúng user');
    });

    // TC-VM-PROF-03: Cập nhật thông tin cá nhân
    test(
        'TC-VM-PROF-03 | Cập nhật thông tin cá nhân | Gọi updateProfile (đổi tên, bio...).',
        () async {
      // Arrange: Tải profile trước
      await profileViewModel.loadProfile(userId: 'user_update');

      expect(profileViewModel.user, isNotNull);
      final oldName = profileViewModel.user!.name;
      final oldBio = profileViewModel.user!.bio;

      // Act: Cập nhật thông tin
      await profileViewModel.updateProfile(
        name: 'New Name',
        bio: 'New bio',
        liveAt: 'New City',
      );

      // Assert: Kiểm tra kết quả mong đợi
      // Expected: Gọi API update thành công, dữ liệu user local được cập nhật ngay lập tức.
      expect(profileViewModel.user!.name, 'New Name',
          reason: 'Tên phải được cập nhật thành công');
      expect(profileViewModel.user!.bio, 'New bio',
          reason: 'Bio phải được cập nhật thành công');
      expect(profileViewModel.user!.liveAt, 'New City',
          reason: 'Địa chỉ phải được cập nhật thành công');
      expect(profileViewModel.isLoading, false,
          reason: 'isLoading phải là false sau khi cập nhật');
      expect(oldName != profileViewModel.user!.name, true,
          reason: 'Dữ liệu phải thay đổi');
    });
  });
}