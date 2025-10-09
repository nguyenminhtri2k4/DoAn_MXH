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
        routes: {
          '/login': (context) => const LoginView(),
          '/register': (context) => const RegisterView(),
          '/home': (context) => const HomeView(),
          '/profile': (context) => const ProfileView(),
          '/create_post': (context) {
            final user = ModalRoute.of(context)!.settings.arguments as UserModel;
            return CreatePostView(currentUser: user);
          },
          '/search': (context) => const SearchView(), 
          '/friends': (context) => const FriendsView(),
        },
      ),
    );
  }
}