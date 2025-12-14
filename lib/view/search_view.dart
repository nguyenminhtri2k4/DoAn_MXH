import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/viewmodel/search_view_model.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/notification/notification_service.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:mangxahoi/view/search/visual_search_view.dart'; // Import màn hình quét

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: const _SearchViewContent(),
    );
  }
}

class _SearchViewContent extends StatelessWidget {
  const _SearchViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();

    return Scaffold(
      appBar: _buildAppBar(context, vm),
      body: _buildBody(context, vm),
    );
  }

  AppBar _buildAppBar(BuildContext context, SearchViewModel vm) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.background,
      elevation: 1,
      titleSpacing: 0,
      toolbarHeight: 70,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: vm.searchController,
                autofocus: false,
                onChanged: (_) => vm.notifyListeners(),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  hintStyle: const TextStyle(fontSize: 14), // Chỉnh lại font size hint cho đẹp
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  
                  // --- CẬP NHẬT PHẦN NÀY ---
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min, // Quan trọng: Để icon không chiếm hết chỗ
                    children: [
                      // 1. Nút Xóa (Chỉ hiện khi có text)
                      if (vm.searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                          onPressed: () {
                            vm.searchController.clear();
                            vm.clearSearch();
                          },
                        ),
                        
                      // 2. Nút Visual Search (Giống TikTok/Shopee)
                      IconButton(
                        // Icon máy ảnh hoặc quét mã
                        icon: const Icon(Icons.center_focus_weak, color: AppColors.textPrimary), 
                        tooltip: 'Tìm bằng hình ảnh',
                        onPressed: () async {
                          // Tắt bàn phím trước khi chuyển màn hình
                          FocusScope.of(context).unfocus();

                          // Chuyển sang màn hình Visual Search và đợi kết quả
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VisualSearchView()),
                          );

                          // Xử lý kết quả trả về
                          if (result != null && result is String) {
                            vm.searchController.text = result; // Điền từ khóa vào ô
                            vm.notifyListeners(); // Cập nhật UI nút xóa
                            
                            // Gọi hàm tìm kiếm (bạn chọn hàm phù hợp với logic app)
                            // Ví dụ: Tìm tất cả hoặc tìm bài viết
                            // vm.searchAll(result); // Nếu ViewModel có hàm này
                          }
                        },
                      ),
                    ],
                  ),
                  // --------------------------

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, SearchViewModel vm) {
    final hasQuery = vm.searchController.text.trim().isNotEmpty;

    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (!hasQuery) {
      return _buildEmptySearchState();
    }

    final hasUsers = vm.searchResults.isNotEmpty;
    final hasGroups = vm.groupResults.isNotEmpty;
    final hasPosts = vm.postResults.isNotEmpty;

    if (!hasUsers && !hasGroups && !hasPosts) {
      return _buildNoResultsState(vm);
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      children: [
        if (hasUsers) ..._buildUsersSection(context, vm),
        if (hasUsers && hasGroups) const Divider(thickness: 1, height: 24),
        if (hasGroups) ..._buildGroupsSection(context, vm),
        if ((hasUsers || hasGroups) && hasPosts) const Divider(thickness: 1, height: 24),
        if (hasPosts) ..._buildPostsSection(vm),
        if ((hasUsers || hasGroups) && !hasPosts) _buildViewAllButton(context, vm),
      ],
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tìm kiếm mọi thứ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập từ khóa để tìm người dùng, nhóm hoặc bài viết',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(SearchViewModel vm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            vm.errorMessage ?? 'Không tìm thấy kết quả',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUsersSection(BuildContext context, SearchViewModel vm) {
    return [
      _buildSectionHeader(
        context: context,
        title: 'Người dùng',
        count: vm.searchResults.length,
        vm: vm,
      ),
      ...vm.searchResults.take(3).map((result) => _buildUserResultTile(context, result, vm)),
    ];
  }

  List<Widget> _buildGroupsSection(BuildContext context, SearchViewModel vm) {
    return [
      _buildSectionHeader(
        context: context,
        title: 'Nhóm',
        count: vm.groupResults.length,
        vm: vm,
      ),
      ...vm.groupResults.take(3).map((group) => _buildGroupResultTile(context, group, vm)),
    ];
  }

  List<Widget> _buildPostsSection(SearchViewModel vm) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Bài viết',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      ...vm.postResults.map(
        (post) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PostWidget(
            post: post,
            currentUserDocId: vm.currentUserId ?? '',
          ),
        ),
      ),
    ];
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required int count,
    required SearchViewModel vm,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (count > 3)
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/search-results', arguments: vm);
              },
              child: Text('Xem tất cả ($count)'),
            ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context, SearchViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/search-results', arguments: vm);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Xem tất cả kết quả',
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserResultTile(
    BuildContext context,
    SearchUserResult result,
    SearchViewModel vm,
  ) {
    final user = result.user;
    final status = result.status;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: user.avatar.isNotEmpty ? NetworkImage(user.avatar.first) : null,
        backgroundColor: Colors.grey[300],
        child: user.avatar.isEmpty ? const Icon(Icons.person, size: 24) : null,
      ),
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      trailing: _buildUserActionButton(context, user, status, vm),
      onTap: () => Navigator.pushNamed(context, '/profile', arguments: user.id),
    );
  }

  Widget _buildUserActionButton(
    BuildContext context,
    dynamic user,
    String status,
    SearchViewModel vm,
  ) {
    final buttonData = _getUserButtonData(status);

    return ElevatedButton(
      onPressed: buttonData['action'] != null
          ? () => _handleUserAction(context, user, status, vm, buttonData['action'])
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonData['color'] as Color,
        foregroundColor: buttonData['textColor'] as Color,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(100, 36),
      ),
      child: Text(buttonData['text'] as String),
    );
  }

  Map<String, dynamic> _getUserButtonData(String status) {
    switch (status) {
      case 'friends':
        return {
          'text': 'Bạn bè',
          'color': AppColors.backgroundDark,
          'textColor': AppColors.textPrimary,
          'action': null,
        };
      case 'pending_sent':
        return {
          'text': 'Đã gửi',
          'color': AppColors.backgroundDark,
          'textColor': AppColors.textPrimary,
          'action': null,
        };
      case 'pending_received':
        return {
          'text': 'Phản hồi',
          'color': AppColors.success,
          'textColor': AppColors.textWhite,
          'action': 'respond',
        };
      case 'self':
        return {
          'text': 'Hồ sơ',
          'color': AppColors.primaryLight,
          'textColor': AppColors.textWhite,
          'action': null,
        };
      default:
        return {
          'text': 'Kết bạn',
          'color': AppColors.primaryLight,
          'textColor': AppColors.textWhite,
          'action': 'add',
        };
    }
  }

  void _handleUserAction(
    BuildContext context,
    dynamic user,
    String status,
    SearchViewModel vm,
    dynamic action,
  ) async {
    if (action == 'add') {
      final success = await vm.sendFriendRequest(user.id);
      if (!context.mounted) return;

      if (success) {
        NotificationService().showSuccessDialog(
          context: context,
          title: 'Thành công',
          message: 'Đã gửi lời mời kết bạn đến ${user.name}!',
        );
      } else {
        NotificationService().showWarningDialog(
          context: context,
          title: 'Thất bại',
          message: 'Không thể gửi lời mời kết bạn.',
        );
      }
    } else if (action == 'respond') {
      Navigator.pushNamed(context, '/friends');
    }
  }

  Widget _buildGroupResultTile(
    BuildContext context,
    GroupModel group,
    SearchViewModel vm,
  ) {
    final currentUserId = vm.currentUserId;
    final isMember = currentUserId != null && group.members.contains(currentUserId);

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: group.coverImage.isNotEmpty ? NetworkImage(group.coverImage) : null,
        backgroundColor: Colors.blue[100],
        child: group.coverImage.isEmpty ? const Icon(Icons.group, size: 24, color: Colors.blue) : null,
      ),
      title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(
        '${group.members.length} thành viên',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: ElevatedButton(
        onPressed: isMember ? null : () => _handleGroupAction(context, group, vm),
        style: ElevatedButton.styleFrom(
          backgroundColor: isMember ? AppColors.backgroundDark : AppColors.primaryLight,
          foregroundColor: isMember ? AppColors.textPrimary : AppColors.textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(100, 36),
        ),
        child: Text(isMember ? 'Đã tham gia' : 'Tham gia'),
      ),
      onTap: () => Navigator.pushNamed(context, '/post_group', arguments: group),
    );
  }

  void _handleGroupAction(BuildContext context, GroupModel group, SearchViewModel vm) async {
    final result = await vm.joinGroup(group.id);

    if (!context.mounted) return;

    if (result == 'success') {
      NotificationService().showSuccessDialog(
        context: context,
        title: 'Thành công',
        message: 'Đã tham gia nhóm ${group.name}!',
      );
    } else if (result == 'pending') {
      NotificationService().showSuccessDialog(
        context: context,
        title: 'Yêu cầu đã gửi',
        message: vm.actionError ?? 'Đã gửi yêu cầu tham gia nhóm. Vui lòng chờ phê duyệt.',
      );
    } else {
      NotificationService().showWarningDialog(
        context: context,
        title: 'Thất bại',
        message: vm.actionError ?? 'Không thể tham gia nhóm.',
      );
    }
  }
}