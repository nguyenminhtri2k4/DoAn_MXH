import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/model/model_comment.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/request/comment_reaction_request.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/constant/reactions.dart' as reaction_helper;

class CommentWidget extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onReply;
  final bool isReply;
  final String currentUserDocId;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.onReply,
    required this.currentUserDocId,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final userListener = context.watch<FirestoreListener>();
    final author = userListener.getUserById(comment.authorId);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (comment.authorId.isNotEmpty) {
                Navigator.pushNamed(context, '/profile', arguments: comment.authorId);
              }
            },
            child: CircleAvatar(
              radius: isReply ? 16 : 20,
              backgroundImage: (author?.avatar.isNotEmpty ?? false)
                  ? NetworkImage(author!.avatar.first)
                  : null,
              child: (author?.avatar.isEmpty ?? true) 
                  ? Icon(Icons.person, size: isReply ? 16 : 20) 
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author?.name ?? 'Người dùng',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(comment.content, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Hàng nút chức năng
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                  child: Row(
                    children: [
                      // Nút Reaction
                      _CommentReactionButton(
                        postId: comment.postId,
                        commentId: comment.id,
                        currentUserDocId: currentUserDocId,
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Nút Trả lời
                      GestureDetector(
                        onTap: onReply,
                        child: Text(
                          'Trả lời',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Thời gian
                      Text(
                        _formatTime(comment.createdAt),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      
                      const Spacer(),
                      
                      // Reaction count ở cuối
                      _ReactionCountBubble(
                        postId: comment.postId,
                        commentId: comment.id,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

/// Widget hiển thị số lượng reactions - inline trong Row
class _ReactionCountBubble extends StatelessWidget {
  final String postId;
  final String commentId;

  const _ReactionCountBubble({
    required this.postId,
    required this.commentId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Post')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final reactionsCount = data?['reactionsCount'] as Map<dynamic, dynamic>? ?? {};
        
        int totalCount = 0;
        String topReactionType = 'like';
        int maxCount = 0;

        reactionsCount.forEach((key, value) {
          if (value is int) {
            totalCount += value;
            if (value > maxCount) {
              maxCount = value;
              topReactionType = key.toString();
            }
          }
        });

        if (totalCount == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => _showReactionList(context, postId, commentId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                reaction_helper.getReactionIcon(topReactionType),
                const SizedBox(width: 4),
                Text(
                  '$totalCount',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReactionList(BuildContext context, String postId, String commentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Post')
                  .doc(postId)
                  .collection('comments')
                  .doc(commentId)
                  .collection('reactions')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reactions = snapshot.data?.docs ?? [];

                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Text(
                        'Người đã bày tỏ cảm xúc',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: reactions.isEmpty
                            ? const Center(child: Text("Chưa có lượt thích nào"))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: reactions.length,
                                itemBuilder: (context, index) {
                                  final reactionData = reactions[index].data() as Map<String, dynamic>;
                                  final reactionType = reactionData['type'] as String?;
                                  final userId = reactions[index].id;
                                  
                                  return _UserReactionTile(
                                    userId: userId,
                                    reactionType: reactionType ?? 'like',
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Nút reaction cho comment
class _CommentReactionButton extends StatelessWidget {
  final String postId;
  final String commentId;
  final String currentUserDocId;

  const _CommentReactionButton({
    required this.postId,
    required this.commentId,
    required this.currentUserDocId,
  });

  @override
  Widget build(BuildContext context) {
    final reactionRequest = CommentReactionRequest();

    return StreamBuilder<DocumentSnapshot>(
      stream: reactionRequest.getUserReactionStream(
        postId,
        commentId,
        currentUserDocId,
      ),
      builder: (context, snapshot) {
        final String? currentReaction = (snapshot.hasData && snapshot.data!.exists)
            ? (snapshot.data!.data() as Map<String, dynamic>)['type']
            : null;

        return _CustomCommentReactionButton(
          currentReaction: currentReaction,
          onReactionSelected: (reactionType) {
            if (currentReaction == reactionType) {
              reactionRequest.removeReaction(
                postId,
                commentId,
                currentUserDocId,
                reactionType,
              );
            } else {
              reactionRequest.setReaction(
                postId,
                commentId,
                currentUserDocId,
                reactionType,
                currentReaction,
              );
            }
          },
        );
      },
    );
  }
}

/// Custom reaction button UI
class _CustomCommentReactionButton extends StatefulWidget {
  final String? currentReaction;
  final Function(String) onReactionSelected;

  const _CustomCommentReactionButton({
    this.currentReaction,
    required this.onReactionSelected,
  });

  @override
  State<_CustomCommentReactionButton> createState() => _CustomCommentReactionButtonState();
}

class _CustomCommentReactionButtonState extends State<_CustomCommentReactionButton> {
  OverlayEntry? _overlayEntry;

  void _showReactionBox() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideReactionBox() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideReactionBox,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy - 70,
              child: Material(
                color: Colors.transparent,
                child: _ReactionBoxWidget(
                  onReactionSelected: (reaction) {
                    widget.onReactionSelected(reaction);
                    _hideReactionBox();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.currentReaction != null) {
          widget.onReactionSelected(widget.currentReaction!);
        } else {
          _showReactionBox();
        }
      },
      onLongPress: _showReactionBox,
      child: Row(
        children: [
          reaction_helper.getReactionIcon(widget.currentReaction),
          const SizedBox(width: 4),
          reaction_helper.getReactionText(widget.currentReaction),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hideReactionBox();
    super.dispose();
  }
}

/// Reaction box widget
class _ReactionBoxWidget extends StatefulWidget {
  final Function(String) onReactionSelected;

  const _ReactionBoxWidget({required this.onReactionSelected});

  @override
  State<_ReactionBoxWidget> createState() => _ReactionBoxWidgetState();
}

class _ReactionBoxWidgetState extends State<_ReactionBoxWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int? _hoveredIndex;
  final List<GlobalKey> _reactionKeys = List.generate(6, (_) => GlobalKey());

  final List<Map<String, dynamic>> _reactions = [
    {'type': reaction_helper.ReactionType.like, 'asset': 'assets/reactions/like.png', 'color': Colors.blue},
    {'type': reaction_helper.ReactionType.love, 'asset': 'assets/reactions/love.png', 'color': Colors.red},
    {'type': reaction_helper.ReactionType.haha, 'asset': 'assets/reactions/haha.png', 'color': Colors.orange},
    {'type': reaction_helper.ReactionType.wow, 'asset': 'assets/reactions/wow.png', 'color': Colors.orange},
    {'type': reaction_helper.ReactionType.sad, 'asset': 'assets/reactions/sad.png', 'color': Colors.orange},
    {'type': reaction_helper.ReactionType.angry, 'asset': 'assets/reactions/angry.png', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    for (int i = 0; i < _reactionKeys.length; i++) {
      final RenderBox? box = _reactionKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final position = box.localToGlobal(Offset.zero);
        final size = box.size;
        
        if (details.globalPosition.dx >= position.dx &&
            details.globalPosition.dx <= position.dx + size.width &&
            details.globalPosition.dy >= position.dy &&
            details.globalPosition.dy <= position.dy + size.height) {
          if (_hoveredIndex != i) {
            setState(() => _hoveredIndex = i);
          }
          return;
        }
      }
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_hoveredIndex != null) {
      widget.onReactionSelected(_reactions[_hoveredIndex!]['type']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_reactions.length, (index) {
              final reaction = _reactions[index];
              final isHovered = _hoveredIndex == index;
              final scale = isHovered ? 1.5 : 1.0;

              return GestureDetector(
                key: _reactionKeys[index],
                onTap: () => widget.onReactionSelected(reaction['type']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.symmetric(horizontal: isHovered ? 6 : 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                        transform: Matrix4.identity()
                          ..translate(0.0, isHovered ? -10.0 : 0.0)
                          ..scale(scale),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isHovered ? reaction['color'].withValues(alpha: 0.1) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            reaction['asset'],
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                      if (isHovered) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reaction_helper.getReactionLabel(reaction['type']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// User reaction tile
class _UserReactionTile extends StatelessWidget {
  final String userId;
  final String reactionType;

  const _UserReactionTile({required this.userId, required this.reactionType});

  @override
  Widget build(BuildContext context) {
    final userListener = context.watch<FirestoreListener>();
    final user = userListener.getUserById(userId);

    if (user == null) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        leading: const CircleAvatar(child: SizedBox.shrink()),
        title: const Text('Đang tải...'),
      );
    }

    final hasAvatar = user.avatar.isNotEmpty;
    final avatarUrl = hasAvatar ? user.avatar.first : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: CircleAvatar(
        backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
        child: !hasAvatar ? const Icon(Icons.person) : null,
      ),
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: reaction_helper.getReactionIcon(reactionType),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/profile', arguments: userId);
      },
    );
  }
}