import 'package:flutter/material.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/viewmodel/follow_view_model.dart';

class FollowButton extends StatefulWidget {
  final String targetUserId; // ĐÂY LÀ DOCUMENT ID CỦA NGƯỜI MUỐN FOLLOW
  final FollowViewModel viewModel;

  const FollowButton({
    super.key,
    required this.targetUserId,
    required this.viewModel,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  @override
  void didUpdateWidget(covariant FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetUserId != widget.targetUserId) {
      _checkFollowStatus();
    }
  }

  Future<void> _checkFollowStatus() async {
    if (!mounted) return;
    // Reset loading khi check trạng thái mới
    setState(() => _isLoading = true);
    try {
      // ViewModel sẽ tự lo việc lấy ID người gọi (current user doc id)
      final isFollowing = await widget.viewModel.isFollowing(widget.targetUserId);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
             _isFollowing = false;
             _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() => _isFollowing = !_isFollowing);

    try {
      if (!_isFollowing) {
         await widget.viewModel.unfollowUser(widget.targetUserId);
      } else {
         await widget.viewModel.followUser(widget.targetUserId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowing = !_isFollowing);
        // Có thể thêm hiển thị lỗi nếu muốn
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleFollow,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _isFollowing ? Colors.grey.shade200 : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isFollowing ? Colors.grey.shade300 : AppColors.primary,
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _isFollowing ? Colors.black54 : Colors.white,
                ),
              )
            : Text(
                _isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isFollowing ? Colors.black87 : Colors.white,
                ),
              ),
      ),
    );
  }
}