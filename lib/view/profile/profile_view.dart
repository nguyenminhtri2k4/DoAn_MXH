import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/profile_view_model.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:intl/intl.dart';
import 'package:mangxahoi/request/chat_request.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileView extends StatelessWidget {
  final String? userId;
  const ProfileView({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..loadProfile(userId: userId),
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
      body:
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.user == null
              ? const Center(child: Text('Không tìm thấy thông tin người dùng'))
              : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 380.0,
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
    // Nếu đã chặn hoặc bị chặn, hiển thị phần hạn chế
    if (vm.isBlocked || vm.isBlockedByOther) {
      return Container(
        color: AppColors.backgroundLight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ảnh nền đơn giản (gradient)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey, Colors.blueGrey],
                  ),
                ),
              ),
            ),
            // Avatar mặc định
            Positioned(
              top: 130,
              child: CircleAvatar(
                radius: 64,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Hiển thị tên
            Positioned(
              top: 265,
              left: 16,
              right: 16,
              child: Text(
                vm.user!.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Nút tương ứng
            Positioned(
              bottom: 8,
              left: 16,
              right: 16,
              child:
                  vm.isBlockedByOther
                      ? _buildBlockedByOtherButton(context)
                      : _buildBlockedButton(context, vm),
            ),
          ],
        ),
      );
    }

    // Hiển thị đầy đủ khi chưa chặn
    return Container(
      color: AppColors.backgroundLight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ảnh nền
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                image:
                    vm.user!.backgroundImageUrl.isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(vm.user!.backgroundImageUrl),
                          fit: BoxFit.cover,
                        )
                        : null,
                gradient:
                    vm.user!.backgroundImageUrl.isEmpty
                        ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary, AppColors.primaryLight],
                        )
                        : null,
                color: AppColors.primaryLight,
              ),
              child: Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
              ),
            ),
          ),
          // Avatar
          Positioned(
            top: 130,
            child: CircleAvatar(
              radius: 64,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 60,
                backgroundImage:
                    vm.user!.avatar.isNotEmpty
                        ? NetworkImage(vm.user!.avatar.first)
                        : null,
                child:
                    vm.user!.avatar.isEmpty
                        ? const Icon(Icons.person, size: 60)
                        : null,
              ),
            ),
          ),
          // Tên và tiểu sử
          Positioned(
            top: 265,
            left: 16,
            right: 16,
            child: Column(
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      vm.user!.bio,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Nút hành động
          Positioned(
            bottom: 8,
            left: 16,
            right: 16,
            child: _buildActionButtons(context, vm),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProfileViewModel vm) {
    if (vm.isCurrentUserProfile) return const SizedBox.shrink();

    final friendshipStatus = vm.friendshipStatus;
    final isBlocked = vm.isBlocked;

    return Row(
      children: [
        Expanded(
          child:
              isBlocked
                  ? _buildBlockedButton(context, vm)
                  : _buildFriendButton(context, vm, friendshipStatus),
        ),
        if (!isBlocked) ...[
          const SizedBox(width: 8),
          Expanded(child: _buildMessageButton(context, vm)),
        ],
      ],
    );
  }

  Widget _buildBlockedByOtherButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'Đã bị chặn',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedButton(BuildContext context, ProfileViewModel vm) {
    return _buildMenuButton(
      icon: Icons.block,
      label: 'Đã chặn',
      backgroundColor: Colors.red.shade50,
      textColor: Colors.red.shade700,
      onTap: () => _showUnblockMenu(context, vm),
    );
  }

  Widget _buildFriendButton(
    BuildContext context,
    ProfileViewModel vm,
    String friendshipStatus,
  ) {
    switch (friendshipStatus) {
      case 'friends':
        return _buildMenuButton(
          icon: Icons.how_to_reg,
          label: 'Bạn bè',
          backgroundColor: Colors.grey.shade300,
          textColor: Colors.black87,
          onTap: () => _showFriendsMenu(context, vm),
        );

      case 'pending_sent':
        return _buildMenuButton(
          icon: Icons.update,
          label: 'Đã gửi lời mời',
          backgroundColor: Colors.grey.shade300,
          textColor: Colors.black87,
          onTap: () => _showPendingSentMenu(context, vm),
        );

      case 'pending_received':
        return _buildMenuButton(
          icon: Icons.group_add,
          label: 'Phản hồi',
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
          onTap: () => Navigator.pushNamed(context, '/friends'),
        );

      case 'none':
      default:
        return _buildMenuButton(
          icon: Icons.person_add,
          label: 'Thêm bạn bè',
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
          onTap: () => _showAddFriendMenu(context, vm),
        );
    }
  }

  Widget _buildMessageButton(BuildContext context, ProfileViewModel vm) {
    return _buildMenuButton(
      icon: Icons.message,
      label: 'Nhắn tin',
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
      onTap: () async {
        final currentUser =
            vm.isCurrentUserProfile
                ? vm.user
                : await UserRequest().getUserByUid(
                  FirebaseAuth.instance.currentUser!.uid,
                );

        if (currentUser != null && vm.user != null) {
          final chatId = await ChatRequest().getOrCreatePrivateChat(
            currentUser.id,
            vm.user!.id,
          );
          if (context.mounted) {
            Navigator.pushNamed(
              context,
              '/chat',
              arguments: {'chatId': chatId, 'chatName': vm.user!.name},
            );
          }
        }
      },
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUnblockMenu(BuildContext context, ProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.check_circle,
                  label: 'Hủy chặn người dùng',
                  iconColor: Colors.green,
                  backgroundColor: Colors.green.shade50.withOpacity(0.5),
                  onTap: () async {
                    Navigator.pop(context);
                    await vm.unblockUser();
                    // Reload profile sau khi hủy chặn
                    await vm.loadProfile(userId: vm.user?.id);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _showFriendsMenu(BuildContext context, ProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.person_remove,
                  label: 'Hủy kết bạn',
                  iconColor: Colors.red,
                  backgroundColor: Colors.red.shade50.withOpacity(0.5),
                  onTap: () {
                    Navigator.pop(context);
                    vm.unfriend();
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: Icons.block,
                  label: 'Chặn',
                  iconColor: Colors.black87,
                  backgroundColor: Colors.grey.shade200.withOpacity(0.5),
                  onTap: () async {
                    Navigator.pop(context);
                    await vm.blockUser();
                    // Reload profile sau khi chặn
                    await vm.loadProfile(userId: vm.user?.id);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _showPendingSentMenu(BuildContext context, ProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.person_remove,
                  label: 'Hủy yêu cầu kết bạn',
                  iconColor: Colors.red,
                  backgroundColor: Colors.red.shade50.withOpacity(0.5),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement cancelFriendRequest in ViewModel
                    // vm.cancelFriendRequest();
                    print('Cancel friend request tapped');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _showAddFriendMenu(BuildContext context, ProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.person_add,
                  label: 'Gửi lời mời kết bạn',
                  iconColor: Colors.blue,
                  backgroundColor: Colors.blue.shade50.withOpacity(0.5),
                  onTap: () {
                    Navigator.pop(context);
                    vm.sendFriendRequest();
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: Icons.block,
                  label: 'Chặn',
                  iconColor: Colors.black87,
                  backgroundColor: Colors.grey.shade200.withOpacity(0.5),
                  onTap: () async {
                    Navigator.pop(context);
                    await vm.blockUser();
                    // Reload profile sau khi chặn
                    await vm.loadProfile(userId: vm.user?.id);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }

  Widget _buildInfoSection(BuildContext context, ProfileViewModel vm) {
    final user = vm.user!;
    final isCurrentUser = vm.isCurrentUserProfile;

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
            _buildInfoRow(
              Icons.home_work_outlined,
              'Sống tại ${user.liveAt}',
              user.liveAt.isNotEmpty,
            ),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Đến từ ${user.comeFrom}',
              user.comeFrom.isNotEmpty,
            ),
            _buildInfoRow(
              Icons.favorite_outline,
              user.relationship,
              user.relationship.isNotEmpty,
            ),
            _buildInfoRow(
              Icons.cake_outlined,
              'Sinh nhật ${user.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(user.dateOfBirth!) : 'Chưa cập nhật'}',
              user.dateOfBirth != null,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/about',
                  arguments: {'viewModel': vm, 'isCurrentUser': isCurrentUser},
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.more_horiz,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isCurrentUser
                          ? 'Xem thông tin giới thiệu của bạn'
                          : 'Xem thông tin giới thiệu',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
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
    if (vm.currentUserData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isCurrentUser = vm.isCurrentUserProfile;

    // Nếu đã chặn hoặc bị chặn, hiển thị màn hình trống
    if (vm.isBlocked || vm.isBlockedByOther) {
      return Container(color: AppColors.background);
    }

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

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              _buildInfoSection(context, vm),
              if (isCurrentUser) _buildCreatePostSection(context, vm),
              if (posts.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Bài viết',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ...posts
                  .map(
                    (post) => PostWidget(
                      post: post,
                      currentUserDocId: vm.currentUserData!.id,
                    ),
                  )
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreatePostSection(BuildContext context, ProfileViewModel vm) {
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
                  backgroundImage:
                      vm.user!.avatar.isNotEmpty
                          ? NetworkImage(vm.user!.avatar.first)
                          : null,
                  child:
                      vm.user!.avatar.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/create_post',
                        arguments: vm.user,
                      );
                    },
                    child: const Text(
                      'Bạn đang nghĩ gì?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  Icons.photo_library,
                  'Ảnh',
                  Colors.green,
                  () {},
                ),
                _buildActionButton(
                  Icons.person_pin_circle,
                  'Check in',
                  Colors.red,
                  () {},
                ),
                _buildActionButton(
                  Icons.emoji_emotions,
                  'Cảm xúc',
                  Colors.orange,
                  () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
