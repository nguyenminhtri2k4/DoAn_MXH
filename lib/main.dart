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
import 'package:mangxahoi/view/search_results_view.dart';

import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:mangxahoi/view/group_chat/add_members_view.dart';
import 'package:mangxahoi/view/group_chat/group_management_view.dart';
import 'package:mangxahoi/view/locket/locket_trash_view.dart';
import 'package:mangxahoi/constant/app_colors.dart';

// --- THÊM CÁC IMPORT STORY ---
import 'package:mangxahoi/view/story/create_story_view.dart';
import 'package:mangxahoi/view/group_chat/qr_scanner_view.dart';
import 'package:mangxahoi/view/group_chat/group_qr_code_view.dart';
// ------------------------------

// --- (A) THÊM IMPORT MỚI ---
import 'package:mangxahoi/view/profile/friend_list_view.dart';
import 'package:mangxahoi/view/profile/user_groups_view.dart';
// -------------------------

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasInitializedCallService = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirestoreListener()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => VideoCacheManager()),
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
          // Khởi tạo call service khi user đã được tải
          if (userService.currentUser != null &&
              !userService.isLoading &&
              !_hasInitializedCallService) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initCallService(context, userService);
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
                      builder:
                          (context) => CreatePostView(
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
                      builder:
                          (context) => EditProfileView(viewModel: viewModel),
                    );
                  }
                  return _buildErrorRoute();

                case '/about':
                  if (settings.arguments is Map<String, dynamic>) {
                    final args = settings.arguments as Map<String, dynamic>;
                    final viewModel = args['viewModel'] as ProfileViewModel;
                    final isCurrentUser = args['isCurrentUser'] as bool;
                    return MaterialPageRoute(
                      builder:
                          (context) => AboutView(
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
                        builder:
                            (context) =>
                                ChatView(chatId: chatId, chatName: chatName),
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
                        builder:
                            (context) => SharePostView(
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
                      builder:
                          (context) => ShareToMessengerView(postToShare: post),
                    );
                  }
                  return _buildErrorRoute();

                case '/group_qr':
                  if (settings.arguments is Map<String, dynamic>) {
                    final args = settings.arguments as Map<String, dynamic>;
                    final group = args['group'] as GroupModel;
                    final userName = args['userName'] as String;
                    return MaterialPageRoute(
                      builder:
                          (context) => GroupQRCodeView(
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
              '/search-results': (context) => const SearchResultsView(),
              '/friends': (context) {
                final arguments = ModalRoute.of(context)?.settings.arguments;
                int initialIndex = 0; // Mặc định là tab 0
                if (arguments is int) {
                  initialIndex = arguments; // Gán index nếu được truyền vào
                }
                return FriendsView(initialIndex: initialIndex);
              },
              '/friend_list': (context) {
                final args =
                    ModalRoute.of(context)!.settings.arguments
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
              '/notification_settings':
                  (context) => const NotificationSettingsView(),
              '/messages': (context) => const MessagesView(),
              '/trash': (context) => const TrashView(),
              '/locket_manage_friends':
                  (context) => const LocketManageFriendsView(),
              '/my_locket_history': (context) => const MyLocketHistoryView(),
              '/locket_trash': (context) => const LocketTrashView(),
              '/qr_scanner': (context) => const QRScannerView(),
              '/follow': (context) {
                final args =
                    ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>?;
                if (args != null) {
                  return FollowViewer(
                    userId: args['userId'],
                    initialIndex: args['initialIndex'] ?? 0,
                  );
                }
                return _buildErrorWidget(); // <-- SỬA: Gọi Widget
              },
              '/user_groups': (context) {
                final args =
                    ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>;
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
                return _buildErrorWidget(); // <-- SỬA: Gọi Widget
              },
              '/add_members': (context) {
                final args = ModalRoute.of(context)!.settings.arguments;
                if (args is String) {
                  return AddMembersView(groupId: args);
                }
                return _buildErrorWidget(); // <-- SỬA: Gọi Widget
              },
              '/create_story': (context) => const CreateStoryView(),
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeScreen(UserService userService) {
    print('🔍 [MyApp] Building home screen:');
    print('🔍 [MyApp] - isLoading: ${userService.isLoading}');
    print('🔍 [MyApp] - currentUser: ${userService.currentUser?.name}');

    // Đang loading
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

    // Đã có user -> HomeView
    if (userService.currentUser != null) {
      print('✅ [MyApp] Đã có user, chuyển đến HomeView');
      return const HomeView();
    }

    // Không có user -> LoginView
    print('🔐 [MyApp] Chưa có user, chuyển đến LoginView');
    return const LoginView();
  }

  // --- (C) TÁCH WIDGET LỖI RA ĐÂY ---
  /// Trả về một Widget lỗi (dùng cho 'routes')
  Widget _buildErrorWidget() {
    return Scaffold(
      // <-- SỬA: Bỏ 'const'
      appBar: AppBar(title: const Text('Lỗi')), // Thêm AppBar
      body: const Center(
        // Thêm const
        child: Text('Lỗi: Không thể tải trang'), // Thêm const
      ),
    );
  }

  /// Trả về một Route lỗi (dùng cho 'onGenerateRoute')
  MaterialPageRoute _buildErrorRoute() {
    return MaterialPageRoute(
      builder: (context) => _buildErrorWidget(), // Gọi lại widget lỗi
    );
  }
  // ---------------------------------

  Future<void> _initCallService(
    BuildContext context,
    UserService userService,
  ) async {
    if (_hasInitializedCallService) return;

    if (!kIsWeb) {
      try {
        final callService = context.read<CallService>();
        print("🚀 [MAIN] Đang init CallService...");
        await ZegoExpressEngine.destroyEngine();
        await callService.init(userService);
        setState(() {
          _hasInitializedCallService = true;
        });
        print("✅ [MAIN] CallService đã được init thành công");
      } catch (e) {
        print("❌ [MAIN] Lỗi khi init CallService: $e");
      }
    } else {
      print("⚠️ [MAIN] Bỏ qua init CallService trên Web.");
    }
  }

  @override
  void dispose() {
    // Cleanup khi app bị dispose
    if (!kIsWeb) {
      ZegoExpressEngine.destroyEngine();
    }
    super.dispose();
  }
}
