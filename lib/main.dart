
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/view/login_view.dart';
import 'package:mangxahoi/view/register_view.dart';
import 'package:mangxahoi/view/home_view.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart'; // Đảm bảo import này đúng
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
import 'package:mangxahoi/model/model_group.dart'; // Đổi tên file nếu cần
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/services/video_cache_manager.dart';
import 'package:mangxahoi/view/post/share_post_view.dart';
import 'package:mangxahoi/view/share_to_messenger_view.dart';
import 'package:mangxahoi/view/post/post_detail_view.dart';
import 'package:mangxahoi/view/post/edit_post_view.dart'; // Import EditPostView
import 'package:mangxahoi/view/trash_view.dart';
import 'package:mangxahoi/view/locket/locket_manage_friends_view.dart'; // Locket: Quản lý bạn bè
import 'package:mangxahoi/view/locket/my_locket_history_view.dart'; // Locket: Lịch sử của tôi
import 'package:mangxahoi/view/locket/locket_trash_view.dart'; // Locket: Thùng rác

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Cấu hình này có thể không cần thiết nếu bạn không dùng phone auth test
  // await FirebaseAuth.instance.setSettings(
  //   appVerificationDisabledForTesting: true,
  // );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirestoreListener()), // Theo dõi thay đổi Firestore
        ChangeNotifierProvider(create: (_) => UserService()),     // Quản lý thông tin user đăng nhập
        ChangeNotifierProvider(create: (_) => VideoCacheManager()),// Quản lý cache video
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false, // Tắt banner debug
        title: 'Mạng Xã Hội', // Tiêu đề ứng dụng
        theme: ThemeData( // Theme chung
          primarySwatch: Colors.blue, // Màu chủ đạo
          useMaterial3: true, // Sử dụng Material 3 design
        ),
        initialRoute: '/login', // Màn hình bắt đầu
        // Xử lý các route cần truyền tham số phức tạp
        onGenerateRoute: (settings) {
          switch (settings.name) {
            // Route đến trang cá nhân (có thể của mình hoặc người khác)
            case '/profile':
              final userId = settings.arguments as String?; // Lấy userId từ arguments
              return MaterialPageRoute(builder: (context) => ProfileView(userId: userId));
            
            // Route đến trang tạo bài viết
            case '/create_post':
              // Xử lý trường hợp chỉ truyền currentUser (đăng lên tường nhà)
              if (settings.arguments is UserModel) {
                final user = settings.arguments as UserModel;
                return MaterialPageRoute(
                  builder: (context) => CreatePostView(currentUser: user),
                );
              } 
              // Xử lý trường hợp truyền cả currentUser và groupId (đăng lên nhóm)
              else if (settings.arguments is Map<String, dynamic>) {
                final args = settings.arguments as Map<String, dynamic>;
                final user = args['currentUser'] as UserModel;
                final groupId = args['groupId'] as String?; // groupId có thể null
                return MaterialPageRoute(
                  builder: (context) => CreatePostView(
                    currentUser: user,
                    groupId: groupId,
                  ),
                );
              }
              // Trả về null nếu arguments không hợp lệ
              return null; 
            
            // Route đến trang sửa bài viết
            case '/edit_post':
               if (settings.arguments is PostModel) { // Kiểm tra kiểu dữ liệu
                final post = settings.arguments as PostModel;
                return MaterialPageRoute(builder: (context) => EditPostView(post: post));
               }
               return null;

            // Route đến trang chỉnh sửa thông tin cá nhân
            case '/edit_profile':
              // Cần kiểm tra kiểu dữ liệu nếu có thể truyền khác ProfileViewModel
              if (settings.arguments is ProfileViewModel) {
                final viewModel = settings.arguments as ProfileViewModel;
                return MaterialPageRoute(builder: (context) => EditProfileView(viewModel: viewModel));
              }
               return null;
              
            // Route đến trang "Giới thiệu" trong profile
            case '/about':
              if (settings.arguments is Map<String, dynamic>) {
                final args = settings.arguments as Map<String, dynamic>;
                final viewModel = args['viewModel'] as ProfileViewModel;
                final isCurrentUser = args['isCurrentUser'] as bool;
                return MaterialPageRoute(builder: (context) => AboutView(viewModel: viewModel, isCurrentUser: isCurrentUser));
              }
               return null;
              
            // Route đến màn hình chat (nhóm hoặc đơn)
            case '/chat':
              if (settings.arguments is Map<String, dynamic>) {
                 final args = settings.arguments as Map<String, dynamic>;
                 // Đảm bảo chatId và chatName được truyền đúng
                 final chatId = args['chatId'] as String?;
                 final chatName = args['chatName'] as String?;
                 if (chatId != null && chatName != null) {
                    return MaterialPageRoute(builder: (context) => ChatView(chatId: chatId, chatName: chatName));
                 }
              }
              return null;
              
            // Route đến trang xem các bài viết trong nhóm
            case '/post_group':
              if (settings.arguments is GroupModel) {
                 final group = settings.arguments as GroupModel;
                 return MaterialPageRoute(builder: (context) => PostGroupView(group: group));
              }
               return null;
            
            // Route đến trang chia sẻ lại bài viết
            case '/share_post':
              if (settings.arguments is Map<String, dynamic>) {
                 final args = settings.arguments as Map<String, dynamic>;
                 final originalPost = args['originalPost'] as PostModel?;
                 final currentUser = args['currentUser'] as UserModel?;
                 if (originalPost != null && currentUser != null) {
                    return MaterialPageRoute(builder: (context) => SharePostView(originalPost: originalPost, currentUser: currentUser));
                 }
              }
               return null;

            // Route đến trang chọn người/nhóm để chia sẻ qua tin nhắn
            case '/share_to_messenger':
              if (settings.arguments is PostModel) {
                 final post = settings.arguments as PostModel;
                 return MaterialPageRoute(builder: (context) => ShareToMessengerView(postToShare: post));
              }
               return null;

            // Route đến trang chi tiết bài viết
            case '/post_detail':
              if (settings.arguments is String) {
                 final postId = settings.arguments as String;
                 return MaterialPageRoute(builder: (context) => PostDetailView(postId: postId));
              }
               return null;

            // Route mặc định nếu không khớp
            default:
              return null;
          }
        },
        // Danh sách các route cố định (không cần truyền tham số phức tạp)
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
          '/trash': (context) => const TrashView(), // Thùng rác bài viết
          // Routes cho Locket
          '/locket_manage_friends': (context) => const LocketManageFriendsView(),
          '/my_locket_history': (context) => const MyLocketHistoryView(),
          //'/locket_trash': (context) => const LocketTrashView(), // Thùng rác Locket
        },
      ),
    );
  }
}