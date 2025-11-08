// lib/view/like_list_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangxahoi/constant/reactions.dart' as reaction_helper;

class LikeListView extends StatefulWidget {
  final String postId;

  const LikeListView({super.key, required this.postId});

  @override
  State<LikeListView> createState() => _LikeListViewState();
}

class _LikeListViewState extends State<LikeListView> {
  Future<List<Map<String, String>>>? _reactionsFuture;

  @override
  void initState() {
    super.initState();
    _reactionsFuture = _fetchReactions();
  }

  Future<List<Map<String, String>>> _fetchReactions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Post')
        .doc(widget.postId)
        .collection('reactions')
        .get();
    
    return snapshot.docs.map((doc) {
      return {
        'userId': doc.id, // ID của người reaction
        'type': (doc.data()['type'] as String?) ?? 'like', // Loại reaction
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lượt tương tác'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
      ),
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Map<String, String>>>( 
        future: _reactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải danh sách.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có tương tác nào.'));
          }

          final reactions = snapshot.data!;
          final listener = context.watch<FirestoreListener>();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: reactions.length,
            itemBuilder: (context, index) {
              final reaction = reactions[index];
              final userId = reaction['userId']!;
              final reactionType = reaction['type']!;
              final user = listener.getUserById(userId);

              if (user == null) {
                return const ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text('Đang tải...'),
                );
              }
              
              final avatarImage = user.avatar.isNotEmpty ? NetworkImage(user.avatar.first) : null;
// ... bên trong hàm itemBuilder ...
return Container(
  margin: const EdgeInsets.symmetric(vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.backgroundLight,
    borderRadius: BorderRadius.circular(12),
  ),
  child: ListTile(
    // BỌC TRONG HERO VỚI TAG DUY NHẤT
    leading: Hero(
      // Kết hợp userId và postId để đảm bảo tag là duy nhất
      tag: '${user.id}_${widget.postId}', 
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundImage: avatarImage,
            child: avatarImage == null ? const Icon(Icons.person) : null,
          ),
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle
              ),
              child: reaction_helper.getReactionIcon(reactionType)
            ),
          )
        ],
      ),
    ),
    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    onTap: () {
      // Bây giờ bạn có thể an toàn điều hướng đến profile
      // Ví dụ: Navigator.pushNamed(context, '/profile', arguments: user.id);
      // Trên trang profile, Hero widget của avatar cũng phải có tag là:
      // '${user.id}_${widget.postId}'
      // Hoặc nếu bạn điều hướng từ nhiều nơi, bạn cần truyền cả tag vào arguments
    },
  ),
);
            },
          );
        },
      ),
    );
  }
}