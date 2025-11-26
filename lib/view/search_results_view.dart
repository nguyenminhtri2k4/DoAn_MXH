
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/search_view_model.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/notification/notification_service.dart';

class SearchResultsView extends StatelessWidget {
  const SearchResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Nhận ViewModel từ arguments thay vì tạo mới
    final vm = ModalRoute.of(context)!.settings.arguments as SearchViewModel?;

    if (vm == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không tìm thấy dữ liệu tìm kiếm')),
      );
    }

    // Wrap với ChangeNotifierProvider.value để sử dụng instance có sẵn
    return ChangeNotifierProvider<SearchViewModel>.value(
      value: vm,
      child: const _SearchResultsContent(),
    );
  }
}

class _SearchResultsContent extends StatefulWidget {
  const _SearchResultsContent();

  @override
  State<_SearchResultsContent> createState() => _SearchResultsContentState();
}

class _SearchResultsContentState extends State<_SearchResultsContent> {
  String _selectedFilter = 'all'; // all, users, groups

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          child: TextField(
            controller: vm.searchController,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
              suffixIcon:
                  vm.searchController.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        onPressed: () {
                          vm.searchController.clear();
                          vm.clearSearch();
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 12,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Bộ lọc
          _buildFilterTabs(),
          const Divider(height: 1, thickness: 1),

          // Kết quả
          Expanded(child: _buildResults(vm)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Tất cả', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Người dùng', 'users'),
          const SizedBox(width: 8),
          _buildFilterChip('Nhóm', 'groups'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResults(SearchViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    if (vm.searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nhập từ khóa để tìm kiếm',
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
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Từ khóa: "${vm.searchController.text}"',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Hiển thị người dùng
        if (_selectedFilter == 'all' || _selectedFilter == 'users')
          if (hasUsers) ...[
            _buildSectionHeader('Người dùng', vm.searchResults.length),
            ...vm.searchResults.map((result) => _buildUserTile(result, vm)),
          ],

        // Hiển thị nhóm
        if (_selectedFilter == 'all' || _selectedFilter == 'groups')
          if (hasGroups) ...[
            if (hasUsers && _selectedFilter == 'all')
              const SizedBox(height: 16),
            _buildSectionHeader('Nhóm', vm.groupResults.length),
            ...vm.groupResults.map((group) => _buildGroupTile(group, vm)),
          ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildUserTile(SearchUserResult result, SearchViewModel vm) {
    final user = result.user;
    final status = result.status;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage:
              user.avatar.isNotEmpty ? NetworkImage(user.avatar.first) : null,
          backgroundColor: Colors.grey[300],
          child:
              user.avatar.isEmpty
                  ? const Icon(Icons.person, size: 24, color: Colors.grey)
                  : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          _getStatusText(status),
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: _buildUserActionButton(user, status, vm),
        onTap: () {
          Navigator.pushNamed(context, '/profile', arguments: user.id);
        },
      ),
    );
  }

  Widget _buildGroupTile(GroupModel group, SearchViewModel vm) {
    final currentUserId = vm.currentUserId;
    final isMember =
        currentUserId != null && group.members.contains(currentUserId);

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage:
              group.coverImage.isNotEmpty
                  ? NetworkImage(group.coverImage)
                  : null,
          backgroundColor: Colors.blue[100],
          child:
              group.coverImage.isEmpty
                  ? const Icon(Icons.group, size: 24, color: Colors.blue)
                  : null,
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${group.members.length} thành viên',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (group.description.isNotEmpty)
              Text(
                group.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
          ],
        ),
        trailing: _buildGroupActionButton(group, vm, isMember),
        onTap: () {
          Navigator.pushNamed(context, '/post_group', arguments: group);
        },
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'friends':
        return 'Bạn bè';
      case 'pending_sent':
        return 'Đã gửi lời mời';
      case 'pending_received':
        return 'Đã gửi lời mời cho bạn';
      case 'self':
        return 'Chính bạn';
      default:
        return '';
    }
  }

  Widget _buildUserActionButton(
    UserModel user,
    String status,
    SearchViewModel vm,
  ) {
    switch (status) {
      case 'friends':
        return TextButton(
          onPressed: null,
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Bạn bè'),
        );
      case 'pending_sent':
        return TextButton(
          onPressed: null,
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Đã gửi'),
        );
      case 'pending_received':
        return TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/friends');
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Phản hồi'),
        );
      case 'self':
        return const SizedBox.shrink();
      default:
        return TextButton(
          onPressed: () async {
            final success = await vm.sendFriendRequest(user.id);
            if (!mounted) return;

            if (success) {
              NotificationService().showSuccessDialog(
                context: context,
                title: 'Thành công',
                message: 'Đã gửi lời mời kết bạn!',
              );
            } else {
              NotificationService().showWarningDialog(
                context: context,
                title: 'Thất bại',
                message: 'Không thể gửi lời mời.',
              );
            }
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Kết bạn'),
        );
    }
  }

  Widget _buildGroupActionButton(
  GroupModel group,
  SearchViewModel vm,
  bool isMember,
) {
  if (isMember) {
    return TextButton(
      onPressed: null,
      style: TextButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: const Text('Đã tham gia'),
    );
  }

  return TextButton(
    onPressed: () async {
      final result = await vm.joinGroup(group.id);
      
      if (!mounted) return;

      // ✅ Kiểm tra result
      if (result == 'success') {
        // Đã tham gia nhóm (open join)
        NotificationService().showSuccessDialog(
          context: context,
          title: 'Thành công',
          message: 'Đã tham gia nhóm ${group.name}!',
        );
      } else if (result == 'pending') {
        // Gửi request thành công (requires_approval)
        NotificationService().showSuccessDialog(
          context: context,
          title: 'Yêu cầu đã gửi',
          message: vm.actionError ?? 'Yêu cầu tham gia đã được gửi. Vui lòng chờ phê duyệt.',
        );
      } else {
        // Lỗi
        NotificationService().showWarningDialog(
          context: context,
          title: 'Thất bại',
          message: vm.actionError ?? 'Không thể tham gia nhóm.',
        );
      }
    },
    style: TextButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    child: const Text('Tham gia'),
  );
}
}