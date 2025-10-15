// lib/view/groups_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/groups_viewmodel.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/request/chat_request.dart'; // Thêm import này

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
      appBar: AppBar(
        title: const Text('Nhóm của bạn'),
      ),
      body: StreamBuilder<List<GroupModel>>(
        stream: vm.groupsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bạn chưa tham gia nhóm nào.'));
          }
          final groups = snapshot.data!;
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: CircleAvatar(child: Text(group.name[0])),
                title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${group.members.length} thành viên'),
                onTap: () async {
                  // Lấy hoặc tạo phòng chat cho nhóm
                  final chatId = await ChatRequest().getOrCreateGroupChat(group.id, group.members);
                  // Điều hướng đến màn hình chat với thông tin cần thiết
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {
                      'chatId': chatId,
                      'chatName': group.name,
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create_group'),
        child: const Icon(Icons.add),
      ),
    );
  }
}