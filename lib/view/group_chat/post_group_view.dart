import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/viewmodel/post_group_viewmodel.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:mangxahoi/model/model_user.dart';

class PostGroupView extends StatelessWidget {
  final GroupModel group;

  const PostGroupView({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostGroupViewModel(group: group),
      child: const _PostGroupViewContent(),
    );
  }
}

class _PostGroupViewContent extends StatelessWidget {
  const _PostGroupViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PostGroupViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 250.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.backgroundLight,
                    foregroundColor: AppColors.textPrimary,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        vm.group.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.groups,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: _buildBodyWithPosts(context, vm),
            ),
    );
  }

  Widget _buildBodyWithPosts(BuildContext context, PostGroupViewModel vm) {
    if (vm.currentUserData == null) {
      return const Center(child: Text("Không thể tải dữ liệu người dùng"));
    }

    return Container(
      color: AppColors.background,
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
            padding: const EdgeInsets.all(8.0),
            children: [
              _buildCreatePostSection(context, vm),
              if (posts.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('Bài viết trong nhóm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              if (posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 50.0),
                  child: Center(child: Text("Chưa có bài viết nào trong nhóm.")),
                ),
              ...posts.map((post) => PostWidget(
                    post: post,
                    currentUserDocId: vm.currentUserData!.id,
                  )).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreatePostSection(BuildContext context, PostGroupViewModel vm) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: InkWell(
          onTap: () {
            // Sửa đổi cách truyền tham số để nó là một Map
            Navigator.pushNamed(
              context,
              '/create_post',
              arguments: {
                'currentUser': vm.currentUserData!,
                'groupId': vm.group.id,
              },
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: vm.currentUserData!.avatar.isNotEmpty
                    ? NetworkImage(vm.currentUserData!.avatar.first)
                    : null,
                child: vm.currentUserData!.avatar.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Viết gì đó trong nhóm...',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ),
              const Icon(Icons.edit, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}