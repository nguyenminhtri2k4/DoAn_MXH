import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/request/user_request.dart'; // ✅ Import UserRequest
// import 'package:mangxahoi/services/user_service.dart'; // ❌ Bỏ hoặc không dùng UserService ở đây
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class PostApprovalView extends StatelessWidget {
  final String groupId;
  final PostRequest _postRequest = PostRequest();
  
  // ✅ SỬA: Dùng UserRequest thay vì UserService để fetch info người khác
  final UserRequest _userRequest = UserRequest(); 

  PostApprovalView({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: _postRequest.getPendingPostsByGroupId(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Không có bài viết nào cần duyệt',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          separatorBuilder: (ctx, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildApprovalCard(context, post);
          },
        );
      },
    );
  }

  Widget _buildApprovalCard(BuildContext context, PostModel post) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Người đăng + Thời gian
          FutureBuilder<UserModel?>(
            // ✅ SỬA: Gọi hàm getUserByUid từ UserRequest
            // Nếu authorId là Document ID thì dùng getUserData(post.authorId)
            // Nếu authorId là Auth UID (phổ biến hơn) thì dùng getUserByUid(post.authorId)
            future: _userRequest.getUserByUid(post.authorId), 
            builder: (context, snapshot) {
              final user = snapshot.data;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (user?.avatar.isNotEmpty ?? false)
                      ? CachedNetworkImageProvider(user!.avatar.first)
                      : null,
                  child: (user?.avatar.isEmpty ?? true) ? const Icon(Icons.person) : null,
                ),
                title: Text(
                  user?.name ?? 'Người dùng',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(post.createdAt)),
              );
            },
          ),
          
          // Nội dung bài viết (Preview)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.content.isNotEmpty)
                  Text(
                    post.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
                  ),
                if (post.mediaIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(post.mediaIds.first),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: post.mediaIds.length > 1
                          ? Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${post.mediaIds.length - 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(),

          // Buttons: Duyệt / Từ chối
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _postRequest.rejectGroupPost(post.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _postRequest.approveGroupPost(post.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Duyệt bài'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}