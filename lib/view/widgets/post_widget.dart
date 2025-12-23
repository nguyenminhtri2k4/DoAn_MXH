
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:mangxahoi/model/model_post.dart';
// import 'package:mangxahoi/model/model_user.dart';
// import 'package:mangxahoi/authanet/firestore_listener.dart';
// import 'package:mangxahoi/viewmodel/post_interaction_view_model.dart';
// import 'package:mangxahoi/request/post_request.dart';
// import 'package:mangxahoi/request/report_request.dart';
// import 'package:mangxahoi/model/model_report.dart';
// import 'package:mangxahoi/view/post/edit_post_view.dart';
// import 'package:intl/intl.dart'; // <<< THÊM IMPORT NÀY

// // Import các widget con
// import 'post/post_header.dart';
// import 'post/post_content.dart';
// import 'post/post_media.dart';
// import 'post/post_stats.dart';
// import 'post/post_actions.dart';
// import 'post/original_post_display.dart';

// // --- Widget PostWidget (Chính) ---
// class PostWidget extends StatefulWidget {
//   final PostModel post;
//   final String currentUserDocId;

//   const PostWidget({
//     super.key,
//     required this.post,
//     required this.currentUserDocId,
//   });

//   @override
//   State<PostWidget> createState() => _PostWidgetState();
// }

// class _PostWidgetState extends State<PostWidget> {
//   late PostModel _currentPost;
//   final ReportRequest _reportRequest = ReportRequest();
//   bool _isReporting = false;

//   @override
//   void initState() {
//     super.initState();
//     _currentPost = widget.post;
//   }

//   @override
//   void didUpdateWidget(covariant PostWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.post != oldWidget.post) {
//       setState(() {
//         _currentPost = widget.post;
//       });
//     }
//   }

//   // --- Các hàm Helpers ---
//   String _formatTimestamp(DateTime postTime) {
//     final now = DateTime.now();
//     final difference = now.difference(postTime);

//     if (difference.inDays >= 7) {
//        final formatter = DateFormat('dd/MM/yyyy'); // Sử dụng DateFormat
//        return formatter.format(postTime);
//     } else if (difference.inDays > 0) {
//       return '${difference.inDays} ngày trước';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours} giờ trước';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes} phút trước';
//     } else {
//       return 'Vừa xong';
//     }
//   }

//   IconData _getVisibilityIcon(String visibility) {
//     switch (visibility) {
//       case 'private': return Icons.lock;
//       case 'friends': return Icons.group;
//       default: return Icons.public;
//     }
//   }

//   String _getVisibilityText(String visibility) {
//     switch (visibility) {
//       case 'private': return 'Chỉ mình tôi';
//       case 'friends': return 'Bạn bè';
//       default: return 'Công khai';
//     }
//   }

//   // --- Hàm Build Chính ---
//   @override
//   Widget build(BuildContext context) {
//     final listener = context.watch<FirestoreListener>();
//     final author = listener.getUserById(_currentPost.authorId);
//     final isSharedPost = _currentPost.originalPostId != null &&
//         _currentPost.originalPostId!.isNotEmpty;

//     if (_currentPost.status == 'deleted') {
//       return const SizedBox.shrink();
//     }

//     return ChangeNotifierProvider(
//       key: ValueKey(_currentPost.id),
//       create: (_) => PostInteractionViewModel(_currentPost.id),
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 5.0),
//         decoration: BoxDecoration(
//           color: Colors.white,
//            border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5))
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // --- Header ---
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12.0, 10.0, 8.0, 0),
//               child: PostHeader(
//                 post: _currentPost,
//                 author: author,
//                 currentUserDocId: widget.currentUserDocId,
//                 onShowOwnerOptions: () => _showOwnerPostOptions(context),
//                 onShowGuestOptions: () => _showGuestPostOptions(context),
//                 onShowPrivacyPicker: () => _showPrivacyPicker(context),
//                 formatTimestamp: _formatTimestamp,
//                 getVisibilityIcon: _getVisibilityIcon,
//                 getVisibilityText: _getVisibilityText,
//               ),
//             ),
//              // --- Content (nếu có) ---
//              if (_currentPost.content.isNotEmpty)
//                Padding(
//                  padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 0),
//                  child: PostContent(content: _currentPost.content),
//                ),
//             const SizedBox(height: 10),

