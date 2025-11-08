
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/groups_viewmodel.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/request/chat_request.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <-- THÊM IMPORT NÀY

class GroupsView extends StatelessWidget {
  const GroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupsViewModel(),
      child: const _GroupsViewContent(),
    );
  }
}

class _GroupsViewContent extends StatelessWidget {
  const _GroupsViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GroupsViewModel>();

    return StreamBuilder<List<GroupModel>>(
      stream: vm.groupsStream,
      builder: (context, snapshot) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text(
                'Nhóm của bạn',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.chat_bubble_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Chat'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.article_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Bài viết'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: snapshot.connectionState == ConnectionState.waiting
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Đang tải danh sách nhóm...',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _GroupsList(type: 'chat', allGroups: snapshot.data ?? []),
                      _GroupsList(type: 'post', allGroups: snapshot.data ?? []),
                    ],
                  ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/create_group'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add),
              label: const Text(
                'Tạo nhóm',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroupsList extends StatelessWidget {
  final String type;
  final List<GroupModel> allGroups;

  const _GroupsList({required this.type, required this.allGroups});

  @override
  Widget build(BuildContext context) {
    // Lọc nhóm theo type
    final groups = allGroups.where((g) => g.type == type).toList();

    if (groups.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: groups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildGroupCard(context, group);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'chat' ? Icons.chat_bubble_outline : Icons.article_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            type == 'chat'
                ? 'Chưa có nhóm chat nào'
                : 'Chưa có nhóm bài viết nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút "Tạo nhóm" để bắt đầu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM MỚI ĐỂ HIỂN THỊ ICON MẶC ĐỊNH ---
  Widget _buildDefaultIcon(String type) {
    return Icon(
      type == 'chat' ? Icons.chat_bubble : Icons.article,
      color: Colors.white,
      size: 28,
    );
  }

  Widget _buildGroupCard(BuildContext context, GroupModel group) {
    // Kiểm tra xem có ảnh bìa không
    final bool hasCoverImage = group.coverImage.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onGroupTap(context, group),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                
                // --- SỬA ĐỔI PHẦN AVATAR/ICON NHÓM ---
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    // Chỉ hiện gradient nếu KHÔNG có ảnh
                    gradient: !hasCoverImage
                        ? LinearGradient(
                            colors: type == 'chat'
                                ? [Colors.blue[400]!, Colors.blue[600]!]
                                : [Colors.purple[400]!, Colors.purple[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    // Màu nền xám cho lúc tải ảnh
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (type == 'chat' ? Colors.blue : Colors.purple)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  // ClipRRect để bo tròn ảnh
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: hasCoverImage
                        // Nếu có ảnh, dùng CachedNetworkImage
                        ? CachedNetworkImage(
                            imageUrl: group.coverImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[200]),
                            // Nếu ảnh lỗi, quay về icon mặc định
                            errorWidget: (context, url, error) =>
                                _buildDefaultIcon(group.type),
                          )
                        // Nếu không có ảnh, dùng icon mặc định
                        : _buildDefaultIcon(group.type),
                  ),
                ),
                // --- KẾT THÚC SỬA ĐỔI ---

                const SizedBox(width: 16),

                // Thông tin nhóm
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${group.members.length} thành viên',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Icon mũi tên
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onGroupTap(BuildContext context, GroupModel group) async {
    if (group.type == 'chat') {
      final chatId = await ChatRequest().getOrCreateGroupChat(
        group.id,
        group.members,
      );
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'chatId': chatId,
            'chatName': group.name,
          },
        );
      }
    } else {
      Navigator.pushNamed(context, '/post_group', arguments: group);
    }
  }
}