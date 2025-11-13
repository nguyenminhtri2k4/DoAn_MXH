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
    return Container(
      color: AppColors.backgroundLight,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
          Positioned(
            top: 265,
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
                  Text(
                    vm.user!.bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 320,
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

    Widget friendButton;
    final friendshipStatus = vm.friendshipStatus;

    switch (friendshipStatus) {
      case 'friends':
        friendButton = _FriendMenuButton(
          onUnfriend: () => vm.unfriend(),
          onBlock: () => vm.blockUser(),
        );
        break;
      case 'pending_sent':
        friendButton = ElevatedButton.icon(
          icon: const Icon(Icons.update),
          label: const Text('Đã gửi lời mời'),
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black87,
          ),
        );
        break;
      case 'pending_received':
        friendButton = ElevatedButton.icon(
          icon: const Icon(Icons.group_add, color: Colors.white),
          label: const Text('Phản hồi'),
          onPressed: () => Navigator.pushNamed(context, '/friends'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        );
        break;
      case 'none':
      default:
        friendButton = _AddFriendMenuButton(
          onAddFriend: () => vm.sendFriendRequest(),
          onBlock: () => vm.blockUser(),
        );
    }

    return Row(
      children: [
        Expanded(child: friendButton),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.message, color: Colors.white),
            label: const Text('Nhắn tin'),
            onPressed: () async {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
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

              ...posts.map(
                (post) => PostWidget(
                  post: post,
                  currentUserDocId: vm.currentUserData!.id,
                ),
              ),
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

// Widget cho nút Bạn bè với dropdown menu
class _FriendMenuButton extends StatelessWidget {
  final VoidCallback onUnfriend;
  final VoidCallback onBlock;

  const _FriendMenuButton({required this.onUnfriend, required this.onBlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            _showMenuSheet(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.how_to_reg, color: Colors.black87, size: 20),
                SizedBox(width: 8),
                Text(
                  'Bạn bè',
                  style: TextStyle(
                    color: Colors.black87,
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

  void _showMenuSheet(BuildContext context) {
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
                ListTile(
                  leading: const Icon(
                    Icons.person_remove,
                    color: Colors.black87,
                  ),
                  title: const Text('Hủy kết bạn'),
                  onTap: () {
                    Navigator.pop(context);
                    onUnfriend();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text(
                    'Chặn',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onBlock();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}

// Widget cho nút Thêm bạn bè với dropdown menu
class _AddFriendMenuButton extends StatelessWidget {
  final VoidCallback onAddFriend;
  final VoidCallback onBlock;

  const _AddFriendMenuButton({
    required this.onAddFriend,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            _showMenuSheet(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.person_add, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Thêm bạn bè',
                  style: TextStyle(
                    color: Colors.white,
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

  void _showMenuSheet(BuildContext context) {
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
                ListTile(
                  leading: const Icon(
                    Icons.person_add,
                    color: AppColors.primary,
                  ),
                  title: const Text('Gửi lời mời kết bạn'),
                  onTap: () {
                    Navigator.pop(context);
                    onAddFriend();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text(
                    'Chặn',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onBlock();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}
