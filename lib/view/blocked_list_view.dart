// lib/view/blocked_list_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/blocked_list_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';

class BlockedListView extends StatelessWidget {
  const BlockedListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BlockedListViewModel(),
      child: const _BlockedListContent(),
    );
  }
}

class _BlockedListContent extends StatelessWidget {
  const _BlockedListContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BlockedListViewModel>();
    final listener = context.watch<FirestoreListener>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Người dùng bị chặn'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<String>>(
        stream: vm.blockedUsersStream,
        builder: (context, snapshot) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa chặn người dùng nào.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final blockedIds = snapshot.data!;
          // Lấy thông tin UserModel từ ID
          final blockedUsers = blockedIds
              .map((id) => listener.getUserById(id))
              .where((user) => user != null)
              .cast<UserModel>()
              .toList();

          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatar.isNotEmpty ? NetworkImage(user.avatar.first) : null,
                  child: user.avatar.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user.email),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await vm.unblockUser(user.id);
                    if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã bỏ chặn ${user.name}')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundDark,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text('Bỏ chặn'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}