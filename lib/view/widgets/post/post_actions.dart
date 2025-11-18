// lib/view/widgets/post/post_actions.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/view/widgets/comment_sheet.dart';
import 'package:mangxahoi/view/widgets/share_bottom_sheet.dart';
import 'package:mangxahoi/viewmodel/post_interaction_view_model.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/reactions.dart' as reaction_helper;

class PostActions extends StatelessWidget {
  final PostModel post;
  final String currentUserDocId;

  const PostActions({
    super.key,
    required this.post,
    required this.currentUserDocId,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PostInteractionViewModel>(context, listen: false);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Post')
          .doc(post.id)
          .collection('reactions')
          .doc(currentUserDocId)
          .snapshots(),
      builder: (context, snapshot) {
        final String? currentReactionType = (snapshot.hasData && snapshot.data!.exists)
            ? (snapshot.data!.data() as Map<String, dynamic>)['type']
            : null;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _CustomReactionButton(
                currentReaction: currentReactionType,
                onReactionSelected: (reactionType) {
                  viewModel.handleReaction(currentUserDocId, reactionType);
                },
              ),
            ),
            _buildActionButton(
              icon: Icons.comment_outlined,
              label: 'Bình luận',
              color: AppColors.textSecondary,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommentSheet(
                    postId: post.id,
                    currentUserDocId: currentUserDocId,
                  ),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.share_outlined,
              label: 'Chia sẻ',
              color: AppColors.textSecondary,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => ShareBottomSheet(
                    post: post,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
        label: Text(
          label,
          style: TextStyle(color: color, fontSize: 13),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// ==================== CUSTOM REACTION BUTTON ====================

class _CustomReactionButton extends StatefulWidget {
  final String? currentReaction;
  final Function(String) onReactionSelected;

  const _CustomReactionButton({
    this.currentReaction,
    required this.onReactionSelected,
  });

  @override
  State<_CustomReactionButton> createState() => _CustomReactionButtonState();
}

class _CustomReactionButtonState extends State<_CustomReactionButton> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

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
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (widget.currentReaction != null) {
            widget.onReactionSelected(widget.currentReaction!);
          } else {
            _showReactionBox();
          }
        },
        onLongPress: _showReactionBox,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              reaction_helper.getReactionIcon(widget.currentReaction),
              const SizedBox(width: 8),
              reaction_helper.getReactionText(widget.currentReaction),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideReactionBox();
    super.dispose();
  }
}

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
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
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
                color: Colors.black.withOpacity(0.15),
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
                  margin: EdgeInsets.symmetric(
                    horizontal: isHovered ? 6 : 4,
                  ),
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
                            color: isHovered
                                ? reaction['color'].withOpacity(0.1)
                                : Colors.transparent,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
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