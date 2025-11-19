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

import 'package:mangxahoi/view/story/create_story_view.dart';
import 'package:mangxahoi/view/group_chat/qr_scanner_view.dart';
import 'package:mangxahoi/view/group_chat/group_qr_code_view.dart';
import 'package:mangxahoi/view/profile/friend_list_view.dart';
import 'package:mangxahoi/view/profile/user_groups_view.dart';

import 'package:mangxahoi/notification/push_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mangxahoi/services/notification_badge_service.dart';
import 'package:mangxahoi/viewmodel/notification_view_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await PushNotificationService().initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
          if (userService.currentUser != null &&
              !userService.isLoading &&
              !_hasInitializedAppServices) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initAppServices(context, userService);
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
                    return MaterialPageRoute(
                      builder:
                          (context) => CreatePostView(
                            currentUser: args['currentUser'],
                            groupId: args['groupId'],
                          ),
                    );
                  }
                  return _buildErrorRoute();

                case '/edit_post':
                  if (settings.arguments is PostModel) {
                    return MaterialPageRoute(
                      builder:
                          (context) => EditPostView(
                            post: settings.arguments as PostModel,
                          ),
                    );
                  }
                  return _buildErrorRoute();

                case '/edit_profile':
                  if (settings.arguments is ProfileViewModel) {
                    return MaterialPageRoute(
                      builder:
                          (context) => EditProfileView(
                            viewModel: settings.arguments as ProfileViewModel,
                          ),
                    );
                  }
                  return _buildErrorRoute();

                case '/about':
                  if (settings.arguments is Map<String, dynamic>) {
                    final args = settings.arguments as Map<String, dynamic>;
                    return MaterialPageRoute(
                      builder:
                          (context) => AboutView(
                            viewModel: args['viewModel'],
                            isCurrentUser: args['isCurrentUser'],
                          ),
                    );
                  }
                  return _buildErrorRoute();

                case '/chat':
                  if (settings.arguments is Map<String, dynamic>) {
                    final args = settings.arguments as Map<String, dynamic>;
                    return MaterialPageRoute(
                      builder:
                          (context) => ChatView(
                            chatId: args['chatId'],
                            chatName: args['chatName'],
                          ),
                    );
                  }
                  return _buildErrorRoute();

                case '/post_group':
                  if (settings.arguments is GroupModel) {
                    return MaterialPageRoute(
                      builder:
                          (context) => PostGroupView(
                            group: settings.arguments as GroupModel,
                          ),
                    );
                  }
                  return _buildErrorRoute();

                case '/share_post':
                  if (settings.arguments is Map<String, dynamic>) {
                    final args = settings.arguments as Map<String, dynamic>;
                    return MaterialPageRoute(
                      builder:
                          (context) => SharePostView(
                            originalPost: args['originalPost'],
                            currentUser: args['currentUser'],
                          ),
                    );
                  }
                  return _buildErrorRoute();

                case '/share_to_messenger':
                  if (settings.arguments is PostModel) {
                    return MaterialPageRoute(
                      builder:
                          (context) => ShareToMessengerView(
                            postToShare: settings.arguments as PostModel,
                          ),
                    );
                  }
                  return _buildErrorRoute();

                case '/group_qr':
                  if (settings.arguments is Map<String, dynamic>) {
                    final args = settings.arguments as Map<String, dynamic>;
                    return MaterialPageRoute(
                      builder:
                          (context) => GroupQRCodeView(
                            group: args['group'],
                            currentUserName: args['userName'],
                          ),
                    );
                  }
                  return _buildErrorRoute();

                case '/post_detail':
                  if (settings.arguments is String) {
                    return MaterialPageRoute(
                      builder:
                          (context) => PostDetailView(
                            postId: settings.arguments as String,
                          ),
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
                final args = ModalRoute.of(context)?.settings.arguments;
                return FriendsView(initialIndex: args is int ? args : 0);
              },
              '/friend_list': (context) {
                final args =
                    ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>?;
                if (args != null) {
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
                return _buildErrorWidget();
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

  Future<void> _initAppServices(
    BuildContext context,
    UserService userService,
  ) async {
    if (_hasInitializedAppServices || userService.currentUser == null) return;

    if (!kIsWeb) {
      try {
        final currentUser = userService.currentUser!;

        final callService = context.read<CallService>();
        await ZegoExpressEngine.destroyEngine();
        await callService.init(userService);

        await _saveUserFcmToken(currentUser.uid);

        setState(() {
          _hasInitializedAppServices = true;
        });
      } catch (e) {
        print("Lỗi khi init app services: $e");
      }
    }
  }

  Future<void> _saveUserFcmToken(String authUid) async {
    String? token = await FirebaseMessaging.instance.getToken();

    final userQuery =
        await FirebaseFirestore.instance
            .collection('User')
            .where('uid', isEqualTo: authUid)
            .limit(1)
            .get();

    if (userQuery.docs.isNotEmpty) {
      final docId = userQuery.docs.first.id;
      await FirebaseFirestore.instance.collection('User').doc(docId).update({
        'fcmToken': token,
      });
    }
  }

  Widget _buildHomeScreen(UserService userService) {
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
      return const HomeView();
    }

    return const LoginView();
  }

  Widget _buildErrorWidget() {
    return Scaffold(
      appBar: AppBar(title: const Text('Lỗi')),
      body: const Center(child: Text('Lỗi: Không thể tải trang')),
    );
  }

  MaterialPageRoute _buildErrorRoute() {
    return MaterialPageRoute(builder: (context) => _buildErrorWidget());
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      ZegoExpressEngine.destroyEngine();
    }
    super.dispose();
  }
}
