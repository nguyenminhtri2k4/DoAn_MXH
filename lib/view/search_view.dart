import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/viewmodel/search_view_model.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/notification/notification_service.dart';

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Container(
                height: 40,
                child: TextField(
                  controller: vm.searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm người dùng hoặc nhóm',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon:
                        vm.searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                vm.searchController.clear();
                                vm.clearSearch();
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: _buildBody(context, vm),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tìm kiếm người dùng hoặc nhóm',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhập tên, email hoặc số điện thoại',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (vm.errorMessage != null &&
        vm.searchResults.isEmpty &&
        vm.groupResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    final hasUsers = vm.searchResults.isNotEmpty;
    final hasGroups = vm.groupResults.isNotEmpty;

    if (!hasUsers && !hasGroups) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8.0),
      children: [
        // Preview người dùng
        if (hasUsers) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Người dùng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (vm.searchResults.length > 3)
                  TextButton(
                    onPressed: () {
                      // ✅ FIX: Truyền ViewModel instance qua arguments
                      Navigator.pushNamed(
                        context,
                        '/search-results',
                        arguments: vm,
                      );
                    },
                    child: Text('Xem tất cả (${vm.searchResults.length})'),
                  ),
              ],
            ),
          ),
          ...vm.searchResults
              .take(3)
              .map((result) => _buildUserResultTile(context, result, vm)),
        ],

        // Preview nhóm
        if (hasGroups) ...[
          if (hasUsers) const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nhóm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (vm.groupResults.length > 3)
                  TextButton(
                    onPressed: () {
                      // ✅ FIX: Truyền ViewModel instance qua arguments
                      Navigator.pushNamed(
                        context,
                        '/search-results',
                        arguments: vm,
                      );
                    },
                    child: Text('Xem tất cả (${vm.groupResults.length})'),
                  ),
              ],
            ),
          ),
          ...vm.groupResults
              .take(3)
              .map((group) => _buildGroupResultTile(context, group, vm)),
        ],

        // Nút xem tất cả ở cuối
        if (hasUsers || hasGroups)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // ✅ FIX: Truyền ViewModel instance qua arguments
                Navigator.pushNamed(context, '/search-results', arguments: vm);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Xem tất cả kết quả',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserResultTile(
    BuildContext context,
    SearchUserResult result,
    SearchViewModel vm,
  ) {
    final user = result.user;
    final status = result.status;

    Widget actionButton;
    Color buttonColor;
    String buttonText;
    Function? onPressed;

    switch (status) {
      case 'friends':
        buttonText = 'Bạn bè';
        buttonColor = AppColors.backgroundDark;
        break;
      case 'pending_sent':
        buttonText = 'Đã gửi';
        buttonColor = AppColors.backgroundDark;
        break;
      case 'pending_received':
        buttonText = 'Phản hồi';
        buttonColor = AppColors.success;
        onPressed = () {
          Navigator.pushNamed(context, '/friends');
        };
        break;
      case 'self':
        buttonText = 'Hồ sơ';
        buttonColor = AppColors.primaryLight;
        break;
      case 'none':
      default:
        buttonText = 'Kết bạn';
        buttonColor = AppColors.primaryLight;
        onPressed = () async {
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
        };
        break;
    }

    actionButton = ElevatedButton(
      onPressed: onPressed != null ? () => onPressed!() : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor:
            (status == 'friends' ||
                    status == 'pending_sent' ||
                    status == 'pending_received')
                ? AppColors.textPrimary
                : AppColors.textWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(100, 36),
      ),
      child: Text(buttonText),
    );

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage:
            (user.avatar.isNotEmpty) ? NetworkImage(user.avatar.first) : null,
        backgroundColor: Colors.grey[300],
        child:
            (user.avatar.isEmpty)
                ? const Icon(Icons.person, size: 24, color: Colors.grey)
                : null,
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      trailing: actionButton,
      onTap: () {
        Navigator.pushNamed(context, '/profile', arguments: user.id);
      },
    );
  }

  Widget _buildGroupResultTile(
    BuildContext context,
    GroupModel group,
    SearchViewModel vm,
  ) {
    final currentUserId = vm.currentUserId;
    final isMember =
        currentUserId != null && group.members.contains(currentUserId);

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage:
            group.coverImage.isNotEmpty ? NetworkImage(group.coverImage) : null,
        backgroundColor: Colors.blue[100],
        child:
            group.coverImage.isEmpty
                ? const Icon(Icons.group, size: 24, color: Colors.blue)
                : null,
      ),
      title: Text(
        group.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        '${group.members.length} thành viên',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: ElevatedButton(
        onPressed:
            isMember
                ? null
                : () async {
                  final success = await vm.joinGroup(group.id);
                  if (!context.mounted) return;

                  if (success == 'success') {
                    NotificationService().showSuccessDialog(
                      context: context,
                      title: 'Thành công',
                      message: 'Đã tham gia nhóm ${group.name}!',
                    );
                  } else {
                    NotificationService().showWarningDialog(
                      context: context,
                      title: 'Thất bại',
                      message: 'Không thể tham gia nhóm.',
                    );
                  }
                },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isMember ? AppColors.backgroundDark : AppColors.primaryLight,
          foregroundColor:
              isMember ? AppColors.textPrimary : AppColors.textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(100, 36),
        ),
        child: Text(isMember ? 'Đã tham gia' : 'Tham gia'),
      ),
      onTap: () {
        Navigator.pushNamed(context, '/post_group', arguments: group);
      },
    );
  }
}
