import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/create_group_viewmodel.dart';
import 'package:mangxahoi/constant/app_colors.dart';

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
    final canCreate = vm.selectedFriends.length >= 1 && vm.groupNameController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo nhóm mới'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: !canCreate
                  ? null
                  : () async {
                      final success = await vm.createGroup();
                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              style: TextButton.styleFrom(
                foregroundColor: canCreate ? AppColors.primary : AppColors.textDisabled,
              ),
              child: const Text('Tạo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: vm.groupNameController,
              decoration: InputDecoration(
                labelText: 'Tên nhóm',
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.group_work),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mời thành viên (${vm.selectedFriends.length} đã chọn)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textSecondary),
              ),
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: vm.friends.length,
                    itemBuilder: (context, index) {
                      final friend = vm.friends[index];
                      final isSelected = vm.selectedFriends.contains(friend);
                      final avatarImage = friend.avatar.isNotEmpty
                          ? NetworkImage(friend.avatar.first)
                          : null;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          activeColor: AppColors.primary,
                          secondary: CircleAvatar(
                            backgroundImage: avatarImage,
                            child: avatarImage == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(friend.email, style: const TextStyle(color: AppColors.textSecondary)),
                          value: isSelected,
                          onChanged: (bool? value) {
                            vm.toggleFriendSelection(friend);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}