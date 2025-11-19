
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/view/login_view.dart';
import 'package:mangxahoi/view/register_view.dart';
import 'package:mangxahoi/view/home_view.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/view/profile/profile_view.dart';
import 'package:mangxahoi/view/post/create_post_view.dart';
import 'package:mangxahoi/view/search_view.dart';
import 'package:mangxahoi/view/friends_view.dart';
import 'package:mangxahoi/view/group_chat/groups_view.dart';
import 'package:mangxahoi/view/group_chat/create_group_view.dart';
import 'package:mangxahoi/view/group_chat/chat_view.dart';
import 'package:mangxahoi/view/blocked_list_view.dart';
import 'package:mangxahoi/view/notification_settings_view.dart';
import 'package:mangxahoi/view/profile/edit_profile_view.dart';
import 'package:mangxahoi/view/profile/about_view.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';
import 'package:mangxahoi/view/messages_view.dart';
import 'package:mangxahoi/view/group_chat/post_group_view.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/services/video_cache_manager.dart';
import 'package:mangxahoi/view/post/share_post_view.dart';
import 'package:mangxahoi/view/share_to_messenger_view.dart';
import 'package:mangxahoi/view/post/post_detail_view.dart';
import 'package:mangxahoi/view/post/edit_post_view.dart';
import 'package:mangxahoi/view/trash_view.dart';
import 'package:mangxahoi/view/locket/locket_manage_friends_view.dart';
import 'package:mangxahoi/view/locket/my_locket_history_view.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:mangxahoi/services/sound_service.dart';
import 'package:mangxahoi/view/follow_viewer.dart';

import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:mangxahoi/view/group_chat/add_members_view.dart';
import 'package:mangxahoi/view/group_chat/group_management_view.dart';
import 'package:mangxahoi/view/locket/locket_trash_view.dart';
import 'package:mangxahoi/constant/app_colors.dart';

// --- CÁC IMPORT STORY VÀ KHÁC ---
import 'package:mangxahoi/view/story/create_story_view.dart';
import 'package:mangxahoi/view/group_chat/qr_scanner_view.dart';
import 'package:mangxahoi/view/group_chat/group_qr_code_view.dart';
import 'package:mangxahoi/view/profile/friend_list_view.dart';
import 'package:mangxahoi/view/profile/user_groups_view.dart';
// --------------------------------

