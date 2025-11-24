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
import 'package:mangxahoi/model/model_group.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/viewmodel/friends_view_model.dart';
import 'package:mangxahoi/request/friend_request_manager.dart';

class ProfileView extends StatelessWidget {
  final String? userId;
  const ProfileView({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..loadProfile(userId: userId),
      child: _ProfileContent(key: ValueKey(userId ?? 'currentUser')),
    );
  }
}

class _ProfileContent extends StatefulWidget {
  const _ProfileContent({super.key});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body:
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.user == null
              ? const Center(child: Text('Không tìm thấy thông tin người dùng'))
              : NestedScrollView(
                physics: const ClampingScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      leading: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back, size: 20),
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/home', // Thay bằng route trang chủ của bạn: '/home', '/main', etc.
                              (route) => false,
                            );
                          }
                        },
                      ),
                      expandedHeight: vm.isCurrentUserProfile ? 380.0 : 480.0,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        key: ValueKey('header_${vm.user?.id}'),
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
    if (vm.isBlocked || vm.isBlockedByOther) {
      return _buildBlockedHeader(context, vm);
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 180,
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
                          ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          )
                          : null,
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                  ),
                ),
              ),
            ],
          ),

          Transform.translate(
            offset: const Offset(0, -50),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundImage:
                        vm.user!.avatar.isNotEmpty
                            ? NetworkImage(vm.user!.avatar.first)
                            : null,
                    child:
                        vm.user!.avatar.isEmpty
                            ? const Icon(Icons.person, size: 56)
                            : null,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  vm.user!.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                if (vm.user!.bio.isNotEmpty && vm.user!.bio != "No")
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 6,
                    ),
                    child: Text(
                      vm.user!.bio,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                  ),

                const SizedBox(height: 12),

                if (!vm.isCurrentUserProfile) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildActionButtons(context, vm),
                  ),
                  const SizedBox(height: 50),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedHeader(BuildContext context, ProfileViewModel vm) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.grey, Colors.blueGrey]),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -50),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(
                      Icons.person,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  vm.user!.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      vm.isBlockedByOther
                          ? _buildBlockedByOtherButton()
                          : _buildUnblockButton(context, vm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProfileViewModel vm) {
    if (vm.isBlocked) {
      return _buildUnblockButton(context, vm);
    }

    return Row(
      children: [
        Expanded(child: _buildFriendButton(context, vm, vm.friendshipStatus)),
        const SizedBox(width: 12),
        Expanded(child: _buildMessageButton(context, vm)),
      ],
    );
  }

  Widget _buildUnblockButton(BuildContext context, ProfileViewModel vm) {
    return _buildStyledButton(
      icon: Icons.block,
      label: 'Đã chặn',
      backgroundColor: Colors.red.shade50,
      foregroundColor: Colors.red.shade700,
      onTap: () => _showUnblockMenu(context, vm),
    );
  }

  Widget _buildBlockedByOtherButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            'Đã bị chặn',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendButton(
    BuildContext context,
    ProfileViewModel vm,
    String friendshipStatus,
  ) {
    switch (friendshipStatus) {
      case 'friends':
        return _buildStyledButton(
          icon: Icons.check_circle,
          label: 'Bạn bè',
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black87,
          onTap: () => _showFriendsMenu(context, vm),
        );
      case 'pending_sent':
        return _buildStyledButton(
          icon: Icons.schedule,
          label: 'Đã gửi',
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black87,
          onTap: () => _showPendingSentMenu(context, vm),
        );
      case 'pending_received':
        return _buildStyledButton(
          icon: Icons.person_add,
          label: 'Phản hồi',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onTap: () => Navigator.pushNamed(context, '/friends'),
        );
      default:
        return _buildStyledButton(
          icon: Icons.person_add,
          label: 'Kết bạn',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onTap: () => _showAddFriendMenu(context, vm),
        );
    }
  }

  Widget _buildMessageButton(BuildContext context, ProfileViewModel vm) {
    return _buildStyledButton(
      icon: Icons.message_rounded,
      label: 'Nhắn tin',
      backgroundColor: Colors.grey.shade200,
      foregroundColor: Colors.black87,
      onTap: () async {
        final currentUser = await UserRequest().getUserByUid(
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

  Widget _buildStyledButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foregroundColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildBottomSheetItem(
                  icon: Icons.check_circle_outline,
                  label: 'Hủy chặn người dùng',
                  iconColor: Colors.green,
                  onTap: () async {
                    Navigator.pop(context);
                    await vm.unblockUser();
                    await vm.loadProfile(userId: vm.user?.id);
                  },
                ),
                const SizedBox(height: 20),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildBottomSheetItem(
                  icon: Icons.person_remove_outlined,
                  label: 'Hủy kết bạn',
                  iconColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    vm.unfriend();
                  },
                ),
                const Divider(height: 1),
                _buildBottomSheetItem(
                  icon: Icons.block_outlined,
                  label: 'Chặn người dùng',
                  iconColor: Colors.grey.shade700,
                  onTap: () async {
                    Navigator.pop(context);
                    await vm.blockUser();
                    await vm.loadProfile(userId: vm.user?.id);
                  },
                ),
                const SizedBox(height: 20),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildBottomSheetItem(
                  icon: Icons.cancel_outlined,
                  label: 'Hủy lời mời kết bạn',
                  iconColor: Colors.red,
                  onTap: () async {
                    Navigator.pop(context); // Đóng bottom sheet

                    // Hiển thị loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      // Tìm và hủy request
                      final sentRequests =
                          await FriendRequestManager()
                              .getSentRequests(vm.currentUserData!.id)
                              .first;

                      final request = sentRequests.firstWhere(
                        (req) => req.toUserId == vm.user!.id,
                        orElse:
                            () =>
                                throw Exception(
                                  'Không tìm thấy lời mời kết bạn',
                                ),
                      );

                      await FriendRequestManager().cancelSentRequest(
                        request.id,
                      );

                      // Đóng loading và hiển thị thông báo
                      if (context.mounted) {
                        Navigator.pop(context); // Đóng loading

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã hủy lời mời kết bạn'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        // ✅ Reload để button đổi từ "Đã gửi" → "Kết bạn"
                        await vm.loadProfile(userId: vm.user!.id);
                      }
                    } catch (e) {
                      // Đóng loading
                      if (context.mounted) {
                        Navigator.pop(context);

                        // Hiển thị lỗi
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildBottomSheetItem(
                  icon: Icons.person_add_outlined,
                  label: 'Gửi lời mời kết bạn',
                  iconColor: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    vm.sendFriendRequest();
                  },
                ),
                const Divider(height: 1),
                _buildBottomSheetItem(
                  icon: Icons.block_outlined,
                  label: 'Chặn người dùng',
                  iconColor: Colors.grey.shade700,
                  onTap: () async {
                    Navigator.pop(context);
                    await vm.blockUser();
                    await vm.loadProfile(userId: vm.user?.id);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildBottomSheetItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  // ==================== BODY WITH POSTS ====================
  Widget _buildBodyWithPosts(BuildContext context, ProfileViewModel vm) {
    if (vm.currentUserData == null || vm.isBlocked || vm.isBlockedByOther) {
      return Container(color: AppColors.background);
    }

    return Container(
      color: AppColors.background,
      child: StreamBuilder<List<PostModel>>(
        key: ValueKey('posts_${vm.user?.id}_v${vm.streamsVersion}'),
        stream: vm.userPostsStream,
        builder: (context, snapshot) {
          final posts = snapshot.data ?? [];
          return _buildPostsList(context, vm, posts);
        },
      ),
    );
  }

  // ==================== POSTS LIST ====================
  Widget _buildPostsList(
    BuildContext context,
    ProfileViewModel vm,
    List<PostModel> posts,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        _buildInfoSection(context, vm),
        const SizedBox(height: 12),
        _buildStatsSection(context, vm),
        const SizedBox(height: 12),
        _buildFriendsSection(context, vm),
        const SizedBox(height: 12),
        _buildGroupsSection(context, vm),
        const SizedBox(height: 12),
        if (vm.isCurrentUserProfile) _buildCreatePostSection(context, vm),
        if (posts.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
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
        if (posts.isEmpty && !vm.isCurrentUserProfile)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bài viết nào',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ==================== INFO SECTION ====================
  Widget _buildInfoSection(BuildContext context, ProfileViewModel vm) {
    final user = vm.user!;
    final isCurrentUser = vm.isCurrentUserProfile;

    final infoItems = [
      if (user.email.isNotEmpty) _InfoItem(Icons.email_outlined, user.email),
      if (user.liveAt.isNotEmpty)
        _InfoItem(Icons.home_work_outlined, 'Sống tại ${user.liveAt}'),
      if (user.comeFrom.isNotEmpty)
        _InfoItem(Icons.location_on_outlined, 'Đến từ ${user.comeFrom}'),
      if (user.relationship.isNotEmpty)
        _InfoItem(Icons.favorite_outline, user.relationship),
      if (user.dateOfBirth != null)
        _InfoItem(
          Icons.cake_outlined,
          'Sinh nhật ${DateFormat('dd/MM/yyyy').format(user.dateOfBirth!)}',
        ),
      if (user.phone.isNotEmpty) _InfoItem(Icons.phone_outlined, user.phone),
    ];

    if (infoItems.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      isCurrentUser
                          ? 'Chưa có thông tin. Nhấn "Xem chi tiết" để cập nhật.'
                          : 'Người dùng chưa cập nhật thông tin',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
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
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isCurrentUser
                          ? 'Cập nhật thông tin'
                          : 'Xem thông tin chi tiết',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...infoItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(item.icon, color: Colors.grey[600], size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.text,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
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
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    isCurrentUser ? 'Xem chi tiết' : 'Xem thông tin chi tiết',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATS SECTION ====================
  Widget _buildStatsSection(BuildContext context, ProfileViewModel vm) {
    final user = vm.user!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            context,
            user.friends.length.toString(),
            'Bạn bè',
            AppColors.primary,
            () {
              Navigator.pushNamed(
                context,
                '/friend_list',
                arguments: {'userId': user.id, 'userName': user.name},
              );
            },
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem(
            context,
            user.followerCount.toString(),
            'Follower',
            Colors.green,
            null,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem(
            context,
            user.followingCount.toString(),
            'Following',
            Colors.orange,
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    final content = Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: content,
        ),
      );
    }
    return content;
  }

  // ==================== FRIENDS SECTION ====================
  Widget _buildFriendsSection(BuildContext context, ProfileViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bạn bè',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/friend_list',
                    arguments: {
                      'userId': vm.user!.id,
                      'userName': vm.user!.name,
                    },
                  );
                },
                child: Text(
                  'Xem tất cả (${vm.user!.friends.length})',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFriendsGrid(context, vm),
        ],
      ),
    );
  }

  Widget _buildFriendsGrid(BuildContext context, ProfileViewModel vm) {
    return StreamBuilder<List<UserModel>>(
      key: ValueKey('friends_${vm.user?.id}_v${vm.streamsVersion}'),
      stream: vm.friendsStream,
      builder: (context, snapshot) {
        final friends = snapshot.data ?? [];
        if (friends.isEmpty) {
          return _buildEmptyState('Chưa có bạn bè');
        }
        return _buildFriendsGridView(friends);
      },
    );
  }

  Widget _buildFriendsGridView(List<UserModel> friends) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: friends.length > 6 ? 6 : friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/profile', arguments: friend.id);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl:
                          friend.avatar.isNotEmpty ? friend.avatar.first : '',
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  friend.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupsSection(BuildContext context, ProfileViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nhóm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              StreamBuilder<List<GroupModel>>(
                stream: vm.groupsStream,
                builder: (context, snapshot) {
                  final totalGroups = (snapshot.data ?? []).length;
                  if (totalGroups <= 2) return const SizedBox.shrink();

                  return TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/user_groups',
                        arguments: {
                          'userId': vm.user!.id,
                          'userName': vm.user!.name,
                        },
                      );
                    },
                    child: Text(
                      'Xem tất cả ($totalGroups)',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGroupsList(context, vm),
        ],
      ),
    );
  }

  Widget _buildGroupsList(BuildContext context, ProfileViewModel vm) {
    return StreamBuilder<List<GroupModel>>(
      key: ValueKey('groups_${vm.user?.id}_v${vm.streamsVersion}'),
      stream: vm.groupsStream,
      builder: (context, snapshot) {
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return _buildEmptyState('Chưa tham gia nhóm nào');
        }
        return _buildGroupsListView(groups);
      },
    );
  }

  Widget _buildGroupsListView(List<GroupModel> groups) {
    final displayGroups = groups.take(2).toList();

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayGroups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = displayGroups[index];
        return _buildGroupCard(context, group);
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, GroupModel group) {
    final hasCoverImage = group.coverImage.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: InkWell(
        onTap: () {
          if (group.type == 'post') {
            Navigator.pushNamed(context, '/post_group', arguments: group);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient:
                      !hasCoverImage
                          ? LinearGradient(
                            colors: [Colors.purple[400]!, Colors.purple[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      hasCoverImage
                          ? CachedNetworkImage(
                            imageUrl: group.coverImage,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) =>
                                    Container(color: Colors.grey[200]),
                            errorWidget:
                                (context, url, error) => const Icon(
                                  Icons.article,
                                  color: Colors.white,
                                  size: 28,
                                ),
                          )
                          : const Icon(
                            Icons.article,
                            color: Colors.white,
                            size: 28,
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.members.length} thành viên',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (group.status == 'private') ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Riêng tư',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== CREATE POST SECTION ====================
  Widget _buildCreatePostSection(BuildContext context, ProfileViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage:
                    vm.user!.avatar.isNotEmpty
                        ? NetworkImage(vm.user!.avatar.first)
                        : null,
                child:
                    vm.user!.avatar.isEmpty
                        ? const Icon(Icons.person, size: 22)
                        : null,
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Bạn đang nghĩ gì?',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPostActionButton(
                Icons.photo_library_outlined,
                'Ảnh',
                Colors.green,
                () {},
              ),
              _buildPostActionButton(
                Icons.location_on_outlined,
                'Check in',
                Colors.red,
                () {},
              ),
              _buildPostActionButton(
                Icons.emoji_emotions_outlined,
                'Cảm xúc',
                Colors.orange,
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER ====================
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String text;

  _InfoItem(this.icon, this.text);
}
