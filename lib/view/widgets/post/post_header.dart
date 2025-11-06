
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/request/follow_request.dart';

class PostHeader extends StatefulWidget {
  final PostModel post;
  final UserModel? author;
  final String currentUserDocId;
  final VoidCallback onShowOwnerOptions;
  final VoidCallback onShowGuestOptions;
  final VoidCallback onShowPrivacyPicker;
  final String Function(DateTime) formatTimestamp;
  final IconData Function(String) getVisibilityIcon;
  final String Function(String) getVisibilityText;

  const PostHeader({
    super.key,
    required this.post,
    required this.author,
    required this.currentUserDocId,
    required this.onShowOwnerOptions,
    required this.onShowGuestOptions,
    required this.onShowPrivacyPicker,
    required this.formatTimestamp,
    required this.getVisibilityIcon,
    required this.getVisibilityText,
  });

  @override
  State<PostHeader> createState() => _PostHeaderState();
}

class _PostHeaderState extends State<PostHeader> {
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  final FollowRequest _followRequest = FollowRequest();

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  @override
  void didUpdateWidget(covariant PostHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.author?.id != oldWidget.author?.id) {
      _checkFollowStatus();
    }
  }

  void _checkFollowStatus() async {
    if (widget.author == null || widget.currentUserDocId == widget.author!.id) return;
    try {
      final isFollowing = await _followRequest.isFollowing(widget.currentUserDocId, widget.author!.id);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      print('Lỗi kiểm tra follow: $e');
    }
  }

  void _handleFollowAction() async {
    if (widget.author == null) return;
    setState(() => _isLoadingFollow = true);
    try {
      if (_isFollowing) {
        await _followRequest.unfollowUser(widget.currentUserDocId, widget.author!.id);
      } else {
        await _followRequest.followUser(widget.currentUserDocId, widget.author!.id);
      }
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoadingFollow = false;
        });
      }
    } catch (e) {
      print('Lỗi follow/unfollow: $e');
      if (mounted) {
        setState(() => _isLoadingFollow = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.author == null) return const SizedBox.shrink();

    final listener = context.read<FirestoreListener>();
    final group = widget.post.groupId != null && widget.post.groupId!.isNotEmpty
        ? listener.getGroupById(widget.post.groupId!)
        : null;
    final isGroupPost = group != null;
    final isOwner = widget.currentUserDocId == widget.post.authorId;
    final String timestamp = widget.formatTimestamp(widget.post.createdAt);

    Widget avatarWidget;
    Widget titleWidget;
    Widget subtitleWidget;

    if (isGroupPost) {
      avatarWidget = GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/post_group', arguments: group),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.backgroundDark,
          child: Text(
            group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      );
      titleWidget = GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/post_group', arguments: group),
        child: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );
      subtitleWidget = RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          children: [
            TextSpan(
              text: widget.author!.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.pushNamed(context, '/profile', arguments: widget.author!.id),
            ),
            TextSpan(text: ' • $timestamp'),
          ],
        ),
      );
    } else {
      avatarWidget = GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/profile', arguments: widget.author!.id),
        child: CircleAvatar(
          radius: 20,
          backgroundImage: (widget.author!.avatar.isNotEmpty) ? NetworkImage(widget.author!.avatar.first) : null,
          child: (widget.author!.avatar.isEmpty) ? const Icon(Icons.person, size: 20) : null,
        ),
      );
      titleWidget = GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/profile', arguments: widget.author!.id),
        child: Text(widget.author!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );
      subtitleWidget = Text(timestamp, style: const TextStyle(color: Colors.grey, fontSize: 13));
    }

    return Row(
      children: [
        avatarWidget,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 2),
              subtitleWidget,
            ],
          ),
        ),
        if (isOwner) ...[
          _buildPrivacyButton(context),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: widget.onShowOwnerOptions,
          ),
        ] else ...[
          // Nếu không phải bài trong nhóm thì hiện nút Follow
          if (!isGroupPost) _buildFollowButton(),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: widget.onShowGuestOptions,
          ),
        ]
      ],
    );
  }

  Widget _buildFollowButton() {
    if (_isLoadingFollow) {
      return const Padding(
        padding: EdgeInsets.only(right: 8.0),
        child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return TextButton(
      onPressed: _handleFollowAction,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        _isFollowing ? 'Đang theo dõi' : 'Theo dõi',
        style: TextStyle(
          color: _isFollowing ? Colors.grey : AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPrivacyButton(BuildContext context) {
    return InkWell(
      onTap: widget.onShowPrivacyPicker,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.getVisibilityIcon(widget.post.visibility), size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              widget.getVisibilityText(widget.post.visibility),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}