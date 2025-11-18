// lib/view/post/post_detail_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:provider/provider.dart';

class PostDetailView extends StatelessWidget {
  final String postId;

  const PostDetailView({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<UserService>().currentUser?.id;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text("Lỗi: Người dùng không xác định.")),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('Post').doc(postId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy bài viết.'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi.'));
          }

          final post = PostModel.fromMap(snapshot.data!.id, snapshot.data!.data() as Map<String, dynamic>);
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: PostWidget(
                post: post,
                currentUserDocId: currentUserId,
              ),
            ),
          );
        },
      ),
    );
  }
}