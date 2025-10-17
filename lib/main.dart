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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirestoreListener()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mạng Xã Hội',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/login',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/profile':
              final userId = settings.arguments as String?;
              return MaterialPageRoute(
                builder: (context) => ProfileView(userId: userId),
              );
            
            // ==========================================================
            // SỬA LỖI LOGIC ĐIỀU HƯỚNG TẠI ĐÂY
            // ==========================================================
            case '/create_post':
              // Kiểm tra xem tham số truyền vào là Map hay UserModel
              if (settings.arguments is Map<String, dynamic>) {
                // Trường hợp đăng bài trong nhóm
                final args = settings.arguments as Map<String, dynamic>;
                final user = args['currentUser'] as UserModel;
                final groupId = args['groupId'] as String?;
                return MaterialPageRoute(
                  builder: (context) => CreatePostView(
                    currentUser: user,
                    groupId: groupId,
                  ),
                );
              } else if (settings.arguments is UserModel) {
                // Trường hợp đăng bài cá nhân từ trang chủ
                final user = settings.arguments as UserModel;
                return MaterialPageRoute(
                  builder: (context) => CreatePostView(currentUser: user),
                );
              }
              return null; // Trả về null nếu tham số không hợp lệ

            case '/edit_profile':
              final viewModel = settings.arguments as ProfileViewModel;
              return MaterialPageRoute(
                builder: (context) => EditProfileView(viewModel: viewModel),
              );
            case '/about':
              final args = settings.arguments as Map<String, dynamic>;
              final viewModel = args['viewModel'] as ProfileViewModel;
              final isCurrentUser = args['isCurrentUser'] as bool;
              return MaterialPageRoute(
                builder: (context) => AboutView(
                  viewModel: viewModel,
                  isCurrentUser: isCurrentUser,
                ),
              );
            case '/chat':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => ChatView(
                  chatId: args['chatId'],
                  chatName: args['chatName'],
                ),
              );
            case '/post_group':
              final group = settings.arguments as GroupModel;
              return MaterialPageRoute(
                builder: (context) => PostGroupView(group: group),
              );
            default:
              return null;
          }
        },
        routes: {
          '/login': (context) => const LoginView(),
          '/register': (context) => const RegisterView(),
          '/home': (context) => const HomeView(),
          '/search': (context) => const SearchView(),
          '/friends': (context) => const FriendsView(),
          '/groups': (context) => const GroupsView(),
          '/create_group': (context) => const CreateGroupView(),
          '/blocked_list': (context) => const BlockedListView(),
          '/notification_settings': (context) => const NotificationSettingsView(),
          '/messages': (context) => const MessagesView(),
        },
      ),
    );
  }
}