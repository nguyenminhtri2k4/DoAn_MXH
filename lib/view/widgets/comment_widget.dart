
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/model/model_comment.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/request/comment_reaction_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/constant/reactions.dart' as reaction_helper;
import 'package:mangxahoi/request/comment_request.dart';
import 'package:mangxahoi/request/report_request.dart';
import 'package:mangxahoi/model/model_report.dart';
import 'package:mangxahoi/notification/notification_service.dart';

class CommentWidget extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onReply;
  final bool isReply;
  final String currentUserDocId;
  final String? postAuthorId;
  final VoidCallback? onDeleted;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.onReply,
    required this.currentUserDocId,
    this.isReply = false,
    this.postAuthorId,
    this.onDeleted,
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
                Navigator.pushNamed(
                  context,
                  '/profile',
                  arguments: comment.authorId,
                );
              }
            },
            child: CircleAvatar(
              radius: isReply ? 16 : 20,
              backgroundImage:
                  (author?.avatar.isNotEmpty ?? false)
                      ? NetworkImage(author!.avatar.first)
                      : null,
              child:
                  (author?.avatar.isEmpty ?? true)
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              author?.name ?? 'Người dùng',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showCommentOptions(context),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.more_horiz,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comment.content,
                        style: const TextStyle(fontSize: 14),
                      ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
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

  void _showCommentOptions(BuildContext context) {
  final bool isPostAuthor = currentUserDocId == postAuthorId;
  final bool isCommentAuthor = currentUserDocId == comment.authorId;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút xóa (chỉ hiện nếu là chủ bài viết hoặc chủ comment)
                  //if (isPostAuthor || isCommentAuthor)
                    // _buildOptionTile(
                    //   icon: Icons.delete_outline,
                    //   label: 'Xóa bình luận',
                    //   iconColor: Colors.red,
                    //   textColor: Colors.red,
                    //   onTap: () {
                    //     Navigator.pop(context);
                    //     _deleteComment(context);
                    //   },
                    // ),
                  if (isPostAuthor || isCommentAuthor)
                    const SizedBox(height: 12),
                  // Nút báo cáo (chỉ hiện nếu không phải chủ comment)
                  if (!isCommentAuthor)
                    _buildOptionTile(
                      icon: Icons.report_outlined,
                      label: 'Báo cáo bình luận',
                      iconColor: Colors.orange,
                      textColor: Colors.black87,
                      onTap: () {
                        Navigator.pop(context);
                        _showReportDialog(context);
                      },
                    ),
                  if (!isCommentAuthor)
                    const SizedBox(height: 12),
                  // Nút hủy
                  _buildOptionTile(
                    icon: Icons.close_rounded,
                    label: 'Hủy',
                    iconColor: Colors.grey[600]!,
                    textColor: Colors.grey[700]!,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

Widget _buildOptionTile({
  required IconData icon,
  required String label,
  required Color iconColor,
  required Color textColor,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey[400],
          ),
        ],
      ),
    ),
  );
}

  void _deleteComment(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              'Xóa bình luận?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Content
            Text(
              'Bình luận này sẽ bị xóa vĩnh viễn. Bạn không thể hoàn tác hành động này.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Xóa',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirmed == true && context.mounted) {
    try {
      await CommentRequest().deleteComment(comment.postId, comment.id);
      if (context.mounted) {
        NotificationService().showSuccessSnackBar(
          context,
          'Đã xóa bình luận',
        );
        onDeleted?.call();
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService().showErrorDialog(
          context: context,
          title: 'Lỗi',
          message: 'Không thể xóa bình luận: $e',
        );
      }
    }
  }
}

  void _showReportDialog(BuildContext context) {
  String? selectedReason;
  final additionalInfoController = TextEditingController();
  bool isReporting = false;

  // Danh sách lý do báo cáo
  final List<Map<String, dynamic>> reportReasons = [
    {
      'value': 'Vi phạm tiêu chuẩn cộng đồng',
      'icon': Icons.gavel_outlined,
      'color': Colors.red,
    },
    {
      'value': 'Bạo lực hoặc nguy hiểm',
      'icon': Icons.warning_amber_outlined,
      'color': Colors.orange,
    },
    {
      'value': 'Nội dung khiêu dâm',
      'icon': Icons.remove_red_eye_outlined,
      'color': Colors.pink,
    },
    {
      'value': 'Thông tin sai lệch',
      'icon': Icons.info_outline,
      'color': Colors.blue,
    },
    {
      'value': 'Spam hoặc lừa đảo',
      'icon': Icons.report_gmailerrorred_outlined,
      'color': Colors.deepOrange,
    },
    {
      'value': 'Quấy rối hoặc bắt nạt',
      'icon': Icons.person_off_outlined,
      'color': Colors.purple,
    },
    {
      'value': 'Nội dung xúc phạm',
      'icon': Icons.sentiment_very_dissatisfied_outlined,
      'color': Colors.redAccent,
    },
    {'value': 'Khác', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (BuildContext bottomSheetContext) {
      return StatefulBuilder(
        builder: (context, setBottomSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Drag handle
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Title
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, size: 28),
                                onPressed:
                                    isReporting
                                        ? null
                                        : () =>
                                            Navigator.pop(bottomSheetContext),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Báo cáo bình luận',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Tiêu đề phần chọn lý do
                          const Text(
                            'Chọn lý do báo cáo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Danh sách lý do
                          ...reportReasons.map((reason) {
                            final isSelected =
                                selectedReason == reason['value'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? reason['color'].withOpacity(0.1)
                                        : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? reason['color']
                                          : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setBottomSheetState(() {
                                      selectedReason = reason['value'];
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          reason['icon'],
                                          color:
                                              isSelected
                                                  ? reason['color']
                                                  : Colors.grey[600],
                                          size: 24,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            reason['value'],
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                              color:
                                                  isSelected
                                                      ? reason['color']
                                                      : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: reason['color'],
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 20),

                          // Phần nhập thông tin bổ sung
                          const Text(
                            'Thông tin bổ sung (không bắt buộc)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: TextField(
                              controller: additionalInfoController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText:
                                    'Mô tả chi tiết vấn đề bạn gặp phải...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Nút gửi báo cáo
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  (isReporting || selectedReason == null)
                                      ? null
                                      : () async {
                                        setBottomSheetState(() {
                                          isReporting = true;
                                        });

                                        final additionalInfo =
                                            additionalInfoController.text
                                                .trim();
                                        final fullReason =
                                            additionalInfo.isEmpty
                                                ? selectedReason!
                                                : '$selectedReason - $additionalInfo';

                                        try {
                                          // Kiểm tra đã báo cáo chưa
                                          final reportRequest =
                                              ReportRequest();
                                          bool alreadyReported =
                                              await reportRequest
                                                  .hasUserAlreadyReported(
                                                    currentUserDocId,
                                                    comment.id,
                                                  );

                                          if (!context.mounted) return;

                                          if (alreadyReported) {
                                            Navigator.pop(bottomSheetContext);
                                            NotificationService()
                                                .showInfoDialog(
                                              context: context,
                                              title: 'Thông báo',
                                              message:
                                                  'Bạn đã báo cáo bình luận này rồi.',
                                            );
                                          } else {
                                            // Tạo báo cáo mới
                                            final newReport = ReportModel(
                                              id: '',
                                              reporterId: currentUserDocId,
                                              targetId: comment.id,
                                              targetAuthorId: comment.authorId,
                                              targetType: 'comment',
                                              reason: fullReason,
                                              createdAt: DateTime.now(),
                                              status: 'pending',
                                            );

                                            await reportRequest.createReport(
                                              newReport,
                                            );

                                            if (!context.mounted) return;

                                            Navigator.pop(bottomSheetContext);
                                            NotificationService()
                                                .showSuccessSnackBar(
                                              context,
                                              'Đã gửi báo cáo thành công! Chúng tôi sẽ xem xét trong thời gian sớm nhất.',
                                            );
                                          }
                                        } catch (e) {
                                          if (!context.mounted) return;

                                          Navigator.pop(bottomSheetContext);
                                          NotificationService()
                                              .showErrorDialog(
                                            context: context,
                                            title: 'Lỗi',
                                            message: 'Lỗi gửi báo cáo: $e',
                                          );
                                        } finally {
                                          if (context.mounted) {
                                            setBottomSheetState(() {
                                              isReporting = false;
                                            });
                                          }
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    selectedReason == null
                                        ? Colors.grey[300]
                                        : Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child:
                                  isReporting
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        selectedReason == null
                                            ? 'Vui lòng chọn lý do'
                                            : 'Gửi báo cáo',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Lưu ý
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Báo cáo của bạn sẽ được xem xét và xử lý theo quy định của cộng đồng.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    },
  );
}
}

/// Widget hiển thị số lượng reactions - inline trong Row
class _ReactionCountBubble extends StatelessWidget {
  final String postId;
  final String commentId;

  const _ReactionCountBubble({required this.postId, required this.commentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Post')
              .doc(postId)
              .collection('comments')
              .doc(commentId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final reactionsCount =
            data?['reactionsCount'] as Map<dynamic, dynamic>? ?? {};

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

  void _showReactionList(
    BuildContext context,
    String postId,
    String commentId,
  ) {
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
              stream:
                  FirebaseFirestore.instance
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            reactions.isEmpty
                                ? const Center(
                                  child: Text("Chưa có lượt thích nào"),
                                )
                                : ListView.builder(
                                  controller: scrollController,
                                  itemCount: reactions.length,
                                  itemBuilder: (context, index) {
                                    final reactionData =
                                        reactions[index].data()
                                            as Map<String, dynamic>;
                                    final reactionType =
                                        reactionData['type'] as String?;
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
        final String? currentReaction =
            (snapshot.hasData && snapshot.data!.exists)
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
  State<_CustomCommentReactionButton> createState() =>
      _CustomCommentReactionButtonState();
}

class _CustomCommentReactionButtonState
    extends State<_CustomCommentReactionButton> {
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
      builder:
          (context) => GestureDetector(
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
    {
      'type': reaction_helper.ReactionType.like,
      'asset': 'assets/reactions/like.png',
      'color': Colors.blue,
    },
    {
      'type': reaction_helper.ReactionType.love,
      'asset': 'assets/reactions/love.png',
      'color': Colors.red,
    },
    {
      'type': reaction_helper.ReactionType.haha,
      'asset': 'assets/reactions/haha.png',
      'color': Colors.orange,
    },
    {
      'type': reaction_helper.ReactionType.wow,
      'asset': 'assets/reactions/wow.png',
      'color': Colors.orange,
    },
    {
      'type': reaction_helper.ReactionType.sad,
      'asset': 'assets/reactions/sad.png',
      'color': Colors.orange,
    },
    {
      'type': reaction_helper.ReactionType.angry,
      'asset': 'assets/reactions/angry.png',
      'color': Colors.red,
    },
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
      final RenderBox? box =
          _reactionKeys[i].currentContext?.findRenderObject() as RenderBox?;
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
                        transform:
                            Matrix4.identity()
                              ..translate(0.0, isHovered ? -10.0 : 0.0)
                              ..scale(scale),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                isHovered
                                    ? reaction['color'].withValues(alpha: 0.1)
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
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: reaction_helper.getReactionIcon(reactionType),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/profile', arguments: userId);
      },
    );
  }
}