// 🔥 IMPORT CHO PUSH NOTIFICATION
import 'package:mangxahoi/notification/push_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mangxahoi/services/notification_badge_service.dart';
import 'package:mangxahoi/viewmodel/notification_view_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 Khởi tạo Push Notification Service (Lắng nghe events)
  if (!kIsWeb) {
    await PushNotificationService().initialize();
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Đổi tên biến để bao hàm cả CallService và FCM Token
  bool _hasInitializedAppServices = false; 

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirestoreListener()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => VideoCacheManager()),
        ChangeNotifierProvider(create: (_) => NotificationBadgeService()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(
          create: (_) => CallService(navigatorKey: navigatorKey),
        ),
        Provider<SoundService>(
          create: (_) => SoundService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: Consumer<UserService>(
        builder: (context, userService, _) {
          // Khởi tạo các service cần thiết khi user đã được tải và chưa khởi tạo
          if (userService.currentUser != null &&
              !userService.isLoading &&
              !_hasInitializedAppServices) { // 🔥 Đã đổi tên biến
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initAppServices(context, userService); // 🔥 Đã đổi tên hàm
            });
          }

          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Mạng Xã Hội',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
            home: _buildHomeScreen(userService),
            // ... (onGenerateRoute và routes giữ nguyên logic)
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/profile':
                  final userId = settings.arguments as String?;
                  return MaterialPageRoute(
                    builder: (context) => ProfileView(userId: userId),
                  );
                case '/create_post':
                  if (settings.arguments is UserModel) {
                    final user = settings.arguments as UserModel;
                    return MaterialPageRoute(
                      builder: (context) => CreatePostView(currentUser: user),
                    );
                  } else if (settings.arguments is Map<String, dynamic>) {
                    final args = settings.arguments as Map<String, dynamic>;
                    final user = args['currentUser'] as UserModel;
                    final groupId = args['groupId'] as String?;
                    return MaterialPageRoute(
                      builder: (context) => CreatePostView(
                        currentUser: user,
                        groupId: groupId,
                      ),
                    );
                  }
                  return _buildErrorRoute();
                case '/edit_post':
                  if (settings.arguments is PostModel) {
                    final post = settings.arguments as PostModel;
                    return MaterialPageRoute(
                      builder: (context) => EditPostView(post: post),
                    );
                  }
                  return _buildErrorRoute();
                case '/edit_profile':
                  if (settings.arguments is ProfileViewModel) {
                    final viewModel = settings.arguments as ProfileViewModel;
                    return MaterialPageRoute(
                      builder: (context) =>
                          EditProfileView(viewModel: viewModel),
                    );
                  }
                  return _buildErrorRoute();
                case '/about':
                  if (settings.arguments is Map<String, dynamic>) {
                    final args = settings.arguments as Map<String, dynamic>;
                    final viewModel = args['viewModel'] as ProfileViewModel;
                    final isCurrentUser = args['isCurrentUser'] as bool;
                    return MaterialPageRoute(
                      builder: (context) => AboutView(
                        viewModel: viewModel,
                        isCurrentUser: isCurrentUser,
                      ),
                    );
                  }
                  return _buildErrorRoute();
                case '/chat':
                  if (settings.arguments is Map<String, dynamic>) {
                    final args = settings.arguments as Map<String, dynamic>;
                    final chatId = args['chatId'] as String?;
                    final chatName = args['chatName'] as String?;
                    if (chatId != null && chatName != null) {
                      return MaterialPageRoute(
                        builder: (context) => ChatView(
                          chatId: chatId,
                          chatName: chatName,
                        ),
                      );
                    }
                  }
                  return _buildErrorRoute();
                case '/post_group':
                  if (settings.arguments is GroupModel) {
                    final group = settings.arguments as GroupModel;
                    return MaterialPageRoute(
                      builder: (context) => PostGroupView(group: group),
                    );
                  }
                  return _buildErrorRoute();
                case '/share_post':
                  if (settings.arguments is Map<String, dynamic>) {
                    final args = settings.arguments as Map<String, dynamic>;
                    final originalPost = args['originalPost'] as PostModel?;
                    final currentUser = args['currentUser'] as UserModel?;
                    if (originalPost != null && currentUser != null) {
                      return MaterialPageRoute(
                        builder: (context) => SharePostView(
                          originalPost: originalPost,
                          currentUser: currentUser,
                        ),
                      );
                    }
                  }
                  return _buildErrorRoute();
                case '/share_to_messenger':
                  if (settings.arguments is PostModel) {
                    final post = settings.arguments as PostModel;
                    return MaterialPageRoute(
                      builder: (context) =>
                          ShareToMessengerView(postToShare: post),
                    );
                  }
                  return _buildErrorRoute();
                case '/group_qr':
                  if (settings.arguments is Map<String, dynamic>) {
                    final args = settings.arguments as Map<String, dynamic>;
                    final group = args['group'] as GroupModel;
                    final userName = args['userName'] as String;
                    return MaterialPageRoute(
                      builder: (context) => GroupQRCodeView(
                        group: group,
                        currentUserName: userName,
                      ),
                    );
                  }
                  return _buildErrorRoute();
                case '/post_detail':
                  if (settings.arguments is String) {
                    final postId = settings.arguments as String;
                    return MaterialPageRoute(
                      builder: (context) => PostDetailView(postId: postId),
                    );
                  }
                  return _buildErrorRoute();
                default:
                  return _buildErrorRoute();
              }
            },
            routes: {
              '/login': (context) => const LoginView(),
              '/register': (context) => const RegisterView(),
              '/home': (context) => const HomeView(),
              '/search': (context) => const SearchView(),
              '/friends': (context) {
                final arguments = ModalRoute.of(context)?.settings.arguments;
                int initialIndex = 0;
                if (arguments is int) {
                  initialIndex = arguments;
                }
                return FriendsView(initialIndex: initialIndex);
              },
              '/friend_list': (context) {
                final args = ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>?;
                if (args != null &&
                    args['userId'] != null &&
                    args['userName'] != null) {
                  return FriendListView(
                    userId: args['userId'],
                    userName: args['userName'],
                  );
                }
                return _buildErrorWidget();
              },
              '/groups': (context) => const GroupsView(),
              '/create_group': (context) => const CreateGroupView(),
              '/blocked_list': (context) => const BlockedListView(),
              '/notification_settings': (context) =>
                  const NotificationSettingsView(),
              '/messages': (context) => const MessagesView(),
              '/trash': (context) => const TrashView(),
              '/locket_manage_friends': (context) =>
                  const LocketManageFriendsView(),
              '/my_locket_history': (context) => const MyLocketHistoryView(),
              '/locket_trash': (context) => const LocketTrashView(),
              '/qr_scanner': (context) => const QRScannerView(),
              '/follow': (context) {
                final args = ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>?;
                if (args != null) {
                  return FollowViewer(
                    userId: args['userId'],
                    initialIndex: args['initialIndex'] ?? 0,
                  );
                }
                return _buildErrorWidget();
              },
              '/user_groups': (context) {
                  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                  return UserGroupsView(
                    userId: args['userId'],
                    userName: args['userName'],
                  );
                },
              '/group_management': (context) {
                final args = ModalRoute.of(context)!.settings.arguments;
                if (args is String) {
                  return GroupManagementView(groupId: args);
                }
                return _buildErrorWidget();
              },
              '/add_members': (context) {
                final args = ModalRoute.of(context)!.settings.arguments;
                if (args is String) {
                  return AddMembersView(groupId: args);
                }
                return _buildErrorWidget();
              },
              '/create_story': (context) => const CreateStoryView(),
            },
          );
        },
      ),
    );
  }

  // 🔥 HÀM MỚI: Khởi tạo tất cả các service (CallService, FCM Token)
  Future<void> _initAppServices(
      BuildContext context, UserService userService) async {
    if (_hasInitializedAppServices || userService.currentUser == null) return;

    if (!kIsWeb) {
      try {
        final currentUser = userService.currentUser!;
        
        // 1. Khởi tạo CallService
        final callService = context.read<CallService>();
        print("🚀 [MAIN] Đang init CallService...");
        await ZegoExpressEngine.destroyEngine();
        await callService.init(userService);
        
        // 2. LƯU FCM TOKEN (Quan trọng cho Push Notification)
        await _saveUserFcmToken(currentUser.uid);

        setState(() {
          _hasInitializedAppServices = true;
        });
        print("✅ [MAIN] CallService & FCM Token đã init thành công");
      } catch (e) {
        print("❌ [MAIN] Lỗi khi init CallService/FCM: $e");
      }
    } else {
      print("⚠️ [MAIN] Bỏ qua init CallService/FCM trên Web.");
    }
  }

  // 🔥 HÀM MỚI: Lưu Token vào Firestore
  Future<void> _saveUserFcmToken(String authUid) async {
    String? token = await FirebaseMessaging.instance.getToken();
    
    if (token != null) {
      // 1. Tìm Document User ID (DocId) bằng Auth UID
      final userQuery = await FirebaseFirestore.instance
          .collection('User')
          .where('uid', isEqualTo: authUid)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final docId = userQuery.docs.first.id;
        // 2. Cập nhật token vào Firestore
        await FirebaseFirestore.instance.collection('User').doc(docId).update({
          'fcmToken': token, 
        }).catchError((e) => print("❌ Lỗi update FCM Token: $e"));
      }
    }
  }


  Widget _buildHomeScreen(UserService userService) {
    print('🔍 [MyApp] Building home screen:');
    print('🔍 [MyApp] - isLoading: ${userService.isLoading}');
    print('🔍 [MyApp] - currentUser: ${userService.currentUser?.name}');

    if (userService.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải thông tin người dùng...'),
            ],
          ),
        ),
      );
    }

    if (userService.currentUser != null) {
      print('✅ [MyApp] Đã có user, chuyển đến HomeView');
      return const HomeView();
    }

    print('🔐 [MyApp] Chưa có user, chuyển đến LoginView');
    return const LoginView();
  }

  // --- (C) TÁCH WIDGET LỖI RA ĐÂY ---
  Widget _buildErrorWidget() {
    return Scaffold(
      appBar: AppBar(title: const Text('Lỗi')),
      body: const Center(
        child: Text('Lỗi: Không thể tải trang'),
      ),
    );
  }

  MaterialPageRoute _buildErrorRoute() {
    return MaterialPageRoute(
      builder: (context) => _buildErrorWidget(),
    );
  }
  // ---------------------------------

  @override
  void dispose() {
    if (!kIsWeb) {
      ZegoExpressEngine.destroyEngine();
    }
    super.dispose();
  }
}