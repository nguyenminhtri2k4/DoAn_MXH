import 'package:flutter/material.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/view/group_chat/join_requests_view.dart'; // Import view cũ bạn đã có
import 'package:mangxahoi/view/group_chat/post_approval_view.dart'; // Import view mới vừa tạo

class GroupManagementRequestsView extends StatelessWidget {
  final String groupId;
  final String groupName;

  const GroupManagementRequestsView({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quản lý yêu cầu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                groupName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(
                icon: Icon(Icons.person_add_outlined),
                text: "Thành viên",
              ),
              Tab(
                icon: Icon(Icons.post_add_outlined),
                text: "Bài viết",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Duyệt thành viên (Dùng lại View cũ của bạn, cần chỉnh sửa JoinRequestsView một chút để bỏ Scaffold nếu muốn đẹp hơn, hoặc để nguyên cũng được)
            JoinRequestsView(groupId: groupId),
            
            // Tab 2: Duyệt bài viết
            PostApprovalView(groupId: groupId),
          ],
        ),
      ),
    );
  }
}