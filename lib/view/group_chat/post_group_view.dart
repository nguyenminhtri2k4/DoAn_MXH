
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/viewmodel/post_group_viewmodel.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangxahoi/view/group_chat/add_members_view.dart';
import 'package:mangxahoi/view/group_chat/group_management_view.dart';
import 'package:mangxahoi/view/group_chat/search_post_group_view.dart';
import 'package:mangxahoi/view/group_chat/group_members_list_view.dart';
import 'group_events_view.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/view/group_chat/group_status_check_widget.dart';

class PostGroupView extends StatelessWidget {
  final GroupModel group;

  const PostGroupView({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    // Sử dụng GroupStatusCheckWidget để tự động check status 'locked'
    // và hiển thị GroupLockedView nếu cần.
    return GroupStatusCheckWidget(
      groupId: group.id,
      child: ChangeNotifierProvider(
        create: (_) => PostGroupViewModel(group: group),
        child: const _PostGroupViewContent(),
      ),
    );
  }
}

class _PostGroupViewContent extends StatelessWidget {
  const _PostGroupViewContent();

  // Helper method để check xem nhóm có private không
  bool _isPrivateGroup(String status) {
    return status.toLowerCase() == 'private';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PostGroupViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body:
          vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 280.0,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,

                      leading: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              innerBoxIsScrolled ? 0 : 0.9,
                            ),
                            shape: BoxShape.circle,
                            boxShadow:
                                innerBoxIsScrolled
                                    ? []
                                    : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                      ),
                                    ],
                          ),
                          child: const Icon(Icons.arrow_back, size: 20),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),

                      // ✅ FIX: Chỉ hiện actions khi là thành viên (isMember = true)
                      actions:
                          vm.isMember
                              ? [
                                // Search button
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      innerBoxIsScrolled ? 0 : 0.9,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow:
                                        innerBoxIsScrolled
                                            ? []
                                            : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 8,
                                              ),
                                            ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.search, size: 22),
                                    tooltip: 'Tìm kiếm',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => SearchPostGroupView(
                                                groupId: vm.group.id,
                                                groupName: vm.group.name,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // More options menu
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      innerBoxIsScrolled ? 0 : 0.9,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow:
                                        innerBoxIsScrolled
                                            ? []
                                            : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 8,
                                              ),
                                            ],
                                  ),
                                  child: PopupMenuButton(
                                    icon: const Icon(
                                      Icons.more_horiz,
                                      size: 22,
                                    ),
                                    tooltip: 'Tùy chọn',
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    itemBuilder:
                                        (context) => [
                                          // ✅ Thêm thành viên (chỉ Owner hoặc Manager)
                                          if (vm.isOwner || vm.isManager)
                                            PopupMenuItem(
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_add_outlined,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text('Thêm thành viên'),
                                                ],
                                              ),
                                              onTap: () {
                                                Future.delayed(
                                                  Duration.zero,
                                                  () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (_) =>
                                                                AddMembersView(
                                                                  groupId:
                                                                      vm
                                                                          .group
                                                                          .id,
                                                                ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          // Thông tin nhóm (tất cả thành viên)
                                          PopupMenuItem(
                                            child: const Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 12),
                                                Text('Thông tin nhóm'),
                                              ],
                                            ),
                                            onTap: () {
                                              Future.delayed(Duration.zero, () {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/group_management',
                                                  arguments: vm.group.id,
                                                );
                                              });
                                            },
                                          ),
                                          // Cài đặt thông báo (tất cả thành viên)
                                          PopupMenuItem(
                                            child: const Row(
                                              children: [
                                                Icon(
                                                  Icons.notifications_outlined,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 12),
                                                Text('Cài đặt thông báo'),
                                              ],
                                            ),
                                            onTap: () {
                                              // TODO: Notification settings
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Tính năng cài đặt thông báo đang được phát triển',
                                                  ),
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          // Rời nhóm (tất cả thành viên trừ Owner)
                                          if (!vm.isOwner)
                                            PopupMenuItem(
                                              child: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.exit_to_app,
                                                    size: 20,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Rời nhóm',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              onTap: () {
                                                Future.delayed(
                                                  Duration.zero,
                                                  () {
                                                    _showLeaveGroupDialog(
                                                      context,
                                                      vm,
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                        ],
                                  ),
                                ),
                              ]
                              : [], // ✅ Không hiện actions nếu không phải thành viên

                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        titlePadding: const EdgeInsets.only(
                          // left: 16,
                          bottom: 16,
                        ),
                        title: AnimatedOpacity(
                          opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            vm.group.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center, //
                          ),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background image
                            vm.group.coverImage.isNotEmpty
                                ? CachedNetworkImage(
                                  imageUrl: vm.group.coverImage,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primary.withOpacity(
                                                0.7,
                                              ),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.groups,
                                            size: 80,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                )
                                : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.groups,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.5, 1.0],
                                ),
                              ),
                            ),

                            // Group info at bottom
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    vm.group.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        _isPrivateGroup(vm.group.status)
                                            ? Icons.lock
                                            : Icons.public,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isPrivateGroup(vm.group.status)
                                            ? 'Nhóm riêng tư'
                                            : 'Nhóm công khai',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black45,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        '•',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.people,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${vm.group.members.length} thành viên',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black45,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: _buildBodyWithPosts(context, vm),
              ),
    );
  }

  // ✅ Thêm dialog xác nhận rời nhóm
  void _showLeaveGroupDialog(BuildContext context, PostGroupViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (bottomSheetContext) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon cảnh báo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFE53935),
                    size: 32,
                  ),
                ),

                const SizedBox(height: 20),

                // Tiêu đề và nội dung
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Bạn có chắc muốn rời nhóm '),
                      TextSpan(
                        text: vm.group.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '?'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Nút Hủy
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF666666),
                          side: const BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Nút Bỏ chặn (hoặc Rời nhóm)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(bottomSheetContext); // Đóng bottom sheet

                          // Hiển thị loading
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (ctx) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          );

                          // Thực hiện rời nhóm
                          final result = await vm.leaveGroup();

                          // Đóng loading
                          if (!context.mounted) return;
                          Navigator.pop(context);

                          // Hiển thị kết quả
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              backgroundColor:
                                  result.success ? Colors.green : Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );

                          // Nếu thành công, quay lại màn hình trước
                          if (result.success && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Rời nhóm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Thêm padding bottom để tránh bị che bởi navigation bar
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
    );
  }

  Widget _buildBodyWithPosts(BuildContext context, PostGroupViewModel vm) {
    if (vm.currentUserData == null) {
      return const Center(child: Text("Không thể tải dữ liệu người dùng"));
    }

    // Kiểm tra quyền truy cập (Private group)
    if (!vm.hasAccess) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              //const SizedBox(height: 24),
              const Text(
                'Nhóm riêng tư',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Bạn cần là thành viên của nhóm này để xem các bài viết.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ============================================================
    // 🔥 LOGIC KIỂM TRA QUYỀN ĐĂNG BÀI (MỚI)
    // ============================================================
    
    // 1. Lấy cài đặt từ nhóm (mặc định là 'all' nếu không có)
    final String postPermission = vm.group.settings['post_permission']?.toString() ?? 'all';
    
    // 2. Xác định quyền
    bool canPost = true;
    String restrictionReason = "";

    if (postPermission == 'owner') {
      // Chỉ chủ nhóm
      if (!vm.isOwner) {
        canPost = false;
        restrictionReason = "Chỉ chủ nhóm mới được đăng bài.";
      }
    } else if (postPermission == 'managers') {
      // Quản trị viên & Chủ nhóm
      if (!vm.isOwner && !vm.isManager) {
        canPost = false;
        restrictionReason = "Chỉ quản trị viên mới được đăng bài.";
      }
    }
    // Nếu 'all' thì ai cũng đăng được (mặc định canPost = true)
    // ============================================================

    return Container(
      color: Colors.grey[100],
      child: StreamBuilder<List<PostModel>>(
        stream: vm.postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải bài viết: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: [
              // ✅ SỬA: Luôn hiện ô đăng bài nếu là thành viên (Backend sẽ lo việc duyệt)
              if (vm.isMember) _buildCreatePostSection(context, vm),

              // Các nút chức năng nhanh (Thành viên / Sự kiện / ...)
              if (vm.isMember) const SizedBox(height: 8),
              if (vm.isMember) _buildQuickActions(context, vm),
              
              if (posts.isNotEmpty) const SizedBox(height: 8),
              
              // Widget hiển thị khi không có bài viết
              if (posts.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Chưa có bài viết nào trong nhóm",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vm.isMember
                            ? "Hãy là người đầu tiên chia sẻ điều gì đó!"
                            : "Tham gia nhóm để xem và chia sẻ bài viết",
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),

              // Danh sách bài viết
              ...posts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: PostWidget(
                    post: post,
                    currentUserDocId: vm.currentUserData!.id,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreatePostSection(BuildContext context, PostGroupViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/create_post',
            arguments: {
              'currentUser': vm.currentUserData!,
              'groupId': vm.group.id,
            },
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
                  vm.currentUserData!.avatar.isNotEmpty
                      ? NetworkImage(vm.currentUserData!.avatar.first)
                      : null,
              child:
                  vm.currentUserData!.avatar.isEmpty
                      ? const Icon(Icons.person, size: 20)
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Bạn đang nghĩ gì?',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.image_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, PostGroupViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.people_outline,
              label: 'Thành viên',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupMembersView(groupId: vm.group.id),
                  ),
                );
              },
            ),
          ),
          Container(width: 1, height: 24, color: Colors.grey[300]),
          Expanded(
          child: _buildQuickActionButton(
            icon: Icons.event_outlined,
            label: 'Sự kiện',
            onTap: () {
              // Lấy ViewModel từ context hiện tại
              final vm = Provider.of<PostGroupViewModel>(context, listen: false);
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Truyền vm vào GroupEventsView
                  builder: (context) => GroupEventsView(viewModel: vm),
                ),
              );
            },
          ),
        ),
          Container(width: 1, height: 24, color: Colors.grey[300]),
          // Expanded(
          //   child: _buildQuickActionButton(
          //     icon: Icons.more_horiz,
          //     label: 'Thêm',
          //     onTap: () {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //           content: Text('Tính năng đang được phát triển'),
          //           duration: Duration(seconds: 2),
          //         ),
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
}