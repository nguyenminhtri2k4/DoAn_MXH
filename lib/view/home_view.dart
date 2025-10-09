import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/home_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';

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

class _HomeViewContent extends StatelessWidget {
  const _HomeViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
      title: AppColors.logosybau.isNotEmpty
          ? Image.asset(
              AppColors.logosybau,
              height: 200,
              fit: BoxFit.contain,
            )
          : const Text('Mạng Xã Hội'),
      centerTitle: true,
      backgroundColor: AppColors.background,
      foregroundColor: Colors.black,
       // ===> THÊM ACTIONS (Kính lúp) <===
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28, color: AppColors.textPrimary), // Biểu tượng kính lúp màu đen
            onPressed: () {
              // Chuyển hướng đến trang tìm kiếm
              Navigator.pushNamed(context, '/search'); 
            },
          ),
          const SizedBox(width: 8),
        ],
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (vm.currentUserData != null) {
            Navigator.pushNamed(context, '/create_post', arguments: vm.currentUserData);
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
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
            ListTile(leading: const Icon(Icons.home), title: const Text('Trang chủ'), onTap: () => Navigator.pop(context)),
            // ===> THÊM NÚT BẠN BÈ <===
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Bạn bè'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/friends'); // Chuyển đến trang FriendsView
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Thông tin cá nhân'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Đăng xuất'), onTap: () => vm.signOut(context)),
          ],
        ),
      ),
      body: (vm.isLoading || vm.currentUserData == null)
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
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return PostWidget(
                      post: posts[index],
                      currentUserDocId: vm.currentUserData!.id,
                    );
                  },
                );
              },
            ),
    );
  }
}