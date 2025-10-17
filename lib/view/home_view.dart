
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/home_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:mangxahoi/view/friends_view.dart';
import 'package:mangxahoi/view/profile/profile_view.dart';
import 'package:mangxahoi/view/blocked_list_view.dart';

// Placeholder for Video and Notification views
class VideoView extends StatelessWidget {
  const VideoView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: Text('Trang Video')),
      ),
    );
  }
}

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: Text('Trang Thông Báo')),
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
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
      _isVisible = true;
    });
  }

  Widget _buildHomePageBody(HomeViewModel vm) {
    return (vm.isLoading || vm.currentUserData == null)
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<List<PostModel>>(
            stream: vm.postsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi tải bài đăng: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Chưa có bài viết nào.'));
              }
              final posts = snapshot.data!;
              return ListView.builder(
                controller: _scrollController,
                // SỬA Ở ĐÂY: Bỏ padding ngang (left, right)
                padding: EdgeInsets.only(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top,
                  bottom: 40,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return PostWidget(
                    post: posts[index],
                    currentUserDocId: vm.currentUserData!.id,
                  );
                },
              );
            },
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
    final vm = context.watch<HomeViewModel>();
    final isHomePage = _selectedIndex == 0;
    final showUI = !isHomePage || _isVisible;

    final List<Widget> pages = [
      _buildHomePageBody(vm),
      const FriendsView(),
      const VideoView(),
      const NotificationView(),
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
                child: AppBar(
                  leading: Builder(
                    builder: (context) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: CircleAvatar(
                          backgroundImage: vm.currentUserData?.avatar.isNotEmpty == true
                              ? NetworkImage(vm.currentUserData!.avatar.first)
                              : null,
                          child: vm.currentUserData?.avatar.isEmpty ?? true
                              ? const Icon(Icons.person, size: 20)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  title: AppColors.logosybau.isNotEmpty
                      ? Image.asset(
                          AppColors.logosybau,
                          height: 200,
                          fit: BoxFit.contain,
                        )
                      : const Text('Mạng Xã Hội'),
                  centerTitle: true,
                  backgroundColor: AppColors.backgroundLight.withOpacity(0.95),
                  elevation: 1,
                  actions: [
                    _buildCircularIconButton(
                      icon: Icons.search,
                      onPressed: () => Navigator.pushNamed(context, '/search'),
                    ),
                    _buildCircularIconButton(
                      icon: Icons.message_outlined,
                      onPressed: () => Navigator.pushNamed(context, '/messages'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            )
          : null,
      drawer: Drawer(
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
                      backgroundImage: vm.currentUserData?.avatar.isNotEmpty == true
                          ? NetworkImage(vm.currentUserData!.avatar.first) : null,
                      child: vm.currentUserData?.avatar.isEmpty ?? true
                          ? const Icon(Icons.person, size: 40, color: AppColors.primary) : null,
                    ),
                  const SizedBox(height: 12),
                  Text(vm.currentUserData?.name ?? 'Đang tải...', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(vm.currentUserData?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
                onTap: () => vm.signOut(context),
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isHomePage
          ? AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: showUI ? 1.0 : 0.0,
              child: FloatingActionButton(
                onPressed: () {
                  if (vm.currentUserData != null) {
                    Navigator.pushNamed(context, '/create_post', arguments: vm.currentUserData);
                  }
                },
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.edit),
              ),
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
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
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Trang chủ',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people),
                      label: 'Bạn bè',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.ondemand_video),
                      label: 'Video',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.notifications),
                      label: 'Thông báo',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Cá nhân',
                    ),
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
      decoration: BoxDecoration(
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