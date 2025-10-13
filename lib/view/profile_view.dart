import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:intl/intl.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..loadProfile(),
      child: const _ProfileContent(),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.user == null
              ? const Center(child: Text('Không tìm thấy thông tin người dùng'))
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: 300.0,
                        floating: false,
                        pinned: true,
                        backgroundColor: AppColors.backgroundLight,
                        foregroundColor: AppColors.textPrimary,
                        flexibleSpace: FlexibleSpaceBar(
                          background: _buildHeader(context, vm),
                        ),
                      ),
                    ];
                  },
                  body: _buildBodyWithPosts(context, vm),
                ),
    );
  }

  Widget _buildHeader(BuildContext context, ProfileViewModel vm) {
    return Stack(
      children: [
        // Cover photo
        Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
        ),
        // Avatar positioned below cover, centered horizontally
        Positioned(
          top: 140,
          left: 0,
          right: 0,
          child: Center(
            child: CircleAvatar(
              radius: 64,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: vm.user!.avatar.isNotEmpty
                    ? NetworkImage(vm.user!.avatar.first)
                    : null,
                child: vm.user!.avatar.isEmpty
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
          ),
        ),
        // Name and bio positioned below avatar, centered
        Positioned(
          top: 270,
          left: 0,
          right: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                vm.user!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              if (vm.user!.bio.isNotEmpty && vm.user!.bio != "No")
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    vm.user!.bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

// ==================== CẬP NHẬT HÀM NÀY ====================
  Widget _buildInfoSection(BuildContext context, ProfileViewModel vm) {
    final user = vm.user!;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.home_work_outlined, 'Sống tại ${user.liveAt}', user.liveAt.isNotEmpty),
            _buildInfoRow(Icons.location_on_outlined, 'Đến từ ${user.comeFrom}', user.comeFrom.isNotEmpty),
            _buildInfoRow(Icons.favorite_outline, user.relationship, user.relationship.isNotEmpty),
            _buildInfoRow(Icons.cake_outlined, 'Sinh nhật ${DateFormat('dd/MM/yyyy').format(user.dateOfBirth!)}', user.dateOfBirth != null),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                // Điều hướng đến trang About, truyền ViewModel và cờ isCurrentUser
                Navigator.pushNamed(
                  context, 
                  '/about', 
                  arguments: {
                    'viewModel': vm,
                    'isCurrentUser': true, // Vì đây là trang của chính người dùng
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 24),
                    const SizedBox(width: 16),
                    const Text(
                      'Xem thông tin giới thiệu của bạn',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isVisible) {
    if (!isVisible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 24),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
  
  Widget _buildBodyWithPosts(BuildContext context, ProfileViewModel vm) {
    //... (Hàm này giữ nguyên không thay đổi)
        return Container(
      color: AppColors.background,
      child: StreamBuilder<List<PostModel>>(
        stream: vm.userPostsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải bài viết: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];
          
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            // +3 cho Info, Create Post, và Title
            itemCount: posts.length + 3,
            itemBuilder: (context, index) {
              if (index == 0) return _buildInfoSection(context, vm);
              if (index == 1) return _buildCreatePostSection(context, vm);
              // Item 2: Tiêu đề "Bài viết"
              if (index == 2) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Bài viết',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                );
              }
              // Các item còn lại: Bài viết
              final post = posts[index - 3];
              return PostWidget(
                post: post,
                currentUserDocId: vm.user!.id,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCreatePostSection(BuildContext context, ProfileViewModel vm) {
    //... (Hàm này giữ nguyên không thay đổi)
        return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
             Row(
              children: [
                CircleAvatar(
                  backgroundImage: vm.user!.avatar.isNotEmpty
                      ? NetworkImage(vm.user!.avatar.first)
                      : null,
                  child: vm.user!.avatar.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/create_post', arguments: vm.user);
                    },
                    child: const Text(
                      'Bạn đang nghĩ gì?',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.photo_library, 'Ảnh', Colors.green, () {}),
                _buildActionButton(Icons.person_pin_circle, 'Check in', Colors.red, () {}),
                _buildActionButton(Icons.emoji_emotions, 'Cảm xúc', Colors.orange, () {}),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    //... (Hàm này giữ nguyên không thay đổi)
        return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}