// lib/view/widgets/post/post_stats.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/view/widgets/comment_sheet.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/view/widgets/post/like_list_view.dart'; 
import 'package:mangxahoi/constant/reactions.dart' as reaction_helper;

class PostStats extends StatelessWidget {
  final String postId;

  const PostStats({super.key, required this.postId});

  void _openCommentSheet(BuildContext context) {
    final currentUserDocId = context.read<UserService>().currentUser?.id;
    if (currentUserDocId != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CommentSheet(
          postId: postId,
          currentUserDocId: currentUserDocId,
        ),
      );
    }
  }

  void _openLikeList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LikeListView(postId: postId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Post')
          .doc(postId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const SizedBox(height: 8);
        }

        final postData = snapshot.data!.data() as Map<String, dynamic>?;

        final reactionsMap =
            Map<String, int>.from(postData?['reactionsCount'] ?? {});
        final comments = postData?['commentsCount'] as int? ?? 0;

        int totalReactions = 0;
        reactionsMap.forEach((key, value) {
          totalReactions += value;
        });

        final topReactions = reactionsMap.entries.toList()
          ..removeWhere((e) => e.value == 0)
          ..sort((a, b) => b.value.compareTo(a.value));

        if (totalReactions == 0 && comments == 0) {
          return const SizedBox(height: 8);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (totalReactions > 0)
                GestureDetector(
                  onTap: () => _openLikeList(context),
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Stack(
                          children: List.generate(
                            topReactions.length.clamp(0, 3),
                            (index) {
                              final reactionType = topReactions[index].key;
                              return Padding(
                                padding: EdgeInsets.only(
                                    left: (index * 14).toDouble()),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: reaction_helper.getReactionIcon(reactionType),
                                ),
                              );
                            },
                          ).reversed.toList(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalReactions',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (totalReactions == 0 && comments > 0) const Spacer(),
              if (comments > 0)
                GestureDetector(
                  onTap: () => _openCommentSheet(context),
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '$comments bình luận',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}