//             // --- Original Post (nếu là bài share) ---
//             if (isSharedPost)
//               OriginalPostDisplay(
//                 originalPostId: _currentPost.originalPostId!,
//                 currentUserDocId: widget.currentUserDocId,
//                 formatTimestamp: _formatTimestamp,
//               ),

//             // --- Media (nếu không phải bài share và có media) ---
//             if (!isSharedPost && _currentPost.mediaIds.isNotEmpty)
//               // <<< SỬA LỖI PADDING Ở ĐÂY >>>
//               Padding(
//                  padding: EdgeInsets.zero, // Hoặc EdgeInsets.symmetric(horizontal: 0) nếu cần
//                  child: PostMedia(mediaIds: _currentPost.mediaIds),
//               ),
//               // <<< KẾT THÚC SỬA LỖI PADDING >>>

//             // --- Stats ---
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12.0),
//               child: PostStats(postId: _currentPost.id),
//             ),

//             // --- Actions ---
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 4.0),
//               child: Builder(builder: (innerContext) {
//                 return PostActions(
//                   post: _currentPost,
//                   currentUserDocId: widget.currentUserDocId,
//                 );
//               }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }


//   // --- CÁC HÀM SHOW MODAL/DIALOG (Giữ nguyên không đổi) ---
//   // (Giữ các hàm _showOwnerPostOptions, _showDeleteConfirmationDialog,
//   //  _showGuestPostOptions, _showReportDialog, _showPrivacyPicker, _updatePrivacy ở đây)

//     // --- Menu cho chủ bài viết ---
//   void _showOwnerPostOptions(BuildContext context) {
//      showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) { // Đổi tên context để tránh trùng lặp
//         return Container(
//           padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Thanh kéo nhỏ ở trên
//               Container(
//                 width: 40, height: 5,
//                 decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
//               ),
//               const SizedBox(height: 20),
//               // Nút Chỉnh sửa
//               ListTile(
//                 leading: const Icon(Icons.edit_outlined, color: Colors.black87),
//                 title: const Text('Chỉnh sửa bài viết'),
//                 onTap: () async {
//                   Navigator.pop(ctx); // Đóng bottom sheet
//                   final result = await Navigator.push(
//                     context, // Dùng context gốc của PostWidget
//                     MaterialPageRoute(
//                       builder: (context) => EditPostView(post: _currentPost),
//                     ),
//                   );
//                    // Cập nhật lại _currentPost nếu có chỉnh sửa thành công
//                   if (result is PostModel && mounted) {
//                      setState(() {
//                        _currentPost = result;
//                      });
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Bài viết đã được cập nhật')),
//                     );
//                    // Không cần reload toàn bộ list, chỉ cần cập nhật state ở đây
//                   } else if (result == true && mounted) { // Trường hợp Edit trả về bool cũ
//                      ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Bài viết đã được cập nhật (cần làm mới)')),
//                     );
//                   }
//                 },
//               ),
//               // Nút Xóa
//               ListTile(
//                 leading: const Icon(Icons.delete_outline, color: Colors.red),
//                 title: const Text('Xóa bài viết', style: TextStyle(color: Colors.red)),
//                 onTap: () async {
//                   Navigator.pop(ctx); // Đóng bottom sheet
//                   _showDeleteConfirmationDialog(context); // Gọi dialog xác nhận
//                 },
//               ),
//               const SizedBox(height: 10),
//             ],
//           ),
//         );
//       },
//     );
//   }

//    // Thay thế hàm _showDeleteConfirmationDialog trong PostWidget

// void _showDeleteConfirmationDialog(BuildContext context) {
//   bool isDeleting = false;

