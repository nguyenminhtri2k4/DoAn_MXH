import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/trash_view_model.dart';
import 'package:mangxahoi/viewmodel/locket_trash_view_model.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TrashView extends StatelessWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrashViewModel()),
        ChangeNotifierProvider(create: (_) => LocketTrashViewModel()),
      ],
      child: const _TrashViewContent(),
    );
  }
}

class _TrashViewContent extends StatefulWidget {
  const _TrashViewContent();

  @override
  State<_TrashViewContent> createState() => _TrashViewContentState();
}

class _TrashViewContentState extends State<_TrashViewContent> {
  int _selectedIndex = 0; // 0 = Bài viết, 1 = Locket

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Thùng rác',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Toggle Buttons Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabChip(
                    label: 'Bài viết',
                    icon: Icons.delete_outline,
                    isSelected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabChip(
                    label: 'Locket',
                    icon: Icons.delete_sweep_outlined,
                    isSelected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child:
                _selectedIndex == 0
                    ? const _PostTrashTab()
                    : const _LocketTrashTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TAB BÀI VIẾT ====================
class _PostTrashTab extends StatefulWidget {
  const _PostTrashTab();

  @override
  State<_PostTrashTab> createState() => _PostTrashTabState();
}

class _PostTrashTabState extends State<_PostTrashTab> {
  final Set<String> _selectedPostIds = {};

  void _togglePostSelection(String postId) {
    setState(() {
      if (_selectedPostIds.contains(postId)) {
        _selectedPostIds.remove(postId);
      } else {
        _selectedPostIds.add(postId);
      }
    });
  }

  void _selectAll(List<PostModel> posts) {
    setState(() {
      if (_selectedPostIds.length == posts.length) {
        _selectedPostIds.clear();
      } else {
        _selectedPostIds.clear();
        _selectedPostIds.addAll(posts.map((p) => p.id));
      }
    });
  }

  Future<void> _deleteSelectedPosts(TrashViewModel vm) async {
    if (_selectedPostIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => _ConfirmDialog(
            title: 'Xác nhận xóa',
            content:
                'Bạn có chắc chắn muốn xóa vĩnh viễn ${_selectedPostIds.length} bài viết?',
          ),
    );

    if (confirm == true) {
      final count = _selectedPostIds.length;
      for (final postId in _selectedPostIds) {
        await vm.deletePostPermanently(postId);
      }
      if (mounted) {
        setState(() => _selectedPostIds.clear());
        _showSnackBar('Đã xóa vĩnh viễn $count bài viết', isError: true);
      }
    }
  }

  Future<void> _restoreSelectedPosts(TrashViewModel vm) async {
    if (_selectedPostIds.isEmpty) return;

    final count = _selectedPostIds.length;
    for (final postId in _selectedPostIds) {
      await vm.restorePost(postId);
    }
    if (mounted) {
      setState(() => _selectedPostIds.clear());
      _showSnackBar('Đã khôi phục $count bài viết');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.delete_forever : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrashViewModel>();

    return vm.isLoading
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<List<PostModel>>(
          stream: vm.deletedPostsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text('Lỗi: ${snapshot.error}'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
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
                        Icons.delete_outline_rounded,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Thùng rác trống',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Các bài viết đã xóa sẽ xuất hiện ở đây',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final deletedPosts = snapshot.data!;

            return Column(
              children: [
                // Select all bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value:
                            _selectedPostIds.length == deletedPosts.length &&
                            deletedPosts.isNotEmpty,
                        tristate:
                            _selectedPostIds.isNotEmpty &&
                            _selectedPostIds.length < deletedPosts.length,
                        onChanged: (value) => _selectAll(deletedPosts),
                      ),
                      const Text(
                        'Tất cả',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedPostIds.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.restore_rounded),
                          color: AppColors.primary,
                          onPressed: () => _restoreSelectedPosts(vm),
                          tooltip: 'Khôi phục',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_rounded),
                          color: AppColors.error,
                          onPressed: () => _deleteSelectedPosts(vm),
                          tooltip: 'Xóa vĩnh viễn',
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Posts list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: deletedPosts.length,
                    itemBuilder: (context, index) {
                      final post = deletedPosts[index];
                      final isSelected = _selectedPostIds.contains(post.id);

                      return _PostCard(
                        post: post,
                        isSelected: isSelected,
                        onToggleSelect: () => _togglePostSelection(post.id),
                        onRestore: () async {
                          await vm.restorePost(post.id);
                          if (context.mounted) {
                            _showSnackBar('Đã khôi phục bài viết');
                          }
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => const _ConfirmDialog(
                                  title: 'Xác nhận xóa',
                                  content:
                                      'Bài viết sẽ bị xóa vĩnh viễn và không thể khôi phục. Bạn có chắc chắn?',
                                ),
                          );

                          if (confirm == true) {
                            await vm.deletePostPermanently(post.id);
                            if (context.mounted) {
                              _showSnackBar('Đã xóa vĩnh viễn', isError: true);
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
  }
}

// ==================== TAB LOCKET ====================
class _LocketTrashTab extends StatefulWidget {
  const _LocketTrashTab();

  @override
  State<_LocketTrashTab> createState() => _LocketTrashTabState();
}

class _LocketTrashTabState extends State<_LocketTrashTab> {
  final Set<String> _selectedLocketIds = {};

  void _toggleLocketSelection(String locketId) {
    setState(() {
      if (_selectedLocketIds.contains(locketId)) {
        _selectedLocketIds.remove(locketId);
      } else {
        _selectedLocketIds.add(locketId);
      }
    });
  }

  void _selectAll(List<LocketPhoto> lockets) {
    setState(() {
      if (_selectedLocketIds.length == lockets.length) {
        _selectedLocketIds.clear();
      } else {
        _selectedLocketIds.clear();
        _selectedLocketIds.addAll(lockets.map((l) => l.id));
      }
    });
  }

  Future<void> _deleteSelectedLockets(LocketTrashViewModel vm) async {
    if (_selectedLocketIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => _ConfirmDialog(
            title: 'Xác nhận xóa',
            content:
                'Bạn có chắc chắn muốn xóa vĩnh viễn ${_selectedLocketIds.length} locket?',
          ),
    );

    if (confirm == true) {
      final count = _selectedLocketIds.length;
      for (final locketId in _selectedLocketIds) {
        await vm.deleteLocketPermanently(locketId);
      }
      if (mounted) {
        setState(() => _selectedLocketIds.clear());
        _showSnackBar('Đã xóa vĩnh viễn $count locket', isError: true);
      }
    }
  }

  Future<void> _restoreSelectedLockets(LocketTrashViewModel vm) async {
    if (_selectedLocketIds.isEmpty) return;

    final count = _selectedLocketIds.length;
    for (final locketId in _selectedLocketIds) {
      await vm.restoreLocket(locketId);
    }
    if (mounted) {
      setState(() => _selectedLocketIds.clear());
      _showSnackBar('Đã khôi phục $count locket');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.delete_forever : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocketTrashViewModel>();

    return StreamBuilder<List<LocketPhoto>>(
      stream: vm.deletedLocketsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Lỗi: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
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
                    Icons.delete_sweep_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Thùng rác trống',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Các locket đã xóa sẽ xuất hiện ở đây',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final deletedLockets = snapshot.data!;

        return Column(
          children: [
            // Select all bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value:
                        _selectedLocketIds.length == deletedLockets.length &&
                        deletedLockets.isNotEmpty,
                    tristate:
                        _selectedLocketIds.isNotEmpty &&
                        _selectedLocketIds.length < deletedLockets.length,
                    onChanged: (value) => _selectAll(deletedLockets),
                  ),
                  const Text(
                    'Tất cả',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  if (_selectedLocketIds.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.restore_rounded),
                      color: AppColors.primary,
                      onPressed: () => _restoreSelectedLockets(vm),
                      tooltip: 'Khôi phục',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_rounded),
                      color: AppColors.error,
                      onPressed: () => _deleteSelectedLockets(vm),
                      tooltip: 'Xóa vĩnh viễn',
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            // Lockets list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: deletedLockets.length,
                itemBuilder: (context, index) {
                  final locket = deletedLockets[index];
                  final isSelected = _selectedLocketIds.contains(locket.id);

                  return _LocketCard(
                    locket: locket,
                    isSelected: isSelected,
                    onToggleSelect: () => _toggleLocketSelection(locket.id),
                    onRestore: () async {
                      await vm.restoreLocket(locket.id);
                      if (context.mounted) {
                        _showSnackBar('Đã khôi phục locket');
                      }
                    },
                    onDelete: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => const _ConfirmDialog(
                              title: 'Xác nhận xóa',
                              content:
                                  'Locket sẽ bị xóa vĩnh viễn và không thể khôi phục. Bạn có chắc chắn?',
                            ),
                      );

                      if (confirm == true) {
                        await vm.deleteLocketPermanently(locket.id);
                        if (context.mounted) {
                          _showSnackBar('Đã xóa vĩnh viễn', isError: true);
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== WIDGET CARDS ====================
class _PostCard extends StatelessWidget {
  final PostModel post;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onRestore,
    required this.onDelete,
  });

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : Colors.grey[400]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.content.isNotEmpty
                                ? post.content
                                : 'Bài viết không có nội dung',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color:
                                  post.content.isEmpty
                                      ? Colors.grey[400]
                                      : Colors.grey[800],
                              fontWeight:
                                  post.content.isEmpty
                                      ? FontWeight.w400
                                      : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Đã xóa ${_getTimeAgo(post.deletedAt!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey[100]),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.restore_rounded,
                        label: 'Khôi phục',
                        color: AppColors.primary,
                        onPressed: onRestore,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.delete_forever_rounded,
                        label: 'Xóa vĩnh viễn',
                        color: AppColors.error,
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocketCard extends StatelessWidget {
  final LocketPhoto locket;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _LocketCard({
    required this.locket,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onRestore,
    required this.onDelete,
  });

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (locket.imageUrl.isNotEmpty)
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: locket.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error, size: 50),
                          ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : Colors.grey[400]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locket Photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Đã xóa ${_getTimeAgo(locket.deletedAt!.toDate())}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey[100]),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.restore_rounded,
                        label: 'Khôi phục',
                        color: AppColors.primary,
                        onPressed: onRestore,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.delete_forever_rounded,
                        label: 'Xóa vĩnh viễn',
                        color: AppColors.error,
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;

  const _ConfirmDialog({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Xóa vĩnh viễn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
