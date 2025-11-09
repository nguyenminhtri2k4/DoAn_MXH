
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
import 'package:mangxahoi/view/locket/locket_view.dart'; 
import 'package:mangxahoi/view/notification_view.dart'; 
import 'package:mangxahoi/services/call_service.dart';
import 'package:mangxahoi/model/model_user.dart'; // Import UserModel

// --- IMPORT MỚI CHO STORY ---
import 'package:mangxahoi/model/model_story.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangxahoi/view/story/story_viewer_screen.dart';
// -----------------


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
        final userService = context.read<UserService>(); 
        context.read<CallService>().init(userService); 
        
        // --- THÊM DÒNG NÀY ---
        // Bắt đầu lắng nghe story
        context.read<HomeViewModel>().listenToStories(context);
        // --------------------
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

  // --- WIDGET TẠO BÀI VIẾT (MỚI) ---
  Widget _buildCreatePostSection(BuildContext context, UserModel? currentUser) {
     return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white, // Nền trắng
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: (currentUser?.avatar.isNotEmpty ?? false)
                ? NetworkImage(currentUser!.avatar.first)
                : null,
            child: (currentUser?.avatar.isEmpty ?? true)
                ? const Icon(Icons.person, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/create_post', arguments: currentUser),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white, // Nền trắng
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey[300]!) // Thêm viền
                ),
                child: const Text(
                  'Bạn đang nghĩ gì?',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/create_post', arguments: currentUser), 
            icon: Icon(Icons.photo_library, color: Colors.green[400], size: 28),
          ),
        ],
      ),
    );
  }
  // ---------------------------------------------
  
  // --- WIDGET DANH SÁCH STORY (MỚI) ---
  Widget _buildStories(BuildContext context, HomeViewModel vm, UserModel? currentUser) {
    final storiesByUser = vm.stories;
    
    // Tạo danh sách ID theo thứ tự: 1. Chính bạn, 2. Bạn bè
    final List<String> orderedUserIds = [currentUser?.id ?? ''];
    orderedUserIds.addAll(
      storiesByUser.keys.where((id) => id != currentUser?.id)
    );
    
    // Lọc ra các ID rỗng hoặc không có story
    final validUserIds = orderedUserIds
      .where((id) => id.isNotEmpty && storiesByUser.containsKey(id))
      .toSet() // Loại bỏ trùng lặp
      .toList();

    return Container(
      height: 190,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // +1 cho nút "Tạo Story"
        itemCount: validUserIds.length + 1,
        itemBuilder: (context, index) {
          
          if (index == 0) {
            return _buildCreateStoryCard(context, currentUser);
          }

          // Story item (index - 1 vì index 0 là nút tạo)
          final userId = validUserIds[index - 1];
          final userStories = storiesByUser[userId] ?? [];
          if (userStories.isEmpty) return const SizedBox.shrink();
          
          // Lấy story mới nhất của user đó để làm ảnh bìa
          final latestStory = userStories.first; 
          final author = context.read<FirestoreListener>().getUserById(latestStory.authorId);

          return _buildStoryCard(context, latestStory, author, userStories);
        },
      ),
    );
  }

  // --- WIDGET NÚT TẠO STORY (MỚI) ---
  Widget _buildCreateStoryCard(BuildContext context, UserModel? currentUser) {
    return GestureDetector(
      onTap: () {
        // Điều hướng đến trang tạo story mới
        Navigator.pushNamed(context, '/create_story');
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!)
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh avatar của user
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: (currentUser?.avatar.isNotEmpty ?? false)
                  ? CachedNetworkImage(
                      imageUrl: currentUser!.avatar.first,
                      fit: BoxFit.cover,
                      height: 110, // Nửa trên
                    )
                  : Container(
                      height: 110,
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
            ),
            // Nửa dưới
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80, // Nửa dưới
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text('Tạo tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
            ),
            // Nút dấu cộng
            Positioned(
              bottom: 30, // Nằm giữa 2 phần
              left: 35,
              right: 35,
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET THẺ STORY (MỚI) ---
  Widget _buildStoryCard(BuildContext context, StoryModel story, UserModel? author, List<StoryModel> userStories) {
    return GestureDetector(
      onTap: () {
        // Điều hướng đến trang xem story
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryViewerScreen(
              stories: userStories, // Chỉ truyền story của user này
              initialIndex: 0, // Bắt đầu từ story mới nhất
            ),
          ),
        );
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[300],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ảnh bìa của story
              if (story.mediaType == 'image' || story.mediaType == 'video')
                CachedNetworkImage(
                  imageUrl: story.mediaUrl,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(color: Colors.grey),
                )
              else
                Container( // Story text
                  color: story.backgroundColor.isNotEmpty 
                       ? Color(int.parse(story.backgroundColor.split('(0x')[1].split(')')[0], radix: 16)) 
                       : Colors.blue,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        story.content, 
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),

              // Lớp phủ tối
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: const Alignment(0.0, 0.3),
                  ),
                ),
              ),

              // Avatar tác giả
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: (author?.avatar.isNotEmpty ?? false)
                        ? CachedNetworkImageProvider(author!.avatar.first)
                        : null,
                    child: (author?.avatar.isEmpty ?? true)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
              ),

              // Tên tác giả
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  author?.name ?? 'Người dùng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    shadows: [Shadow(blurRadius: 5, color: Colors.black87)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- KẾT THÚC CÁC HÀM STORY ---

  Widget _buildHomePageBody(BuildContext context) {
    final homeViewModel = context.watch<HomeViewModel>();
    final userService = context.watch<UserService>();
    final currentUser = userService.currentUser;

    // Lấy chiều cao màn hình để tính cacheExtent
    final double screenHeight = MediaQuery.of(context).size.height;

    if (userService.isLoading || currentUser == null) {
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

    final currentUserId = currentUser.id;
    final posts = homeViewModel.posts;

    // --- SỬA ĐỔI BODY ĐỂ DÙNG CUSTOMSCROLLVIEW ---
    return RefreshIndicator(
      onRefresh: () => context.read<HomeViewModel>().refreshPosts(context),
      child: CustomScrollView( // Đổi ListView thành CustomScrollView
        controller: _scrollController,
        cacheExtent: screenHeight * 1.5,
        slivers: [
          // Thêm 3 mục này vào đầu
          SliverToBoxAdapter(
            child: _buildCreatePostSection(context, currentUser),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 200, // Chiều cao của story bar
              color: Colors.white,
              child: _buildStories(context, homeViewModel, currentUser),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(height: 8, color: AppColors.background), // Phân cách
          ),

          // Hiển thị bài viết
          if (homeViewModel.isLoading && posts.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                heightFactor: 10,
                child: CircularProgressIndicator(),
              ),
            )
          else if (posts.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                heightFactor: 10,
                child: Text('Chưa có bài viết nào.'),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return PostWidget(
                    key: ValueKey(posts[index].id),
                    post: posts[index],
                    currentUserDocId: currentUserId,
                  );
                },
                childCount: posts.length,
              ),
            ),

          // Widget loading
          if (homeViewModel.hasMore)
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
    // --- KẾT THÚC SỬA ĐỔI BODY ---
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