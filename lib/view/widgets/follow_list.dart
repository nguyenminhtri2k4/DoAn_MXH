import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/viewmodel/follow_view_model.dart';
import 'package:mangxahoi/view/widgets/follow_button.dart';

class FollowList extends StatelessWidget {
  final bool isFollowers;
  const FollowList({super.key, required this.isFollowers});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FollowViewModel>();
    final stream = isFollowers ? vm.followersStream : vm.followingStream;

    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final users = snapshot.data!;
        return Column(
          children: [
            _buildCountHeader(users.length),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildUserItem(context, users[index], vm),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFollowers ? Icons.people_outline : Icons.person_add_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isFollowers ? 'Chưa có người theo dõi' : 'Chưa theo dõi ai',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCountHeader(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.backgroundLight,
      child: Text(
        '$count ${isFollowers ? 'người theo dõi' : 'đang theo dõi'}',
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, UserModel user, FollowViewModel vm) {
    // Sử dụng UID từ Firebase Auth để so sánh nhanh xem có phải chính mình không
    // Điều này vẫn đúng vì mỗi UserModel đều có trường 'uid' lưu Auth UID
    final currentAuthUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = currentAuthUid == user.uid;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/profile', arguments: user.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: user.avatar.isNotEmpty ? NetworkImage(user.avatar.first) : null,
              child: user.avatar.isEmpty
                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  if (user.bio.isNotEmpty && user.bio != 'No')
                    Text(
                      user.bio,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (!isMe)
              SizedBox(
                height: 36,
                // Truyền user.id (Document ID) vào nút Follow
                child: FollowButton(
                  key: ValueKey('follow_${user.id}'),
                  targetUserId: user.id,
                  viewModel: vm,
                ),
              ),
          ],
        ),
      ),
    );
  }
}