//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext dialogContext) {
//       return StatefulBuilder(
//         builder: (context, setDialogState) {
//           return Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             elevation: 0,
//             backgroundColor: Colors.transparent,
//             child: Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Icon cảnh báo
//                   Container(
//                     width: 70,
//                     height: 70,
//                     decoration: BoxDecoration(
//                       color: Colors.red.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.delete_forever_outlined,
//                       color: Colors.red,
//                       size: 40,
//                     ),
//                   ),
                  
//                   const SizedBox(height: 20),
                  
//                   // Tiêu đề
//                   const Text(
//                     'Xác nhận xóa bài viết',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
                  
//                   const SizedBox(height: 12),
                  
//                   // Nội dung
//                   Text(
//                     'Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.',
//                     style: TextStyle(
//                       fontSize: 15,
//                       color: Colors.grey[700],
//                       height: 1.4,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
                  
//                   const SizedBox(height: 28),
                  
//                   // Các nút hành động
//                   Row(
//                     children: [
//                       // Nút Hủy
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: isDeleting
//                               ? null
//                               : () => Navigator.of(dialogContext).pop(),
//                           style: OutlinedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             side: BorderSide(
//                               color: Colors.grey[300]!,
//                               width: 1.5,
//                             ),
//                           ),
//                           child: const Text(
//                             'Hủy',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ),
//                       ),
                      
//                       const SizedBox(width: 12),
                      
//                       // Nút Xóa
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: isDeleting
//                               ? null
//                               : () async {
//                                   setDialogState(() {
//                                     isDeleting = true;
//                                   });

//                                   try {
//                                     await PostRequest().deletePostSoft(_currentPost.id);
                                    
