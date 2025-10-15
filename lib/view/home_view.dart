
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/home_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:mangxahoi/view/friends_view.dart';
import 'package:mangxahoi/view/profile_view.dart';
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
    // Chỉ áp dụng hiệu ứng cho trang chủ (index 0)
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
      _isVisible = true; // Luôn hiển thị lại các thanh khi chuyển tab
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
                padding: EdgeInsets.only(top:MediaQuery.of(context).padding.top, bottom: 40),
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final isHomePage = _selectedIndex == 0;
    // showUI sẽ là true nếu không phải trang chủ, hoặc là trang chủ và _isVisible là true
    final showUI = !isHomePage || _isVisible;

    final List<Widget> pages = [
      _buildHomePageBody(vm),
      const FriendsView(),
      const VideoView(),
      const NotificationView(),
      const ProfileView(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: isHomePage,
      appBar: isHomePage
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, showUI ? 0 : -(kToolbarHeight + MediaQuery.of(context).padding.top), 0),
                child: AppBar(
                  title: AppColors.logosybau.isNotEmpty
                      ? Image.asset(
                          AppColors.logosybau,
                          height: 200,
                          fit: BoxFit.contain,
                        )
                      : const Text('Mạng Xã Hội'),
                  centerTitle: true,
                  backgroundColor: AppColors.background.withOpacity(0.95),
                  foregroundColor: Colors.black,
                  elevation: 1,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search, size: 28, color: AppColors.textPrimary),
                      onPressed: () {
                        Navigator.pushNamed(context, '/search');
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            )
          : null,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                children: [
                   CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage: vm.currentUserData?.avatar.isNotEmpty == true
                          ? NetworkImage(vm.currentUserData!.avatar.first) : null,
                      child: vm.currentUserData?.avatar.isEmpty ?? true
                          ? const Icon(Icons.person, size: 40, color: Colors.blue) : null,
                    ),
                  const SizedBox(height: 10),
                  Text(vm.currentUserData?.name ?? 'Đang tải...', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(vm.currentUserData?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text('Trang chủ'), onTap: () {
              Navigator.pop(context);
              _onTabTapped(0);
            }),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Bạn bè'),
              onTap: () {
                Navigator.pop(context);
                _onTabTapped(1);
              },
            ),
             ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Nhóm'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/groups');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Trang cá nhân'),
              onTap: () {
                Navigator.pop(context);
                _onTabTapped(4);
              },
            ),
              ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Danh sách chặn'),
              onTap: () {
                Navigator.pop(context); 
                Navigator.pushNamed(context, '/blocked_list');
              },
            ),
             ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Cài đặt thông báo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notification_settings');
              },
            ),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Đăng xuất'), onTap: () => vm.signOut(context)),
          ],
        ),
      ),
      // ==================== CẬP NHẬT TẠI ĐÂY ====================
      floatingActionButton: isHomePage // Chỉ hiển thị nút ở trang chủ
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
          : null, // Không hiển thị ở các trang khác
      // ==========================================================
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: showUI ? kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom : 0.0,
        child: Wrap(
          children: [
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
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
          ],
        ),
      ),
    );
  }
}