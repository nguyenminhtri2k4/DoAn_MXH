import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Cập nhật tên package của bạn nếu khác 'mangxahoi'
import 'package:mangxahoi/model/model_blocked.dart';
import 'package:mangxahoi/model/model_chat.dart';
import 'package:mangxahoi/model/model_comment.dart';
import 'package:mangxahoi/model/model_friend_request.dart';
import 'package:mangxahoi/model/model_friend.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_reaction.dart';
import 'package:mangxahoi/model/model_report.dart';
import 'package:mangxahoi/model/model_user.dart';

void main() {
  // ==========================================
  // 1. BLOCKED USER MODEL TEST
  // ==========================================
  group('BlockedUserModel Tests', () {
    test('TC-BLK-01: Tạo và kiểm tra toMap', () {
      final blocked = BlockedUserModel(
        id: 'block1',
        blockedId: 'userB',
        blockerId: 'userA',
        reason: 'Spam',
        status: 'active',
      );

      final map = blocked.toMap();

      expect(map['blockedId'], 'userB');
      expect(map['blockerId'], 'userA');
      expect(map['reason'], 'Spam');
      expect(map['status'], 'active');
    });
  });

  // ==========================================
  // 2. CHAT MODEL TEST
  // ==========================================
  group('ChatModel Tests', () {
    test('TC-CHT-01: fromMap và toMap hoạt động đúng', () {
      final now = Timestamp.now();
      final chatData = {
        'lastMessage': 'Hello',
        'members': ['A', 'B'],
        'type': 'private',
        'updatedAt': now,
        'status': 'active',
      };

      final chat = ChatModel.fromMap(chatData, 'chat1');

      expect(chat.id, 'chat1');
      expect(chat.lastMessage, 'Hello');
      expect(chat.members.length, 2);
      expect(chat.status, 'active');

      final mapOutput = chat.toMap();
      expect(mapOutput['lastMessage'], 'Hello');
      expect(mapOutput['status'], 'active');
    });

    test('TC-CHT-02: Kiểm tra giá trị mặc định của status', () {
      final chatData = {
        'lastMessage': 'Hi',
        'members': [],
        'updatedAt': Timestamp.now(),
        // Thiếu status
      };
      final chat = ChatModel.fromMap(chatData, 'chat2');
      expect(chat.status, 'active'); // Mặc định phải là active
    });
  });

  // ==========================================
  // 3. COMMENT MODEL TEST
  // ==========================================
  group('CommentModel Tests', () {
    test('TC-CMT-01: Constructor và toMap', () {
      final comment = CommentModel(
        id: 'cmt1',
        postId: 'post1',
        authorId: 'author1',
        content: 'Nice post',
        createdAt: DateTime.now(),
        // Thay đổi: Sử dụng Map reactions thay vì List likes
        reactions: {
          'user1': 'like',
          'user2': 'love', // Test thử 2 loại reaction khác nhau
        },
        commentsCount: 5,
      );

      final map = comment.toMap();
      
      expect(map['content'], 'Nice post');
      
      // Thay đổi: Kiểm tra field reactions là Map
      expect(map['reactions'], isA<Map>());
      expect((map['reactions'] as Map).length, 2);
      expect(map['reactions']['user1'], 'like');
      
      expect(map['commentsCount'], 5);
      expect(map['status'], 'active'); // Giá trị mặc định
    });
});

  // ==========================================
  // 4. FRIEND REQUEST MODEL TEST
  // ==========================================
  group('FriendRequestModel Tests', () {
    test('TC-FRQ-01: Xử lý status mặc định là pending', () {
      final data = {
        'fromUserId': 'userA',
        'toUserId': 'userB',
        // Thiếu status
        'createdAt': Timestamp.now(),
      };

      final req = FriendRequestModel.fromMap('req1', data);
      expect(req.status, 'pending');
    });
  });

  // ==========================================
  // 5. FRIEND MODEL TEST
  // ==========================================
  group('FriendModel Tests', () {
    test('TC-FRD-01: Round-trip từ Map sang Object và ngược lại', () {
      final data = {
        'user1': 'A',
        'user2': 'B',
        'status': 'accepted',
        'createdAt': Timestamp.now(),
      };
      
      final friend = FriendModel.fromMap('friend1', data);
      expect(friend.user1, 'A');
      
      final map = friend.toMap();
      expect(map['user2'], 'B');
    });
  });

  // ==========================================
  // 6. GROUP MODEL TEST
  // ==========================================
  group('GroupModel Tests', () {
    test('TC-GRP-01: Kiểm tra trường coverImage mới', () {
      final groupData = {
        'ownerId': 'owner1',
        'name': 'IT Group',
        'description': 'Devs',
        'coverImage': 'http://image.com/cover.jpg',
        'managers': [],
        'members': ['owner1'],
        'settings': 'public',
        'status': 'activate',
        'type': 'post',
      };

      final group = GroupModel.fromMap('group1', groupData);
      expect(group.coverImage, 'http://image.com/cover.jpg');
    });

    test('TC-GRP-02: Giá trị mặc định khi thiếu dữ liệu', () {
      final incompleteData = {
        'ownerId': 'owner1',
        'name': 'Test',
        'description': '',
        'managers': [],
        'members': [],
        'settings': '',
        'status': 'activate',
        // Thiếu coverImage và type
      };

      final group = GroupModel.fromMap('group2', incompleteData);
      expect(group.coverImage, ''); 
      expect(group.type, 'post');
    });
  });

  // ==========================================
  // 7. MESSAGE MODEL TEST
  // ==========================================
  group('MessageModel Tests', () {
    test('TC-MSG-01: Kiểm tra Shared Post ID', () {
      final msgData = {
        'content': 'Check this out',
        'senderId': 'A',
        'type': 'share_post',
        'sharedPostId': 'post_123',
        'mediaIds': [],
        'status': 'sent',
        'createdAt': Timestamp.now(),
      };

      final msg = MessageModel.fromMap(msgData, 'msg1');
      expect(msg.type, 'share_post');
      expect(msg.sharedPostId, 'post_123');
    });
  });

  // ==========================================
  // 8. POST MODEL TEST
  // ==========================================
  group('PostModel Tests', () {
    test('TC-PST-01: Tagged Users và CopyWith', () {
      final post = PostModel(
        id: 'post1',
        authorId: 'author1',
        content: 'Content',
        mediaIds: [],
        commentsCount: 0,
        reactionsCount: {'like': 10},
        shareCount: 0,
        status: 'active',
        visibility: 'public',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        taggedUserIds: ['userA'],
      );

      // Test CopyWith
      final updatedPost = post.copyWith(
        content: 'New Content',
        taggedUserIds: ['userA', 'userB'], // Thêm userB
      );

      expect(updatedPost.content, 'New Content');
      expect(updatedPost.taggedUserIds?.length, 2);
      expect(updatedPost.reactionsCount['like'], 10);
    });

    test('TC-PST-02: Xử lý fromMap với taggedUserIds null', () {
      final map = {
        'authorId': 'A',
        'content': 'Hi',
        'taggedUserIds': null, // Giả lập dữ liệu cũ
        'status': 'active',
      };
      
      final post = PostModel.fromMap('post2', map);
      expect(post.taggedUserIds, []); // Không được null, phải là list rỗng
      expect(post.taggedUserIds, isNotNull);
    });
  });

  // ==========================================
  // 9. REACTION MODEL TEST
  // ==========================================
  group('ReactionModel Tests', () {
    test('TC-RCT-01: Constructor và toMap', () {
      final react = ReactionModel(
        id: 'r1',
        authorId: 'user1',
        type: 'love',
        time: DateTime.now(),
      );

      final map = react.toMap();
      expect(map['authorId'], 'user1');
      expect(map['type'], 'love');
    });
  });

  // ==========================================
  // 10. REPORT MODEL TEST
  // ==========================================
  group('ReportModel Tests', () {
    test('TC-RPT-01: Kiểm tra thông tin báo cáo', () {
      final report = ReportModel(
        id: 'rp1',
        reporterId: 'userA',
        targetId: 'post1',
        targetAuthorId: 'userB',
        targetType: 'post',
        reason: 'Inappropriate',
        createdAt: DateTime.now(),
      );

      final map = report.toMap();
      expect(map['targetAuthorId'], 'userB');
      expect(map['status'], 'pending'); // Default check
    });
  });

  // ==========================================
  // 11. USER MODEL TEST
  // ==========================================
  group('UserModel Tests', () {
    test('TC-USR-01: Getter friendsCount', () {
      final user = UserModel(
        id: 'u1', uid: 'user1759821679969', name: 'A', email: 'a@a.com', password: 'p', phone: '', bio: '', gender: '', liveAt: '', comeFrom: '', role: '', relationship: '', statusAccount: '', backgroundImageUrl: '', avatar: [],
        friends: ['user1759821679974', 'user1759821679977', 'user1759821679970'],
        groups: [], posterList: [], followerCount: 0, followingCount: 0, createAt: DateTime.now(), notificationSettings: {}
      );

      expect(user.friendsCount, 3);
    });

    test('TC-USR-02: CopyWith hoạt động đúng', () {
      final user = UserModel(
        id: 'u1', uid: 'uid1', name: 'Old Name', email: 'a@a.com', password: 'p', phone: '', bio: '', gender: '', liveAt: '', comeFrom: '', role: '', relationship: '', statusAccount: '', backgroundImageUrl: '', avatar: [],
        friends: [], groups: [], posterList: [], followerCount: 0, followingCount: 0, createAt: DateTime.now(), notificationSettings: {}
      );

      final newUser = user.copyWith(name: 'New Name');
      expect(newUser.name, 'New Name');
      expect(newUser.email, 'a@a.com'); // Không đổi
    });
    test('TC-USR-033: Kiểm thử với Dữ liệu thực tế (Real Data Mapping)', () {
      // 1. Giả lập Document ID (Cái này KHÔNG PHẢI LÀ UID)
      final String docId = 'user1759821679968';

      // 2. Giả lập dữ liệu bên trong (Chứa UID thật)
      final Map<String, dynamic> realData = {
        'avatar': [],
        'backgroundImageUrl': "",
        'bio': "No",
        'comeFrom': "Tay Ninh",
        // Giả lập Timestamp của Firestore bằng DateTime cho unit test
        'createAt': Timestamp.fromDate(DateTime(2025, 10, 7, 14, 21, 19)),
        'dateOfBirth': Timestamp.fromDate(DateTime(2025, 10, 13)),
        'email': "tien@gmail.com",
        'followerCount': 2,
        'followingCount': 4,
        'friends': [
          "user1759821679969",
          "user1759821679974",
          "user1759821679977",
          "user1759821679970"
        ],
        'gender': "Nam",
        'groups': [
          "jjxKMIbslKgFRmLzZqh9",
          "IPhweKu0xKQWNPGFtKZW",
          "xOglJfAeh0O2ezTHovby",
          "T5El2Yx861NMj7odHqhj",
          "mqwXXDPCJfOa4N4Adx7H",
          "PH8ACFeqrFu503ztwGTT",
          "RNFGBM4se0Rma7umbxxz"
        ],
        'lastActive': Timestamp.fromDate(DateTime(2025, 10, 7, 14, 21, 19)),
        'liveAt': "HCM",
        'locketFriends': [
          "user1759821679970",
          "user1759821679969"
        ],
        'name': "Minh Tiến",
        'notificationSettings': {
          'comments': true,
          'friendRequests': true,
          'likes': true,
          'messages': true,
          'tags': true
        },
        'password': "Susu@123",
        'phone': "0329860362",
        'posterList': [],
        'relationship': "Đã kết hôn",
        'role': "user",
        'servicegemini': false,
        'statusAccount': "active",
        'uid': "VTzc9f6qyOR3PNOHT5FXDMEOdSA3" // <--- ĐÂY MỚI LÀ UID
      };

      // Giả lập hành vi của UserModel.fromFirestore
      // Vì không thể mock DocumentSnapshot dễ dàng, ta dùng constructor và truyền dữ liệu đã parse
      // Hoặc nếu bạn có phương thức fromMap tách biệt thì dùng nó.
      // Ở đây ta test logic mapping thủ công tương đương logic trong fromFirestore của bạn.
      
      final user = UserModel(
        id: docId, // Map docId vào id
        uid: realData['uid'], // Map data['uid'] vào uid
        name: realData['name'],
        email: realData['email'],
        password: realData['password'],
        phone: realData['phone'],
        bio: realData['bio'],
        gender: realData['gender'],
        liveAt: realData['liveAt'],
        comeFrom: realData['comeFrom'],
        role: realData['role'],
        relationship: realData['relationship'],
        statusAccount: realData['statusAccount'],
        backgroundImageUrl: realData['backgroundImageUrl'],
        avatar: List<String>.from(realData['avatar']),
        friends: List<String>.from(realData['friends']),
        groups: List<String>.from(realData['groups']),
        posterList: List<String>.from(realData['posterList']),
        followerCount: realData['followerCount'],
        followingCount: realData['followingCount'],
        createAt: (realData['createAt'] as Timestamp).toDate(),
        dateOfBirth: (realData['dateOfBirth'] as Timestamp).toDate(),
        notificationSettings: Map<String, bool>.from(realData['notificationSettings']),
        locketFriends: List<String>.from(realData['locketFriends']),
      );

      // --- ASSERTIONS (Kiểm tra kết quả) ---
      
      // 1. Kiểm tra sự phân biệt giữa ID và UID
      expect(user.id, 'user1759821679968', reason: 'ID phải là Document ID');
      expect(user.uid, 'VTzc9f6qyOR3PNOHT5FXDMEOdSA3', reason: 'UID phải lấy từ field uid');
      expect(user.id, isNot(equals(user.uid)), reason: 'ID và UID không được trùng nhau');

      // 2. Kiểm tra các dữ liệu khác
      expect(user.name, 'Minh Tiến');
      expect(user.friendsCount, 4); // List friends có 4 phần tử
      expect(user.groups.length, 7);
      expect(user.notificationSettings['messages'], true);
    });
  });
}