//                                     if (mounted) {
//                                       Navigator.of(dialogContext).pop();
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         SnackBar(
//                                           content: const Row(
//                                             children: [
//                                               Icon(
//                                                 Icons.check_circle_outline,
//                                                 color: Colors.white,
//                                               ),
//                                               SizedBox(width: 8),
//                                               Text('Đã xóa bài viết'),
//                                             ],
//                                           ),
//                                           backgroundColor: Colors.green,
//                                           behavior: SnackBarBehavior.floating,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(10),
//                                           ),
//                                           duration: const Duration(seconds: 2),
//                                         ),
//                                       );
//                                     }
//                                   } catch (e) {
//                                     if (mounted) {
//                                       Navigator.of(dialogContext).pop();
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         SnackBar(
//                                           content: Row(
//                                             children: [
//                                               const Icon(
//                                                 Icons.error_outline,
//                                                 color: Colors.white,
//                                               ),
//                                               const SizedBox(width: 8),
//                                               Expanded(
//                                                 child: Text('Lỗi khi xóa bài viết: $e'),
//                                               ),
//                                             ],
//                                           ),
//                                           backgroundColor: Colors.red,
//                                           behavior: SnackBarBehavior.floating,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(10),
//                                           ),
//                                           duration: const Duration(seconds: 3),
//                                         ),
//                                       );
//                                     }
//                                   } finally {
//                                     if (mounted) {
//                                       setDialogState(() {
//                                         isDeleting = false;
//                                       });
//                                     }
//                                   }
//                                 },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red,
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           child: isDeleting
//                               ? const SizedBox(
//                                   height: 20,
//                                   width: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     color: Colors.white,
//                                   ),
//                                 )
//                               : const Text(
//                                   'Xóa',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }

//   // --- Menu cho người xem ---
//   void _showGuestPostOptions(BuildContext context) {
//      showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) {
//         return Container(
//           padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//                Container(
//                 width: 40, height: 5,
//                 decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
//               ),
//               const SizedBox(height: 20),
//               ListTile(
//                 leading: const Icon(Icons.report_outlined, color: Colors.orange),
//                 title: const Text('Báo cáo bài viết'),
//                 onTap: () {
//                   Navigator.pop(ctx);
//                   _showReportDialog(context);
//                 },
//               ),
//               // Thêm các tùy chọn khác nếu cần (Chặn, Ẩn, ...)
//               const SizedBox(height: 10),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // --- Dialog báo cáo ---
//   // Thay thế hàm _showReportDialog trong PostWidget

// void _showReportDialog(BuildContext context) {
//   String? selectedReason;
//   final additionalInfoController = TextEditingController();
//   bool isReporting = false;

//   // Danh sách lý do báo cáo
//   final List<Map<String, dynamic>> reportReasons = [
//     {
//       'value': 'Vi phạm tiêu chuẩn cộng đồng',
//       'icon': Icons.gavel_outlined,
//       'color': Colors.red,
//     },
//     {
//       'value': 'Bạo lực hoặc nguy hiểm',
//       'icon': Icons.warning_amber_outlined,
//       'color': Colors.orange,
//     },
//     {
//       'value': 'Nội dung khiêu dâm',
//       'icon': Icons.remove_red_eye_outlined,
//       'color': Colors.pink,
//     },
//     {
//       'value': 'Thông tin sai lệch',
//       'icon': Icons.info_outline,
//       'color': Colors.blue,
//     },
//     {
//       'value': 'Spam hoặc lừa đảo',
//       'icon': Icons.report_gmailerrorred_outlined,
//       'color': Colors.deepOrange,
//     },
//     {
//       'value': 'Quấy rối hoặc bắt nạt',
//       'icon': Icons.person_off_outlined,
//       'color': Colors.purple,
//     },
//     {
//       'value': 'Nội dung xúc phạm',
//       'icon': Icons.sentiment_very_dissatisfied_outlined,
//       'color': Colors.redAccent,
//     },
//     {
//       'value': 'Khác',
//       'icon': Icons.more_horiz,
//       'color': Colors.grey,
//     },
//   ];

//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     isDismissible: true,
//     builder: (BuildContext bottomSheetContext) {
//       return StatefulBuilder(
//         builder: (context, setBottomSheetState) {
//           return Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             ),
//             padding: EdgeInsets.only(
//               bottom: MediaQuery.of(context).viewInsets.bottom,
//             ),
//             child: DraggableScrollableSheet(
//               initialChildSize: 0.75,
//               minChildSize: 0.5,
//               maxChildSize: 0.9,
//               expand: false,
//               builder: (context, scrollController) {
//                 return Column(
//                   children: [
//                     // Header
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: const BorderRadius.vertical(
//                           top: Radius.circular(20),
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 4,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         children: [
//                           // Drag handle
//                           Container(
//                             width: 40,
//                             height: 4,
//                             margin: const EdgeInsets.only(bottom: 12),
//                             decoration: BoxDecoration(
//                               color: Colors.grey[300],
//                               borderRadius: BorderRadius.circular(2),
//                             ),
//                           ),
//                           // Title
//                           Row(
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.close, size: 28),
//                                 onPressed: isReporting
//                                     ? null
//                                     : () => Navigator.pop(bottomSheetContext),
//                                 padding: EdgeInsets.zero,
//                                 constraints: const BoxConstraints(),
//                               ),
//                               const SizedBox(width: 12),
//                               const Expanded(
//                                 child: Text(
//                                   'Báo cáo bài viết',
//                                   style: TextStyle(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),

//                     const Divider(height: 1),

//                     // Content
//                     Expanded(
//                       child: ListView(
//                         controller: scrollController,
//                         padding: const EdgeInsets.all(16),
//                         children: [
//                           // Tiêu đề phần chọn lý do
//                           const Text(
//                             'Chọn lý do báo cáo',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 12),

//                           // Danh sách lý do
//                           ...reportReasons.map((reason) {
//                             final isSelected =
//                                 selectedReason == reason['value'];
//                             return Container(
//                               margin: const EdgeInsets.only(bottom: 8),
//                               decoration: BoxDecoration(
//                                 color: isSelected
//                                     ? reason['color']
//                                         .withOpacity(0.1)
//                                     : Colors.grey[50],
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: isSelected
//                                       ? reason['color']
//                                       : Colors.grey[300]!,
//                                   width: isSelected ? 2 : 1,
//                                 ),
//                               ),
//                               child: Material(
//                                 color: Colors.transparent,
//                                 child: InkWell(
//                                   onTap: () {
//                                     setBottomSheetState(() {
//                                       selectedReason = reason['value'];
//                                     });
//                                   },
//                                   borderRadius: BorderRadius.circular(12),
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 16,
//                                       vertical: 14,
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         Icon(
//                                           reason['icon'],
//                                           color: isSelected
//                                               ? reason['color']
//                                               : Colors.grey[600],
//                                           size: 24,
//                                         ),
//                                         const SizedBox(width: 16),
//                                         Expanded(
//                                           child: Text(
//                                             reason['value'],
//                                             style: TextStyle(
//                                               fontSize: 15,
//                                               fontWeight: isSelected
//                                                   ? FontWeight.w600
//                                                   : FontWeight.w500,
//                                               color: isSelected
//                                                   ? reason['color']
//                                                   : Colors.black87,
//                                             ),
//                                           ),
//                                         ),
//                                         if (isSelected)
//                                           Icon(
//                                             Icons.check_circle,
//                                             color: reason['color'],
//                                             size: 24,
//                                           ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           }).toList(),

//                           const SizedBox(height: 20),

//                           // Phần nhập thông tin bổ sung
//                           const Text(
//                             'Thông tin bổ sung (không bắt buộc)',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 12),

//                           Container(
//                             decoration: BoxDecoration(
//                               color: Colors.grey[50],
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: Colors.grey[300]!,
//                               ),
//                             ),
//                             child: TextField(
//                               controller: additionalInfoController,
//                               maxLines: 4,
//                               decoration: const InputDecoration(
//                                 hintText:
//                                     'Mô tả chi tiết vấn đề bạn gặp phải...',
//                                 hintStyle: TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 14,
//                                 ),
//                                 border: InputBorder.none,
//                                 contentPadding: EdgeInsets.all(16),
//                               ),
//                               style: const TextStyle(fontSize: 15),
//                             ),
//                           ),

//                           const SizedBox(height: 24),

//                           // Nút gửi báo cáo
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed: (isReporting || selectedReason == null)
//                                   ? null
//                                   : () async {
//                                       setBottomSheetState(() {
//                                         isReporting = true;
//                                       });

//                                       // Tạo nội dung báo cáo
//                                       final additionalInfo =
//                                           additionalInfoController.text.trim();
//                                       final fullReason = additionalInfo.isEmpty
//                                           ? selectedReason!
//                                           : '$selectedReason - $additionalInfo';

//                                       final reporterId =
//                                           widget.currentUserDocId;
//                                       final reportedPostId = _currentPost.id;
//                                       final postAuthorId =
//                                           _currentPost.authorId;

//                                       try {
//                                         // Kiểm tra đã báo cáo chưa
//                                         bool alreadyReported =
//                                             await _reportRequest
//                                                 .hasUserAlreadyReported(
//                                           reporterId,
//                                           reportedPostId,
//                                         );

//                                         if (!mounted) return;

//                                         if (alreadyReported) {
//                                           Navigator.pop(bottomSheetContext);
//                                           ScaffoldMessenger.of(context)
//                                               .showSnackBar(
//                                             const SnackBar(
//                                               content: Text(
//                                                   'Bạn đã báo cáo bài viết này rồi.'),
//                                               backgroundColor: Colors.orange,
//                                             ),
//                                           );
//                                         } else {
//                                           // Tạo báo cáo mới
//                                           final newReport = ReportModel(
//                                             id: '',
//                                             reporterId: reporterId,
//                                             targetId: reportedPostId,
//                                             targetAuthorId: postAuthorId,
//                                             targetType: 'post',
//                                             reason: fullReason,
//                                             createdAt: DateTime.now(),
//                                             status: 'pending',
//                                           );

//                                           await _reportRequest
//                                               .createReport(newReport);

//                                           if (!mounted) return;

//                                           Navigator.pop(bottomSheetContext);
//                                           ScaffoldMessenger.of(context)
//                                               .showSnackBar(
//                                             const SnackBar(
//                                               content: Text(
//                                                   'Đã gửi báo cáo thành công! Chúng tôi sẽ xem xét trong thời gian sớm nhất.'),
//                                               backgroundColor: Colors.green,
//                                               duration: Duration(seconds: 3),
//                                             ),
//                                           );
//                                         }
//                                       } catch (e) {
//                                         if (!mounted) return;

//                                         Navigator.pop(bottomSheetContext);
//                                         ScaffoldMessenger.of(context)
//                                             .showSnackBar(
//                                           SnackBar(
//                                             content: Text('Lỗi gửi báo cáo: $e'),
//                                             backgroundColor: Colors.red,
//                                           ),
//                                         );
//                                       } finally {
//                                         if (mounted) {
//                                           setBottomSheetState(() {
//                                             isReporting = false;
//                                           });
//                                         }
//                                       }
//                                     },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: selectedReason == null
//                                     ? Colors.grey[300]
//                                     : Colors.red,
//                                 foregroundColor: Colors.white,
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 16,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 elevation: 0,
//                               ),
//                               child: isReporting
//                                   ? const SizedBox(
//                                       height: 20,
//                                       width: 20,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         color: Colors.white,
//                                       ),
//                                     )
//                                   : Text(
//                                       selectedReason == null
//                                           ? 'Vui lòng chọn lý do'
//                                           : 'Gửi báo cáo',
//                                       style: const TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                             ),
//                           ),

//                           const SizedBox(height: 16),

//                           // Lưu ý
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.blue[50],
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Icon(
//                                   Icons.info_outline,
//                                   size: 20,
//                                   color: Colors.blue[700],
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     'Báo cáo của bạn sẽ được xem xét và xử lý theo quy định của cộng đồng.',
//                                     style: TextStyle(
//                                       fontSize: 13,
//                                       color: Colors.blue[900],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           );
//         },
//       );
//     },
//   );
// }

//   // --- Modal chọn quyền riêng tư ---
//   void _showPrivacyPicker(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) {
//         // Hàm helper nội bộ để tạo ListTile chọn privacy
//         Widget buildPrivacyOption({ required String value, required IconData icon, required String title, required String subtitle }) {
//           final bool isSelected = _currentPost.visibility == value;
//           return ListTile(
//             onTap: () {
//               Navigator.pop(ctx); // Đóng bottom sheet trước
//               _updatePrivacy(context, value); // Gọi hàm cập nhật
//             },
//             leading: Icon(icon, color: Colors.grey[700]),
//             title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
//             subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
//             trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue /* Hoặc AppColors.primary */) : null,
//           );
//         }

//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('Ai có thể xem bài viết này?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 16),
//               buildPrivacyOption(value: 'public', icon: Icons.public, title: 'Công khai', subtitle: 'Bất kỳ ai ở trong hoặc ngoài mạng xã hội.'),
//               const Divider(height: 1, indent: 56), // Indent bằng chiều rộng leading + padding
//               buildPrivacyOption(value: 'friends', icon: Icons.group, title: 'Bạn bè', subtitle: 'Chỉ bạn bè của bạn có thể xem.'),
//               const Divider(height: 1, indent: 56),
//               buildPrivacyOption(value: 'private', icon: Icons.lock, title: 'Chỉ mình tôi', subtitle: 'Bài viết này sẽ không hiển thị với ai khác.'),
//               const SizedBox(height: 10),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // --- Hàm cập nhật quyền riêng tư ---
//   void _updatePrivacy(BuildContext context, String newVisibility) async { // Thêm async/await
//     // Cập nhật state ngay lập tức để UI thay đổi
//     setState(() {
//       _currentPost = _currentPost.copyWith(visibility: newVisibility);
//     });

//     try {
//       // Gọi request để cập nhật Firestore
//       await PostRequest().updatePost(_currentPost.copyWith(updatedAt: DateTime.now()));
//       if (mounted) {
//          ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Đã cập nhật quyền riêng tư thành: ${_getVisibilityText(newVisibility)}')),
//          );
//       }
//     } catch (e) {
//        if (mounted) {
//          // Hoàn tác lại state nếu cập nhật thất bại
//           setState(() {
//             // Lấy lại visibility cũ từ widget.post (hoặc lưu state cũ trước khi cập nhật)
//              _currentPost = _currentPost.copyWith(visibility: widget.post.visibility);
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Lỗi cập nhật quyền riêng tư: $e')),
//          );
//        }
//     }
//   }

// } // Kết thúc _PostWidgetState
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
  final bool _isReporting = false;

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
      case 'private':
        return Icons.lock;
      case 'friends':
        return Icons.group;
      default:
        return Icons.public;
    }
  }

  String _getVisibilityText(String visibility) {
    switch (visibility) {
      case 'private':
        return 'Chỉ mình tôi';
      case 'friends':
        return 'Bạn bè';
      default:
        return 'Công khai';
    }
  }

  // --- Hàm Build Chính ---
  @override
  Widget build(BuildContext context) {
    final listener = context.watch<FirestoreListener>();
    final author = listener.getUserById(_currentPost.authorId);
    final isSharedPost =
        _currentPost.originalPostId != null &&
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
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
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
                padding:
                    EdgeInsets
                        .zero, // Hoặc EdgeInsets.symmetric(horizontal: 0) nếu cần
                child: PostMedia(mediaIds: _currentPost.mediaIds),
              ),
            // <<< KẾT THÚC SỬA LỖI PADDING >>>

            // --- Stats ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: PostStats(
                postId: _currentPost.id,
                postAuthorId: _currentPost.authorId,
              ),
            ),

            // --- Actions ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Builder(
                builder: (innerContext) {
                  return PostActions(
                    post: _currentPost,
                    currentUserDocId: widget.currentUserDocId,
                  );
                },
              ),
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
      builder: (ctx) {
        // Đổi tên context để tránh trùng lặp
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo nhỏ ở trên
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      const SnackBar(
                        content: Text('Bài viết đã được cập nhật'),
                      ),
                    );
                    // Không cần reload toàn bộ list, chỉ cần cập nhật state ở đây
                  } else if (result == true && mounted) {
                    // Trường hợp Edit trả về bool cũ
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bài viết đã được cập nhật (cần làm mới)',
                        ),
                      ),
                    );
                  }
                },
              ),
              // Nút Xóa
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Xóa bài viết',
                  style: TextStyle(color: Colors.red),
                ),
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

  // Thay thế hàm _showDeleteConfirmationDialog trong PostWidget

  void _showDeleteConfirmationDialog(BuildContext context) {
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon cảnh báo
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tiêu đề
                    const Text(
                      'Xác nhận xóa bài viết',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Nội dung
                    Text(
                      'Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 28),

                    // Các nút hành động
                    Row(
                      children: [
                        // Nút Hủy
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                isDeleting
                                    ? null
                                    : () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Nút Xóa
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                isDeleting
                                    ? null
                                    : () async {
                                      setDialogState(() {
                                        isDeleting = true;
                                      });

                                      try {
                                        await PostRequest().deletePostSoft(
                                          _currentPost.id,
                                        );

                                        if (mounted) {
                                          Navigator.of(dialogContext).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_outline,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Đã xóa bài viết'),
                                                ],
                                              ),
                                              backgroundColor: Colors.green,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          Navigator.of(dialogContext).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.error_outline,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Lỗi khi xóa bài viết: $e',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.red,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setDialogState(() {
                                            isDeleting = false;
                                          });
                                        }
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                isDeleting
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text(
                                      'Xóa',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.report_outlined,
                  color: Colors.orange,
                ),
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
  // Thay thế hàm _showReportDialog trong PostWidget

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
                                    'Báo cáo bài viết',
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

                                          // Tạo nội dung báo cáo
                                          final additionalInfo =
                                              additionalInfoController.text
                                                  .trim();
                                          final fullReason =
                                              additionalInfo.isEmpty
                                                  ? selectedReason!
                                                  : '$selectedReason - $additionalInfo';

                                          final reporterId =
                                              widget.currentUserDocId;
                                          final reportedPostId =
                                              _currentPost.id;
                                          final postAuthorId =
                                              _currentPost.authorId;

                                          try {
                                            // Kiểm tra đã báo cáo chưa
                                            bool alreadyReported =
                                                await _reportRequest
                                                    .hasUserAlreadyReported(
                                                      reporterId,
                                                      reportedPostId,
                                                    );

                                            if (!mounted) return;

                                            if (alreadyReported) {
                                              Navigator.pop(bottomSheetContext);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Bạn đã báo cáo bài viết này rồi.',
                                                  ),
                                                  backgroundColor:
                                                      Colors.orange,
                                                ),
                                              );
                                            } else {
                                              // Tạo báo cáo mới
                                              final newReport = ReportModel(
                                                id: '',
                                                reporterId: reporterId,
                                                targetId: reportedPostId,
                                                targetAuthorId: postAuthorId,
                                                targetType: 'post',
                                                reason: fullReason,
                                                createdAt: DateTime.now(),
                                                status: 'pending',
                                              );

                                              await _reportRequest.createReport(
                                                newReport,
                                              );

                                              if (!mounted) return;

                                              Navigator.pop(bottomSheetContext);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Đã gửi báo cáo thành công! Chúng tôi sẽ xem xét trong thời gian sớm nhất.',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  duration: Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (!mounted) return;

                                            Navigator.pop(bottomSheetContext);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Lỗi gửi báo cáo: $e',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          } finally {
                                            if (mounted) {
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
                                            color: Colors.white,
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
        Widget buildPrivacyOption({
          required String value,
          required IconData icon,
          required String title,
          required String subtitle,
        }) {
          final bool isSelected = _currentPost.visibility == value;
          return ListTile(
            onTap: () {
              Navigator.pop(ctx); // Đóng bottom sheet trước
              _updatePrivacy(context, value); // Gọi hàm cập nhật
            },
            leading: Icon(icon, color: Colors.grey[700]),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
            trailing:
                isSelected
                    ? const Icon(
                      Icons.check_circle,
                      color: Colors.blue /* Hoặc AppColors.primary */,
                    )
                    : null,
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ai có thể xem bài viết này?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              buildPrivacyOption(
                value: 'public',
                icon: Icons.public,
                title: 'Công khai',
                subtitle: 'Bất kỳ ai ở trong hoặc ngoài mạng xã hội.',
              ),
              const Divider(
                height: 1,
                indent: 56,
              ), // Indent bằng chiều rộng leading + padding
              buildPrivacyOption(
                value: 'friends',
                icon: Icons.group,
                title: 'Bạn bè',
                subtitle: 'Chỉ bạn bè của bạn có thể xem.',
              ),
              const Divider(height: 1, indent: 56),
              buildPrivacyOption(
                value: 'private',
                icon: Icons.lock,
                title: 'Chỉ mình tôi',
                subtitle: 'Bài viết này sẽ không hiển thị với ai khác.',
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // --- Hàm cập nhật quyền riêng tư ---
  void _updatePrivacy(BuildContext context, String newVisibility) async {
    // Thêm async/await
    // Cập nhật state ngay lập tức để UI thay đổi
    setState(() {
      _currentPost = _currentPost.copyWith(visibility: newVisibility);
    });

    try {
      // Gọi request để cập nhật Firestore
      await PostRequest().updatePost(
        _currentPost.copyWith(updatedAt: DateTime.now()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã cập nhật quyền riêng tư thành: ${_getVisibilityText(newVisibility)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Hoàn tác lại state nếu cập nhật thất bại
        setState(() {
          // Lấy lại visibility cũ từ widget.post (hoặc lưu state cũ trước khi cập nhật)
          _currentPost = _currentPost.copyWith(
            visibility: widget.post.visibility,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật quyền riêng tư: $e')),
        );
      }
    }
  }
} // Kết thúc _PostWidgetState
