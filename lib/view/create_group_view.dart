// lib/view/create_group_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/create_group_viewmodel.dart';
import 'package:mangxahoi/model/model_user.dart';

class CreateGroupView extends StatelessWidget {
  const CreateGroupView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateGroupViewModel(),
      child: const _CreateGroupViewContent(),
    );
  }
}

class _CreateGroupViewContent extends StatelessWidget {
  const _CreateGroupViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateGroupViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo nhóm mới'),
        actions: [
          TextButton(
            onPressed: (vm.selectedFriends.length < 1 || vm.groupNameController.text.isEmpty)
                ? null
                : () async {
                    final success = await vm.createGroup();
                    if (success && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            child: const Text('Tạo'),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: vm.groupNameController,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mời thành viên (${vm.selectedFriends.length} đã chọn)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: vm.friends.length,
                    itemBuilder: (context, index) {
                      final friend = vm.friends[index];
                      final isSelected = vm.selectedFriends.contains(friend);

                      // **SỬA LỖI TẠI ĐÂY**: Kiểm tra xem danh sách avatar có rỗng không
                      final avatarImage = friend.avatar.isNotEmpty
                          ? NetworkImage(friend.avatar.first)
                          : null;

                      return CheckboxListTile(
                        secondary: CircleAvatar(
                          backgroundImage: avatarImage,
                          // Nếu không có ảnh, hiển thị icon
                          child: avatarImage == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(friend.name),
                        subtitle: Text(friend.email),
                        value: isSelected,
                        onChanged: (bool? value) {
                          vm.toggleFriendSelection(friend);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}