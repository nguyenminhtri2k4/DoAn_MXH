
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/groups_viewmodel.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/request/chat_request.dart';
import 'package:mangxahoi/constant/app_colors.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nhóm của bạn'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
      ),
      body: StreamBuilder<List<GroupModel>>(
        stream: vm.groupsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa tham gia nhóm nào.\nHãy tạo nhóm mới!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            );
          }
          final groups = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    foregroundColor: AppColors.primary,
                    child: Text(group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${group.members.length} thành viên'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () async {
                    final chatId = await ChatRequest().getOrCreateGroupChat(group.id, group.members);
                    Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: {
                        'chatId': chatId,
                        'chatName': group.name,
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create_group'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
    );
  }
}