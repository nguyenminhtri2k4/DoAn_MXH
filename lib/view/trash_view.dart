import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/trash_view_model.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:intl/intl.dart';

class TrashView extends StatelessWidget {
  const TrashView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrashViewModel(),
      child: const _TrashViewContent(),
    );
  }
}

class _TrashViewContent extends StatelessWidget {
  const _TrashViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrashViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thùng rácdddd'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<PostModel>>(
              stream: vm.deletedPostsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Thùng rác của bạn trống.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final deletedPosts = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: deletedPosts.length,
                  itemBuilder: (context, index) {
                    final post = deletedPosts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.content.isNotEmpty ? post.content : 'Bài viết không có nội dung',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: post.content.isEmpty ? Colors.grey : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Đã xóa vào: ${DateFormat('dd/MM/yyyy HH:mm').format(post.deletedAt!)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.restore_from_trash, color: AppColors.primary),
                                  label: const Text('Khôi phục', style: TextStyle(color: AppColors.primary)),
                                  onPressed: () async {
                                    await vm.restorePost(post.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã khôi phục bài viết.')),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_forever, color: AppColors.error),
                                  label: const Text('Xóa vĩnh viễn', style: TextStyle(color: AppColors.error)),
                                  onPressed: () async {
                                    await vm.deletePostPermanently(post.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã xóa vĩnh viễn bài viết.')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}