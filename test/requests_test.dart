import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import các model và request của bạn
// LƯU Ý: Sửa lại đường dẫn import cho đúng với project của bạn
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_friend_request.dart';
// import 'package:mangxahoi/request/user_request.dart'; 
// import 'package:mangxahoi/request/post_request.dart';
// import 'package:mangxahoi/request/friend_request_manager.dart';

// --- MOCK CLASSES (Vì Request class của bạn khởi tạo Firestore bên trong, 
// nên ta cần kế thừa để override lại instance firestore giả) ---

// 1. Mock UserRequest
class TestUserRequest {
  final FirebaseFirestore _firestore;
  TestUserRequest(this._firestore);

  Future<String> addUser(UserModel user) async {
    final docRef = await _firestore.collection('User').add(user.toMap());
    return docRef.id;
  }
  
  Future<UserModel?> getUserData(String docId) async {
    final doc = await _firestore.collection('User').doc(docId).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }
}

// 2. Mock PostRequest
class TestPostRequest {
  final FirebaseFirestore _firestore;
  TestPostRequest(this._firestore);

  Future<String> createPost(PostModel post) async {
    final docRef = await _firestore.collection('Post').add(post.toMap());
    return docRef.id;
  }

  Future<void> deletePostSoft(String postId) async {
    await _firestore.collection('Post').doc(postId).update({
      'status': 'deleted',
      'deletedAt': Timestamp.now(),
    });
  }
}

// 3. Mock FriendRequestManager (Logic gửi kết bạn)
class TestFriendRequestManager {
  final FirebaseFirestore _firestore;
  TestFriendRequestManager(this._firestore);

  Future<void> sendRequest(String fromUserId, String toUserId) async {
    if (fromUserId == toUserId) return;
    
    // Check nếu đã có request
    final query = await _firestore.collection('FriendRequest')
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .get();
        
    if (query.docs.isNotEmpty) throw Exception("Đã gửi lời mời trước đó.");

    final newRequest = FriendRequestModel(
      id: 'temp_id', // Firestore tự sinh
      fromUserId: fromUserId,
      toUserId: toUserId,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await _firestore.collection('FriendRequest').add(newRequest.toMap());
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TestUserRequest userRequest;
  late TestPostRequest postRequest;
  late TestFriendRequestManager friendRequestManager;

  setUp(() {
    // Khởi tạo Database giả trước mỗi bài test
    fakeFirestore = FakeFirebaseFirestore();
    userRequest = TestUserRequest(fakeFirestore);
    postRequest = TestPostRequest(fakeFirestore);
    friendRequestManager = TestFriendRequestManager(fakeFirestore);
  });

  group('UserRequest Tests (Tương tác User)', () {
    test('TC-REQ-01: Thêm mới User vào Firestore', () async {
      final user = UserModel(
        id: '', uid: 'uid_test', name: 'Nguyen Van A', email: 'test@a.com', password: '123', phone: '', bio: '', gender: '', liveAt: '', comeFrom: '', role: '', relationship: '', statusAccount: '', backgroundImageUrl: '', avatar: [], friends: [], groups: [], posterList: [], followerCount: 0, followingCount: 0, createAt: DateTime.now(), notificationSettings: {}
      );

      final docId = await userRequest.addUser(user);
      
      // Kiểm tra xem database giả đã có dữ liệu chưa
      final snapshot = await fakeFirestore.collection('User').doc(docId).get();
      expect(snapshot.exists, true);
      expect(snapshot.data()?['name'], 'Nguyen Van A');
    });

    test('TC-REQ-02: Lấy thông tin User theo ID', () async {
      // Setup dữ liệu giả sẵn
      await fakeFirestore.collection('User').doc('user_123').set({
        'uid': 'uid_123',
        'name': 'User Test Get',
        'email': 'get@test.com',
        // Các trường bắt buộc khác để tránh lỗi fromFirestore...
        'friends': [], 'groups': [], 'posterList': [], 'notificationSettings': {}, 'avatar': [], 'locketFriends': []
      });

      // Action
      final user = await userRequest.getUserData('user_123');

      // Verify
      expect(user, isNotNull);
      expect(user!.name, 'User Test Get');
    });
  });

  group('PostRequest Tests (Quản lý bài viết)', () {
    test('TC-REQ-03: Tạo bài viết mới', () async {
      final post = PostModel(
        id: '', authorId: 'user_1', content: 'Hello World', mediaIds: [], commentsCount: 0, reactionsCount: {}, shareCount: 0, status: 'active', visibility: 'public', createdAt: DateTime.now(), updatedAt: DateTime.now(), taggedUserIds: []
      );

      final postId = await postRequest.createPost(post);
      
      final doc = await fakeFirestore.collection('Post').doc(postId).get();
      expect(doc.exists, true);
      expect(doc.data()?['content'], 'Hello World');
    });

    test('TC-REQ-04: Xóa mềm bài viết (Soft Delete)', () async {
      // Setup
      final ref = await fakeFirestore.collection('Post').add({
        'content': 'To be deleted',
        'status': 'active'
      });
      final postId = ref.id;

      // Action
      await postRequest.deletePostSoft(postId);

      // Verify
      final doc = await fakeFirestore.collection('Post').doc(postId).get();
      expect(doc.data()?['status'], 'deleted');
      expect(doc.data()?['deletedAt'], isNotNull); // Phải có timestamp
    });
  });

  group('FriendRequestManager Tests (Logic kết bạn)', () {
    test('TC-REQ-05: Gửi lời mời kết bạn thành công', () async {
      await friendRequestManager.sendRequest('user_A', 'user_B');

      final query = await fakeFirestore.collection('FriendRequest').get();
      expect(query.docs.length, 1);
      expect(query.docs.first.data()['fromUserId'], 'user_A');
      expect(query.docs.first.data()['status'], 'pending');
    });

    test('TC-REQ-06: Không thể gửi lời mời cho chính mình', () async {
      await friendRequestManager.sendRequest('user_A', 'user_A');
      
      final query = await fakeFirestore.collection('FriendRequest').get();
      expect(query.docs.isEmpty, true); // Không được tạo record nào
    });

    test('TC-REQ-07: Chặn gửi trùng lặp (Logic Business)', () async {
      // Gửi lần 1
      await friendRequestManager.sendRequest('user_A', 'user_B');
      
      // Gửi lần 2 -> Mong đợi throw Exception
      expect(
        () async => await friendRequestManager.sendRequest('user_A', 'user_B'),
        throwsA(isA<Exception>()),
      );
    });
  });
}