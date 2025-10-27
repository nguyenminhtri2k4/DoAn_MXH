
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/viewmodel/post_interaction_view_model.dart';
import 'package:mangxahoi/request/post_request.dart';
import 'package:mangxahoi/request/report_request.dart';
import 'package:mangxahoi/model/model_report.dart';
import 'package:mangxahoi/view/post/edit_post_view.dart';
import 'package:intl/intl.dart'; // <<< THÊM IMPORT NÀY

// Import các widget con
import 'post/post_header.dart';
import 'post/post_content.dart';
import 'post/post_media.dart';
import 'post/post_stats.dart';
import 'post/post_actions.dart';
import 'post/original_post_display.dart';

// --- Widget PostWidget (Chính) ---
class PostWidget extends StatefulWidget {
  final PostModel post;
  final String currentUserDocId;

  const PostWidget({
    super.key,
    required this.post,
    required this.currentUserDocId,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late PostModel _currentPost;
  final ReportRequest _reportRequest = ReportRequest();
  bool _isReporting = false;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }

  @override
  void didUpdateWidget(covariant PostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post != oldWidget.post) {
      setState(() {
        _currentPost = widget.post;
      });
    }
  }

  // --- Các hàm Helpers ---
  String _formatTimestamp(DateTime postTime) {
    final now = DateTime.now();
    final difference = now.difference(postTime);

    if (difference.inDays >= 7) {
       final formatter = DateFormat('dd/MM/yyyy'); // Sử dụng DateFormat
       return formatter.format(postTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  IconData _getVisibilityIcon(String visibility) {
    switch (visibility) {
      case 'private': return Icons.lock;
      case 'friends': return Icons.group;
      default: return Icons.public;
    }
  }

  String _getVisibilityText(String visibility) {
    switch (visibility) {
      case 'private': return 'Chỉ mình tôi';
      case 'friends': return 'Bạn bè';
      default: return 'Công khai';
    }
  }

  // --- Hàm Build Chính ---
  @override
  Widget build(BuildContext context) {
    final listener = context.watch<FirestoreListener>();
    final author = listener.getUserById(_currentPost.authorId);
    final isSharedPost = _currentPost.originalPostId != null &&
        _currentPost.originalPostId!.isNotEmpty;

    if (_currentPost.status == 'deleted') {
      return const SizedBox.shrink();
    }

    return ChangeNotifierProvider(
      key: ValueKey(_currentPost.id),
      create: (_) => PostInteractionViewModel(_currentPost.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        decoration: BoxDecoration(
          color: Colors.white,
           border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 10.0, 8.0, 0),
              child: PostHeader(
                post: _currentPost,
                author: author,
                currentUserDocId: widget.currentUserDocId,
                onShowOwnerOptions: () => _showOwnerPostOptions(context),
                onShowGuestOptions: () => _showGuestPostOptions(context),
                onShowPrivacyPicker: () => _showPrivacyPicker(context),
                formatTimestamp: _formatTimestamp,
                getVisibilityIcon: _getVisibilityIcon,
                getVisibilityText: _getVisibilityText,
              ),
            ),
             // --- Content (nếu có) ---
             if (_currentPost.content.isNotEmpty)
               Padding(
                 padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 0),
                 child: PostContent(content: _currentPost.content),
               ),
            const SizedBox(height: 10),

            // --- Original Post (nếu là bài share) ---
            if (isSharedPost)
              OriginalPostDisplay(
                originalPostId: _currentPost.originalPostId!,
                currentUserDocId: widget.currentUserDocId,
                formatTimestamp: _formatTimestamp,
              ),

            // --- Media (nếu không phải bài share và có media) ---
            if (!isSharedPost && _currentPost.mediaIds.isNotEmpty)
              // <<< SỬA LỖI PADDING Ở ĐÂY >>>
              Padding(
                 padding: EdgeInsets.zero, // Hoặc EdgeInsets.symmetric(horizontal: 0) nếu cần
                 child: PostMedia(mediaIds: _currentPost.mediaIds),
              ),
              // <<< KẾT THÚC SỬA LỖI PADDING >>>

            // --- Stats ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: PostStats(postId: _currentPost.id),
            ),

            // --- Actions ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Builder(builder: (innerContext) {
                return PostActions(
                  post: _currentPost,
                  currentUserDocId: widget.currentUserDocId,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }


  // --- CÁC HÀM SHOW MODAL/DIALOG (Giữ nguyên không đổi) ---
  // (Giữ các hàm _showOwnerPostOptions, _showDeleteConfirmationDialog,
  //  _showGuestPostOptions, _showReportDialog, _showPrivacyPicker, _updatePrivacy ở đây)

    // --- Menu cho chủ bài viết ---
  void _showOwnerPostOptions(BuildContext context) {
     showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) { // Đổi tên context để tránh trùng lặp
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo nhỏ ở trên
              Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 20),
              // Nút Chỉnh sửa
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.black87),
                title: const Text('Chỉnh sửa bài viết'),
                onTap: () async {
                  Navigator.pop(ctx); // Đóng bottom sheet
                  final result = await Navigator.push(
                    context, // Dùng context gốc của PostWidget
                    MaterialPageRoute(
                      builder: (context) => EditPostView(post: _currentPost),
                    ),
                  );
                   // Cập nhật lại _currentPost nếu có chỉnh sửa thành công
                  if (result is PostModel && mounted) {
                     setState(() {
                       _currentPost = result;
                     });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bài viết đã được cập nhật')),
                    );
                   // Không cần reload toàn bộ list, chỉ cần cập nhật state ở đây
                  } else if (result == true && mounted) { // Trường hợp Edit trả về bool cũ
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bài viết đã được cập nhật (cần làm mới)')),
                    );
                  }
                },
              ),
              // Nút Xóa
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa bài viết', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx); // Đóng bottom sheet
                  _showDeleteConfirmationDialog(context); // Gọi dialog xác nhận
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

   // --- Dialog xác nhận xóa ---
   void _showDeleteConfirmationDialog(BuildContext context) {
     showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Đóng dialog
                try {
                  await PostRequest().deletePostSoft(_currentPost.id);
                  if (mounted) {
                      // Không cần setState vì StreamBuilder sẽ tự cập nhật status
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Đã xóa bài viết')),
                     );
                  }
                } catch (e) {
                   if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Lỗi khi xóa bài viết: $e')),
                     );
                   }
                }
              },
            ),
          ],
        );
      },
    );
   }

  // --- Menu cho người xem ---
  void _showGuestPostOptions(BuildContext context) {
     showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.report_outlined, color: Colors.orange),
                title: const Text('Báo cáo bài viết'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportDialog(context);
                },
              ),
              // Thêm các tùy chọn khác nếu cần (Chặn, Ẩn, ...)
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // --- Dialog báo cáo ---
  void _showReportDialog(BuildContext context) {
    final reportController = TextEditingController();
    final reportFormKey = GlobalKey<FormState>();

     showDialog(
      context: context,
      barrierDismissible: !_isReporting,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Để cập nhật trạng thái loading
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Báo cáo bài viết'),
              content: Form(
                key: reportFormKey,
                child: TextFormField(
                  controller: reportController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập lý do báo cáo...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập lý do báo cáo.';
                    }
                    return null;
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: _isReporting ? null : () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: _isReporting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Gửi báo cáo'),
                  onPressed: _isReporting ? null : () async {
                    if (reportFormKey.currentState!.validate()) {
                      setDialogState(() => _isReporting = true);
                      final reason = reportController.text.trim();
                      final reporterId = widget.currentUserDocId;
                      final reportedPostId = _currentPost.id;
                      final postAuthorId = _currentPost.authorId;

                      try {
                        bool alreadyReported = await _reportRequest.hasUserAlreadyReported(reporterId, reportedPostId);
                        if (!mounted) return;

                        if (alreadyReported) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bạn đã báo cáo bài viết này rồi.')),
                          );
                        } else {
                          final newReport = ReportModel(
                            id: '', reporterId: reporterId, targetId: reportedPostId,
                            targetAuthorId: postAuthorId, targetType: 'post',
                            reason: reason, createdAt: DateTime.now(), status: 'pending',
                          );
                          await _reportRequest.createReport(newReport);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã gửi báo cáo thành công!')),
                          );
                        }
                        Navigator.of(dialogContext).pop(); // Đóng dialog
                      } catch (e) {
                         if (!mounted) return;
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Lỗi gửi báo cáo: $e')),
                         );
                      } finally {
                         // Luôn reset state dù thành công hay lỗi
                        // Kiểm tra mounted lần nữa trước khi gọi setDialogState
                        if (mounted) {
                           setDialogState(() => _isReporting = false);
                        }
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      // Đảm bảo reset state nếu dialog bị đóng bất thường
      if (mounted && _isReporting) {
        setState(() => _isReporting = false);
      }
    });
  }

  // --- Modal chọn quyền riêng tư ---
  void _showPrivacyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Hàm helper nội bộ để tạo ListTile chọn privacy
        Widget buildPrivacyOption({ required String value, required IconData icon, required String title, required String subtitle }) {
          final bool isSelected = _currentPost.visibility == value;
          return ListTile(
            onTap: () {
              Navigator.pop(ctx); // Đóng bottom sheet trước
              _updatePrivacy(context, value); // Gọi hàm cập nhật
            },
            leading: Icon(icon, color: Colors.grey[700]),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue /* Hoặc AppColors.primary */) : null,
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ai có thể xem bài viết này?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              buildPrivacyOption(value: 'public', icon: Icons.public, title: 'Công khai', subtitle: 'Bất kỳ ai ở trong hoặc ngoài mạng xã hội.'),
              const Divider(height: 1, indent: 56), // Indent bằng chiều rộng leading + padding
              buildPrivacyOption(value: 'friends', icon: Icons.group, title: 'Bạn bè', subtitle: 'Chỉ bạn bè của bạn có thể xem.'),
              const Divider(height: 1, indent: 56),
              buildPrivacyOption(value: 'private', icon: Icons.lock, title: 'Chỉ mình tôi', subtitle: 'Bài viết này sẽ không hiển thị với ai khác.'),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // --- Hàm cập nhật quyền riêng tư ---
  void _updatePrivacy(BuildContext context, String newVisibility) async { // Thêm async/await
    // Cập nhật state ngay lập tức để UI thay đổi
    setState(() {
      _currentPost = _currentPost.copyWith(visibility: newVisibility);
    });

    try {
      // Gọi request để cập nhật Firestore
      await PostRequest().updatePost(_currentPost.copyWith(updatedAt: DateTime.now()));
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã cập nhật quyền riêng tư thành: ${_getVisibilityText(newVisibility)}')),
         );
      }
    } catch (e) {
       if (mounted) {
         // Hoàn tác lại state nếu cập nhật thất bại
          setState(() {
            // Lấy lại visibility cũ từ widget.post (hoặc lưu state cũ trước khi cập nhật)
             _currentPost = _currentPost.copyWith(visibility: widget.post.visibility);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật quyền riêng tư: $e')),
         );
       }
    }
  }

} // Kết thúc _PostWidgetState