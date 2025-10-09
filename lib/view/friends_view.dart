import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/friends_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_friend_request.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/model/model_user.dart';

class FriendsView extends StatelessWidget {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Truyền FirestoreListener vào ViewModel
    return ChangeNotifierProvider(
      create: (context) => FriendsViewModel(context.read<FirestoreListener>()),
      child: const _FriendsViewContent(),
    );
  }
}

class _FriendsViewContent extends StatelessWidget {
  const _FriendsViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bạn bè', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 1,
        actions: [
          IconButton(
            // Kính lúp cho chức năng TÌM KIẾM BẠN BÈ (Friend Search)
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng tìm kiếm trong danh sách bạn bè đang được triển khai.')),
              );
            },
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          // Kiểm tra incomingRequestsStream có null không trước khi render SingleChildScrollView
          : (vm.incomingRequestsStream == null) 
              ? const Center(child: Text('Đang chờ dữ liệu người dùng...'))
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================
                  // === PHẦN 1: LỜI MỜI KẾT BẠN (INCOMING - toUserId) ===
                  // ==================================
                  _buildRequestSection(
                    context,
                    title: 'Lời mời kết bạn',
                    stream: vm.incomingRequestsStream!,
                    vm: vm,
                    isIncoming: true,
                  ),
                  const SizedBox(height: 20),
                  
                  // ==================================
                  // === PHẦN 2: LỜI MỜI ĐÃ GỬI (SENT - fromUserId) ===
                  // ==================================
                  _buildRequestSection(
                    context,
                    title: 'Lời mời đã gửi',
                    stream: vm.sentRequestsStream!,
                    vm: vm,
                    isIncoming: false,
                  ),

                  // Thêm phần "Những người bạn có thể biết" 
                  const SizedBox(height: 20),
                  const Text('Những người bạn có thể biết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  // ... (Placeholder cho Gợi ý bạn bè)
                ],
              ),
            ),
    );
  }

  Widget _buildRequestSection(
    BuildContext context, {
    required String title,
    required Stream<List<FriendRequestModel>> stream,
    required FriendsViewModel vm,
    required bool isIncoming,
  }) {
    final listener = context.read<FirestoreListener>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hiển thị số lượng và tiêu đề
        StreamBuilder<List<FriendRequestModel>>(
            stream: stream,
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Text('$title ($count)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (count > 0 && isIncoming) 
                          TextButton(onPressed: () {}, child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primary))),
                  ],
              );
            }
        ),
        const Divider(),
        // Hiển thị danh sách chi tiết
        StreamBuilder<List<FriendRequestModel>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(isIncoming ? 'Bạn không có lời mời kết bạn nào.' : 'Bạn chưa gửi lời mời kết bạn nào.', style: TextStyle(color: Colors.grey[600])),
              );
            }
            
            return Column(
              children: requests.map((request) {
                // Lấy ID của người cần hiển thị:
                // - Nếu là Incoming (toUserId), ta hiển thị người gửi (fromUserId).
                // - Nếu là Sent (fromUserId), ta hiển thị người nhận (toUserId).
                final targetUserId = isIncoming ? request.fromUserId : request.toUserId; 
                final user = listener.getUserById(targetUserId);

                return _buildRequestTile(
                  context,
                  request,
                  user,
                  vm,
                  isIncoming,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRequestTile(
    BuildContext context,
    FriendRequestModel request,
    UserModel? user,
    FriendsViewModel vm,
    bool isIncoming,
  ) {
    // Nếu thông tin người dùng chưa tải (do FirestoreListener chạy chậm), hiển thị Placeholder
    if (user == null) {
      return const ListTile(
        leading: CircleAvatar(radius: 30, child: Icon(Icons.person)),
        title: Text('Đang tải thông tin...', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Vui lòng chờ'),
      ); 
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: user.avatar.isNotEmpty ? NetworkImage(user.avatar.first) : null,
            child: user.avatar.isEmpty ? const Icon(Icons.person, size: 30) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                // Sử dụng bio hoặc mô tả mặc định
                Text(
                  user.bio.isNotEmpty ? user.bio : (isIncoming ? 'Gửi lời mời kết bạn' : 'Chờ chấp nhận'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          isIncoming
              ? Row( // Nút Chấp nhận / Xóa (Incoming)
                  children: [
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => vm.acceptRequest(request),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text('Chấp nhận'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () => vm.rejectOrCancelRequest(request.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.divider),
                          backgroundColor: AppColors.backgroundDark,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text('Xóa'),
                      ),
                    ),
                  ],
                )
              : SizedBox( // Nút Hủy (Sent)
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => vm.rejectOrCancelRequest(request.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      backgroundColor: AppColors.backgroundDark,
                    ),
                    child: const Text('Hủy lời mời'),
                  ),
                ),
        ],
      ),
    );
  }
}