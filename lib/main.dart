
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/view/login_view.dart';
import 'package:mangxahoi/view/register_view.dart';
import 'package:mangxahoi/view/home_view.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/view/profile_view.dart';
import 'package:mangxahoi/view/create_post_view.dart';
import 'package:mangxahoi/view/search_view.dart';
import 'package:mangxahoi/view/friends_view.dart';
import 'package:mangxahoi/view/groups_view.dart';
import 'package:mangxahoi/view/create_group_view.dart';
import 'package:mangxahoi/view/chat_view.dart'; // Thêm import này
import 'package:mangxahoi/view/blocked_list_view.dart';
import 'package:mangxahoi/view/notification_settings_view.dart';
import 'package:mangxahoi/view/edit_profile_view.dart';
import 'package:mangxahoi/view/about_view.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';

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
            case '/create_post':
              final user = settings.arguments as UserModel;
              return MaterialPageRoute(
                builder: (context) => CreatePostView(currentUser: user),
              );
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
            case '/chat': // Thêm case cho màn hình chat
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => ChatView(
                  chatId: args['chatId'],
                  chatName: args['chatName'],
                ),
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
        },
      ),
    );
  }
}