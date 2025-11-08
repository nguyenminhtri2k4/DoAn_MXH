import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/home_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:mangxahoi/view/friends_view.dart';
import 'package:mangxahoi/view/profile/profile_view.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:mangxahoi/view/video_feed_view.dart';
import 'package:mangxahoi/services/video_cache_manager.dart';
import 'package:mangxahoi/view/locket/locket_view.dart'; // <--- THÊM MỚI
import 'package:mangxahoi/view/notification_view.dart'; // <--- VẪN GIỮ (để dùng cho nút trên AppBar)
import 'package:provider/provider.dart';
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/view/video_feed_view.dart';


class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeViewModel(),
      child: const _HomeViewContent(),
    );
  }
}

class _HomeViewContent extends StatefulWidget {
  const _HomeViewContent();

  @override
  State<_HomeViewContent> createState() => _HomeViewContentState();
}

class _HomeViewContentState extends State<_HomeViewContent> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isVisible = true;
  bool _isPostsLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { 
        // Lấy UserService từ Provider
        final userService = context.read<UserService>(); 
        // Khởi động CallService và truyền UserService vào
        context.read<CallService>().init(userService); 
      }
    });
    _scrollController.addListener(_handleScroll);
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        context.read<HomeViewModel>().fetchMorePosts(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_selectedIndex != 0) return;

    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _isVisible) {
      setState(() => _isVisible = false);
    } else if (direction == ScrollDirection.forward && !_isVisible) {
      setState(() => _isVisible = true);
    }
  }

  void _onTabTapped(int index) {
    if (index == 0 && _selectedIndex == 0) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    setState(() {
      _selectedIndex = index;
      if (index != 0) {
        _isVisible = false; 
      } else {
        _isVisible = _scrollController.hasClients ? _scrollController.position.pixels < kToolbarHeight : true;
      }
    });
  }

  Widget _buildHomePageBody(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();
    final userService = context.watch<UserService>();

    if (userService.isLoading || userService.currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (!homeViewModel.isLoading && homeViewModel.posts.isEmpty && !_isPostsLoading) {
      _isPostsLoading = true; 
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<HomeViewModel>().fetchInitialPosts(context).then((_) {
          if (mounted) {
            _isPostsLoading = false;
          }
        });
      });
    }

    final currentUserId = userService.currentUser!.id;
    final posts = homeViewModel.posts;

    if (homeViewModel.isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (posts.isEmpty) {
      return const Center(child: Text('Chưa có bài viết nào.'));
    }

    return RefreshIndicator(
      onRefresh: () => context.read<HomeViewModel>().refreshPosts(context),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 10,
          bottom: 85,
        ),
        itemCount: posts.length + (homeViewModel.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return PostWidget(
            post: posts[index],
            currentUserDocId: currentUserId,
          );
        },
      ),
    );
  }

    Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(
        text,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.read<HomeViewModel>();
    final isHomePage = _selectedIndex == 0;
    final showUI = !isHomePage || _isVisible;

    // *** DANH SÁCH PAGES ĐÃ CẬP NHẬT ***
    final List<Widget> pages = [
      _buildHomePageBody(context),
      const FriendsView(),
      const VideoFeedView(),
      const LocketView(), // <--- THAY ĐỔI
      const ProfileView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: isHomePage,
      appBar: isHomePage
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, showUI ? 0 : -(kToolbarHeight + MediaQuery.of(context).padding.top), 0),
                child: Consumer<UserService>(
                  builder: (context, userService, child) => AppBar(
                    leading: Builder(
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: CircleAvatar(
                            backgroundImage: userService.currentUser?.avatar.isNotEmpty == true
                                ? NetworkImage(userService.currentUser!.avatar.first)
                                : null,
                            child: userService.currentUser?.avatar.isEmpty ?? true
                                ? const Icon(Icons.person, size: 20)
                                : null,
                          ),
                        ),
                      ),
                    ),
                    title: AppColors.logosybau.isNotEmpty
                        ? Image.asset(
                            AppColors.logosybau,
                            height: 300,
                            fit: BoxFit.contain,
                          )
                        : const Text('Mạng Xã Hội'),
                    centerTitle: true,
                    backgroundColor: AppColors.backgroundLight.withOpacity(0.95),
                    elevation: 1,
                    // *** ACTIONS ĐÃ CẬP NHẬT ***
                    actions: [
                      _buildCircularIconButton(
                        icon: Icons.search,
                        onPressed: () => Navigator.pushNamed(context, '/search'),
                      ),
                      _buildCircularIconButton( // <--- NÚT THÔNG BÁO
                        icon: Icons.notifications_outlined,
                        onPressed: () {
                          // Mở trang thông báo
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationView()),
                           );
                        },
                      ),
                      _buildCircularIconButton(
                        icon: Icons.message_outlined,
                        onPressed: () => Navigator.pushNamed(context, '/messages'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            )
          : null,
      drawer: Consumer<UserService>(
        builder: (context, userService, child) => Drawer(
          backgroundColor: AppColors.background,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage: userService.currentUser?.avatar.isNotEmpty == true
                          ? NetworkImage(userService.currentUser!.avatar.first) : null,
                      child: userService.currentUser?.avatar.isEmpty ?? true
                          ? const Icon(Icons.person, size: 40, color: AppColors.primary) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(userService.currentUser?.name ?? 'Đang tải...', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(userService.currentUser?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDrawerItem(
                        icon: Icons.home_outlined,
                        text: 'Trang chủ',
                        onTap: () {
                          Navigator.pop(context);
                          _onTabTapped(0);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.people_outline,
                        text: 'Bạn bè',
                        onTap: () {
                          Navigator.pop(context);
                          _onTabTapped(1);
                        },
                      ),
                      _buildDrawerItem(
            icon: Icons.people_alt_outlined,
            text: 'Theo dõi',
            onTap: () {
              Navigator.pop(context);
              if (userService.currentUser != null) {
                // Gọi route '/follow' đã đăng ký ở main.dart
                Navigator.pushNamed(
                  context,
                  '/follow',
                  arguments: {
                    'userId': userService.currentUser!.id,
                    'initialIndex': 0,
                  },
                );
              }
            },
          ),
                      _buildDrawerItem(
                        icon: Icons.group_outlined,
                        text: 'Nhóm',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/groups');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.person_outline,
                        text: 'Trang cá nhân',
                        onTap: () {
                          Navigator.pop(context);
                          _onTabTapped(4);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                        _buildDrawerItem(
                          icon: Icons.delete_outline,
                          text: 'Thùng rác (Bài viết)',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/trash');
                          },
                        ),
                        // === THÊM MỤC NÀY ===
                        _buildDrawerItem(
                          icon: Icons.delete_sweep_outlined, // Icon khác
                          text: 'Thùng rác Locket',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/locket_trash');
                          },
                        ),
                        // ======================
                        _buildDrawerItem(
                          icon: Icons.block,
                          text: 'Danh sách chặn',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/blocked_list');
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.notifications_active_outlined,
                          text: 'Cài đặt thông báo',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/notification_settings');
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildDrawerItem(
                  icon: Icons.logout,
                  text: 'Đăng xuất',
                  onTap: () {
                    context.read<VideoCacheManager>().pauseAllVideos();
                    homeViewModel.signOut(context);
                  },
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isHomePage
          ? Consumer<UserService>(
              builder: (context, userService, child) => AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: showUI ? 1.0 : 0.0,
                child: FloatingActionButton(
                  onPressed: () async {
                    if (userService.currentUser != null) {
                      await Navigator.pushNamed(context, '/create_post', arguments: userService.currentUser);
                      if (mounted) {
                        context.read<HomeViewModel>().refreshPosts(context);
                      }
                    }
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.edit),
                ),
              ),
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      // *** BOTTOMNAVBAR ĐÃ CẬP NHẬT ***
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: showUI ? 85.0 : 0.0,
        child: Wrap(
          children: [
            Container(
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
                    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Bạn bè'),
                    BottomNavigationBarItem(icon: Icon(Icons.ondemand_video), label: 'Video'),
                    BottomNavigationBarItem(icon: Icon(Icons.lock_outline), label: 'Locket'), // <--- THAY ĐỔI
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: Colors.grey,
                  onTap: _onTabTapped,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 24, color: AppColors.textPrimary),
        onPressed: onPressed,
      ),
    );
  }
}