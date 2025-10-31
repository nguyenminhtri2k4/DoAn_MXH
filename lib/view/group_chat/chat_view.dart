
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';
// import 'package:video_player/video_player.dart';
// // --- Import cũ của bạn ---
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:mangxahoi/viewmodel/chat_viewmodel.dart';
// import 'package:mangxahoi/model/model_message.dart';
// import 'package:mangxahoi/model/model_user.dart';
// import 'package:mangxahoi/model/model_post.dart';
// import 'package:mangxahoi/model/model_media.dart';
// import 'package:mangxahoi/authanet/firestore_listener.dart';
// import 'package:mangxahoi/constant/app_colors.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:visibility_detector/visibility_detector.dart';
// // --- Thêm import của UserService ---
// import 'package:mangxahoi/services/user_service.dart';


// class ChatView extends StatelessWidget {
//   final String chatId;
//   final String chatName;

//   const ChatView({super.key, required this.chatId, required this.chatName});

//   @override
//   Widget build(BuildContext context) {
//     // --- Lấy currentUserId từ UserService ---
//     final String? currentUserId = context.watch<UserService>().currentUser?.uid;

//     return ChangeNotifierProvider(
//       // --- Truyền currentUserId vào ViewModel ---
//       create: (_) => ChatViewModel(chatId: chatId, currentUserId: currentUserId),
//       child: _ChatViewContent(chatName: chatName),
//     );
//   }
// }

// class _ChatViewContent extends StatelessWidget {
//   final String chatName;
//   const _ChatViewContent({required this.chatName});

//   @override
//   Widget build(BuildContext context) {
//     final vm = context.watch<ChatViewModel>();
//     final firestoreListener = context.watch<FirestoreListener>();

//     // --- Thêm xử lý lỗi (mới) ---
//     if (vm.errorMessage != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(vm.errorMessage!),
//             backgroundColor: Colors.red,
//           ),
//         );
//       });
//     }

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: Text(chatName),
//         backgroundColor: AppColors.backgroundLight,
//         elevation: 1,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<List<MessageModel>>(
//               stream: vm.messagesStream,
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 var messages = snapshot.data!;
//                 messages = messages.where((m) => m.status != 'deleted').toList();

//                 if (messages.isEmpty) {
//                   return const Center(child: Text('Bắt đầu cuộc trò chuyện.'));
//                 }

//                 return ListView.builder(
//                   reverse: true,
//                   padding: const EdgeInsets.all(10.0),
//                   itemCount: messages.length,
//                   itemBuilder: (context, index) {
//                     final message = messages[index];
//                     final sender = firestoreListener.getUserByAuthUid(message.senderId);
//                     // --- Sửa logic isMe ---
//                     final isMe = message.senderId == vm.currentUserId;

//                     return VisibilityDetector(
//                       key: Key(message.id),
//                       onVisibilityChanged: (visibilityInfo) {
//                         if (visibilityInfo.visibleFraction == 1.0 && !isMe && message.status != 'seen') {
//                           vm.markAsSeen(message.id);
//                         }
//                       },
//                       child: GestureDetector(
//                         onLongPress: () {
//                           if (isMe) {
//                             _showMessageOptions(context, vm, message);
//                           }
//                         },
//                         child: _MessageBubble(
//                           message: message,
//                           sender: sender,
//                           isMe: isMe,
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           _buildMessageComposer(context, vm),
//         ],
//       ),
//     );
//   }
  
//   // --- Hàm này giữ nguyên ---
//   void _showMessageOptions(BuildContext context, ChatViewModel vm, MessageModel message) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Wrap(
//           children: <Widget>[
//             ListTile(
//               leading: const Icon(Icons.undo),
//               title: const Text('Thu hồi'),
//               onTap: () {
//                 Navigator.pop(context);
//                 vm.recallMessage(message.id);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.delete),
//               title: const Text('Xóa'),
//               onTap: () {
//                 Navigator.pop(context);
//                 vm.deleteMessage(message.id);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // --- HÀM NÀY GIỮ NGUYÊN (TỪ LẦN TRƯỚC) ---
//   Widget _buildMessageComposer(BuildContext context, ChatViewModel vm) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
//       decoration: const BoxDecoration(
//         color: AppColors.backgroundLight,
//         border: Border(top: BorderSide(color: AppColors.divider)),
//       ),
//       child: SafeArea(
//         child: Column( // --- Bọc Row trong Column ---
//           children: [
//             // --- Thêm phần xem trước media (mới) ---
//             _buildMediaPreview(vm),
//             // --- Row cũ của bạn ---
//             Row(
//               children: <Widget>[
//                 // --- Thêm nút chọn ảnh (mới) ---
//                 IconButton(
//                   icon: Icon(Icons.image, color: Theme.of(context).primaryColor),
//                   onPressed: vm.isLoading ? null : vm.pickImages,
//                 ),
//                 // --- Thêm nút chọn video (mới) ---
//                 IconButton(
//                   icon: Icon(Icons.videocam, color: Theme.of(context).primaryColor),
//                   onPressed: vm.isLoading ? null : vm.pickVideo,
//                 ),
//                 Expanded(
//                   child: TextField(
//                     controller: vm.messageController,
//                     textCapitalization: TextCapitalization.sentences,
//                     decoration: InputDecoration(
//                       hintText: 'Nhập tin nhắn...',
//                       filled: true,
//                       fillColor: AppColors.background,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30),
//                         borderSide: BorderSide.none,
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 // --- Cập nhật nút Gửi (mới) ---
//                 vm.isLoading 
//                   ? Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: CircularProgressIndicator(),
//                     )
//                   : IconButton(
//                       icon: const Icon(Icons.send),
//                       iconSize: 25.0,
//                       color: Theme.of(context).primaryColor,
//                       // --- Sửa: disable khi đang loading ---
//                       onPressed: vm.isLoading ? null : vm.sendMessage,
//                     ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- HÀM NÀY GIỮ NGUYÊN (TỪ LẦN TRƯỚC) ---
//   Widget _buildMediaPreview(ChatViewModel viewModel) {
//     if (viewModel.selectedMedia.isEmpty) {
//       return SizedBox.shrink();
//     }

//     return Container(
//       height: 200,
//       padding: EdgeInsets.only(bottom: 8.0),
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: viewModel.selectedMedia.length,
//         itemBuilder: (context, index) {
//           final file = viewModel.selectedMedia[index];
//           final bool isVideo = file.path.toLowerCase().endsWith('.mp4') ||
//               file.path.toLowerCase().endsWith('.mov');

//           return Stack(
//             alignment: Alignment.topRight,
//             children: [
//               Container(
//                 margin: EdgeInsets.symmetric(horizontal: 4.0),
//                 width: 80,
//                 height: 100,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8.0),
//                   color: Colors.grey[300],
//                 ),
//                 child: isVideo
//                     ? Container(
//                         color: Colors.black,
//                         child: Icon(Icons.videocam, color: Colors.white, size: 40),
//                       )
//                     : ClipRRect(
//                         borderRadius: BorderRadius.circular(8.0),
//                         child: Image.file(
//                           File(file.path),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//               ),
//               GestureDetector(
//                 onTap: () => viewModel.removeMedia(file),
//                 child: Container(
//                   padding: EdgeInsets.all(2),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.5),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(Icons.close, color: Colors.white, size: 18),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// class _MessageBubble extends StatelessWidget {
//   final MessageModel message;
//   final UserModel? sender;
//   final bool isMe;

//   const _MessageBubble({
//     required this.message,
//     required this.sender,
//     required this.isMe,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (message.status == 'recalled') {
//       return _buildRecalledMessageBubble();
//     }
//     if (message.type == 'share_post' && message.sharedPostId != null) {
//       return _buildSharedPostBubble(context);
//     }
//     return _buildTextBubble(context);
//   }
  
//   // --- Hàm này giữ nguyên ---
//   Widget _buildRecalledMessageBubble() {
//     return Row(
//       mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//       children: [
//         Container(
//           margin: const EdgeInsets.symmetric(vertical: 6.0),
//           padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
//           decoration: BoxDecoration(
//             color: Colors.grey[200],
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: const Text(
//             'Tin nhắn đã bị thu hồi',
//             style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
//           ),
//         ),
//       ],
//     );
//   }

//   // --- Hàm này giữ nguyên ---
//   Widget _buildSharedPostBubble(BuildContext context) {
//     final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
//     final rowAlignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
//     final avatarImage = sender?.avatar.isNotEmpty ?? false ? NetworkImage(sender!.avatar.first) : null;

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Column(
//         crossAxisAlignment: alignment,
//         children: [
//           Row(
//             mainAxisAlignment: rowAlignment,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               if (!isMe) ...[
//                 CircleAvatar(
//                   radius: 18.0,
//                   backgroundImage: avatarImage,
//                   child: avatarImage == null ? const Icon(Icons.person, size: 18) : null,
//                 ),
//                 const SizedBox(width: 8.0),
//               ],
//               Column(
//                 crossAxisAlignment: alignment,
//                 children: [
//                   if (!isMe && sender != null)
//                     Padding(
//                       padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
//                       child: Text(sender!.name, style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
//                     ),
//                   if(message.content.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 4.0),
//                       child: Text(message.content, style: const TextStyle(color: AppColors.textSecondary)),
//                     ),
//                   _SharedPostPreview(postId: message.sharedPostId!),
//                 ],
//               ),
//             ],
//           ),
//           Padding(
//             padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 52, right: isMe ? 8 : 0),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(DateFormat('HH:mm').format(message.createdAt), style: const TextStyle(fontSize: 10.0, color: Colors.grey)),
//                 if (isMe) ...[
//                   const SizedBox(width: 4),
//                   _buildStatusIcon(message.status),
//                 ]
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ======================================================
//   // ===> NÂNG CẤP BONG BÓNG CHAT (MỚI) <===
//   // ======================================================
//   Widget _buildTextBubble(BuildContext context) {
//     // --- Lấy style từ friends_view.dart ---
//     final Radius messageRadius = const Radius.circular(18.0); // Bo góc
//     final avatarImage = sender?.avatar.isNotEmpty ?? false ? NetworkImage(sender!.avatar.first) : null;

//     final bool hasText = message.content.isNotEmpty;
//     final bool hasMedia = message.mediaIds.isNotEmpty;

//     final messageContent = Container(
//       constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
//       // --- Xóa padding ngoài, để media tràn viền ---
//       padding: EdgeInsets.zero, 
//       decoration: BoxDecoration(
//         color: isMe ? AppColors.primary : Colors.white,
//         borderRadius: isMe
//             ? BorderRadius.only(topLeft: messageRadius, bottomLeft: messageRadius, topRight: messageRadius)
//             : BorderRadius.only(topRight: messageRadius, bottomRight: messageRadius, topLeft: messageRadius),
//         // --- Thêm shadow cho bong bóng người khác ---
//         boxShadow: [ 
//           if (!isMe) 
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 10,
//               offset: const Offset(0, 2)
//             ) 
//         ],
//       ),
//       // --- Dùng ClipRRect để bo góc media bên trong ---
//       child: ClipRRect(
//         borderRadius: isMe
//             ? BorderRadius.only(topLeft: messageRadius, bottomLeft: messageRadius, topRight: messageRadius)
//             : BorderRadius.only(topRight: messageRadius, bottomRight: messageRadius, topLeft: messageRadius),
//         child: Column(
//           crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//           children: [
//             // Tên người gửi (!isMe)
//             if (!isMe && sender != null)
//               Padding(
//                 // Thêm padding cho tên
//                 padding: EdgeInsets.only(
//                   top: hasMedia ? 8.0 : 10.0, // Nếu có media, giảm padding
//                   left: 14.0, 
//                   right: 14.0, 
//                   bottom: (hasMedia || hasText) ? 4.0 : 10.0 // Thêm bottom padding nếu chỉ có tên
//                 ),
//                 child: Text(sender!.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14.0)),
//               ),
            
//             // Lưới Media
//             if (hasMedia)
//               _buildMessageMedia(context, message.mediaIds, hasText),
            
//             // Nội dung Text
//             if (hasText)
//               Padding(
//                 // Thêm padding cho text
//                 padding: EdgeInsets.only(
//                   top: (hasMedia || (!isMe && sender != null)) ? 8.0 : 10.0, // Nếu có media/tên, giảm padding
//                   bottom: 10.0,
//                   left: 14.0,
//                   right: 14.0,
//                 ),
//                 child: Text(message.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15.0)),
//               ),
//           ],
//         ),
//       ),
//     );

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               if (!isMe) ...[
//                 // --- Avatar style từ friends_view.dart ---
//                 Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.grey[200]!, width: 1),
//                   ),
//                   child: CircleAvatar(
//                     radius: 18.0,
//                     backgroundColor: Colors.grey[100],
//                     backgroundImage: avatarImage,
//                     child: avatarImage == null ? const Icon(Icons.person, size: 18, color: Colors.grey) : null,
//                   ),
//                 ),
//                 const SizedBox(width: 8.0),
//               ],
//               messageContent,
//             ],
//           ),
//           // Thời gian + Trạng thái
//           Padding(
//             padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 52, right: isMe ? 8 : 0),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(DateFormat('HH:mm').format(message.createdAt), style: const TextStyle(fontSize: 10.0, color: Colors.grey)),
//                 if (isMe) ...[
//                   const SizedBox(width: 4),
//                   _buildStatusIcon(message.status),
//                 ]
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   // --- Hàm này giữ nguyên ---
//   Widget _buildStatusIcon(String status) {
//     IconData iconData;
//     Color color = Colors.grey;
//     switch (status) {
//       case 'seen':
//         iconData = Icons.done_all;
//         color = Colors.blue;
//         break;
//       case 'delivered':
//         iconData = Icons.done_all;
//         break;
//       case 'sent':
//       default:
//         iconData = Icons.check;
//         break;
//     }
//     return Icon(iconData, size: 14, color: color);
//   }

//   // ======================================================
//   // ===> NÂNG CẤP LƯỚI MEDIA (MỚI) <===
//   // ======================================================
//   Widget _buildMessageMedia(BuildContext context, List<String> mediaIds, bool hasText) {
//     final double mediaWidth = MediaQuery.of(context).size.width * 0.75;
//     final firestoreListener = context.read<FirestoreListener>();
//     final int count = mediaIds.length;
//     final double spacing = 3.0; // Khoảng cách nhỏ giữa các ảnh
//     final double borderRadius = 0.0; // Không bo góc ở đây, bubble cha đã bo rồi
    
//     // Nếu chỉ có 1 media, cho nó to
//     if (count == 1) {
//       final media = firestoreListener.getMediaById(mediaIds.first);
//       return _buildMediaItem(
//         media: media, 
//         width: mediaWidth, 
//         height: 250, 
//         borderRadius: borderRadius
//       );
//     }
    
//     // Nếu 2 media, chia đôi
//     if (count == 2) {
//       final itemWidth = (mediaWidth - spacing) / 2;
//       return Row(
//         children: [
//           _buildMediaItem(
//             media: firestoreListener.getMediaById(mediaIds[0]),
//             width: itemWidth, 
//             height: 180, 
//             borderRadius: borderRadius
//           ),
//           SizedBox(width: spacing),
//           _buildMediaItem(
//             media: firestoreListener.getMediaById(mediaIds[1]),
//             width: itemWidth, 
//             height: 180, 
//             borderRadius: borderRadius
//           ),
//         ],
//       );
//     }

//     // Nếu 3 media, chia 3
//     final itemWidth = (mediaWidth - (2 * spacing)) / 3;
//     return Row(
//       children: [
//          _buildMediaItem(
//             media: firestoreListener.getMediaById(mediaIds[0]),
//             width: itemWidth, 
//             height: 120, 
//             borderRadius: borderRadius
//           ),
//           SizedBox(width: spacing),
//           _buildMediaItem(
//             media: firestoreListener.getMediaById(mediaIds[1]),
//             width: itemWidth, 
//             height: 120, 
//             borderRadius: borderRadius
//           ),
//           SizedBox(width: spacing),
//            _buildMediaItem(
//             media: firestoreListener.getMediaById(mediaIds[2]),
//             width: itemWidth, 
//             height: 120, 
//             borderRadius: borderRadius
//           ),
//       ],
//     );
//   }

//   // --- Widget con để hiển thị media (Mới) ---
//   Widget _buildMediaItem({
//     required MediaModel? media, 
//     required double width, 
//     required double height, 
//     required double borderRadius
//   }) {
//     // Widget chờ
//     if (media == null) {
//       return Container(
//         width: width,
//         height: height,
//         decoration: BoxDecoration(
//           color: Colors.grey[300]?.withOpacity(0.5),
//           borderRadius: BorderRadius.circular(borderRadius),
//         ),
//         child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
//       );
//     }

//     // Ảnh
//     if (media.type == 'image') {
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(borderRadius),
//         child: CachedNetworkImage(
//           imageUrl: media.url,
//           width: width,
//           height: height,
//           fit: BoxFit.cover,
//           placeholder: (context, url) => Container(
//             width: width,
//             height: height,
//             color: Colors.grey[300]?.withOpacity(0.5),
//             child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
//           ),
//           errorWidget: (context, url, error) => Container(
//             width: width,
//             height: height,
//             color: Colors.grey[300]?.withOpacity(0.5),
//             child: Icon(Icons.broken_image, color: Colors.grey[600]),
//           ),
//         ),
//       );
//     }

//     // Video
//     if (media.type == 'video') {
//       return _MessageVideoPlayer(
//         videoUrl: media.url,
//         width: width,
//         height: 300,//height, 
//         borderRadius: borderRadius,
//       );
//     }
    
//     return SizedBox.shrink();
//   }
// }

// // ======================================================
// // ===> NÂNG CẤP VIDEO PLAYER (MỚI) <===
// // ======================================================
// class _MessageVideoPlayer extends StatefulWidget {
//   final String videoUrl;
//   final double width;
//   final double height;
//   final double borderRadius;

//   const _MessageVideoPlayer({
//     Key? key,
//     required this.videoUrl,
//     required this.width,
//     required this.height,
//     required this.borderRadius,
//   }) : super(key: key);

//   @override
//   _MessageVideoPlayerState createState() => _MessageVideoPlayerState();
// }

// class _MessageVideoPlayerState extends State<_MessageVideoPlayer> {
//   late VideoPlayerController _controller;
//   bool _isInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
//       ..initialize().then((_) {
//         if (mounted) {
//           setState(() {
//             _isInitialized = true;
//           });
//         }
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(widget.borderRadius),
//       child: Container(
//         width: widget.width,
//         height: widget.height,
//         color: Colors.black,
//         child: _isInitialized
//             ? GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     if (_controller.value.isPlaying) {
//                       _controller.pause();
//                     } else {
//                       _controller.play();
//                     }
//                   });
//                 },
//                 child: Stack(
//                   alignment: Alignment.center,
//                   fit: StackFit.expand,
//                   children: [
//                     FittedBox(
//                       fit: BoxFit.cover,
//                       clipBehavior: Clip.hardEdge,
//                       child: SizedBox(
//                         width: _controller.value.size.width,
//                         height: _controller.value.size.height,
//                         child: VideoPlayer(_controller),
//                       ),
//                     ),

//                     // Hiển thị icon Play hoặc Pause khi video DỪNG
//                     if (!_controller.value.isPlaying)
//                       Icon(
//                         Icons.play_arrow,
//                         color: Colors.white,
//                         size: 30,
//                       ),
//                   ],
//                 ),
//               )
//             : const Center(
//                 child: CircularProgressIndicator(
//                     color: Colors.white, strokeWidth: 2.0),
//               ),
//       ),
//     );
//   }
// }


// // --- Lớp _SharedPostPreview giữ nguyên (bạn đã có) ---
// class _SharedPostPreview extends StatelessWidget {
//   final String postId;

//   const _SharedPostPreview({required this.postId});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.pushNamed(context, '/post_detail', arguments: postId);
//       },
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.65,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: StreamBuilder<DocumentSnapshot>(
//           stream: FirebaseFirestore.instance.collection('Post').doc(postId).snapshots(),
//           builder: (context, snapshot) {
//             if (!snapshot.hasData || !snapshot.data!.exists) {
//               return const Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Text('Bài viết đã bị xóa hoặc không tồn tại.'),
//               );
//             }
//             final post = PostModel.fromMap(snapshot.data!.id, snapshot.data!.data() as Map<String, dynamic>);
//             final author = context.read<FirestoreListener>().getUserById(post.authorId);

//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 18,
//                         backgroundImage: (author?.avatar.isNotEmpty ?? false) ? NetworkImage(author!.avatar.first) : null,
//                         child: (author?.avatar.isEmpty ?? true) ? const Icon(Icons.person, size: 18) : null,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(author?.name ?? '...', style: const TextStyle(fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                 ),
//                 if (post.content.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//                     child: Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis),
//                   ),
//                 if (post.mediaIds.isNotEmpty)
//                   _buildMediaPreview(context, post),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildMediaPreview(BuildContext context, PostModel post) {
//     final media = context.read<FirestoreListener>().getMediaById(post.mediaIds.first);
//     if (media == null) return const SizedBox.shrink();

//     if (media.type == 'video') {
//       return Container(
//         height: 150,
//         decoration: const BoxDecoration(
//           color: Colors.black,
//           borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
//         ),
//         child: const Center(
//           child: Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
//         ),
//       );
//     }

//     return ClipRRect(
//       borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
//       child: CachedNetworkImage(
//         imageUrl: media.url,
//         height: 150,
//         width: double.infinity,
//         fit: BoxFit.cover,
//       ),
//     );
//   }
// }
// --- Thêm các import mới ---
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
// --- Import cũ của bạn ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/chat_viewmodel.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_media.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
// --- Thêm import của UserService ---
import 'package:mangxahoi/services/user_service.dart';

// Import màn hình xem ảnh/video full
import 'package:mangxahoi/view/widgets/full_screen_image_viewer.dart';
import 'package:mangxahoi/view/widgets/full_screen_video_player.dart';
import 'package:mangxahoi/services/call_service.dart'; // Để dùng cho ViewModel
import 'package:mangxahoi/model/model_call.dart';


class ChatView extends StatelessWidget {
  final String chatId;
  final String chatName;

  const ChatView({super.key, required this.chatId, required this.chatName});

  @override
  Widget build(BuildContext context) {
    // --- Lấy currentUserId từ UserService ---
    final String? currentUserId = context.watch<UserService>().currentUser?.id;

    return ChangeNotifierProvider(
      // --- Truyền currentUserId vào ViewModel ---
      create: (_) => ChatViewModel(chatId: chatId, currentUserId: currentUserId),
      child: _ChatViewContent(chatName: chatName),
    );
  }
}

class _ChatViewContent extends StatelessWidget {
  final String chatName;
  const _ChatViewContent({required this.chatName});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final firestoreListener = context.watch<FirestoreListener>();

    // --- Thêm xử lý lỗi (mới) ---
    if (vm.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(chatName),
        backgroundColor: AppColors.backgroundLight,
        elevation: 1,
        actions: [
          // Chỉ hiển thị nút gọi nếu KHÔNG phải là nhóm
          if (!vm.isGroup) // ViewModel sẽ tự biết
            IconButton(
              icon: Icon(Icons.call),
              onPressed: () {
                vm.startAudioCall(context);
              },
            ),
          if (!vm.isGroup)
            IconButton(
              icon: Icon(Icons.videocam),
              onPressed: () {
                 vm.startVideoCall(context);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: vm.messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var messages = snapshot.data!;
                messages = messages.where((m) => m.status != 'deleted').toList();

                if (messages.isEmpty) {
                  return const Center(child: Text('Bắt đầu cuộc trò chuyện.'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final sender = firestoreListener.getUserByAuthUid(message.senderId);
                    // --- Sửa logic isMe ---
                    final isMe = message.senderId == vm.currentUserId;

                    return VisibilityDetector(
                      key: Key(message.id),
                      onVisibilityChanged: (visibilityInfo) {
                        if (visibilityInfo.visibleFraction == 1.0 && !isMe && message.status != 'seen') {
                          vm.markAsSeen(message.id);
                        }
                      },
                      child: GestureDetector(
                        onLongPress: () {
                          if (isMe) {
                            _showMessageOptions(context, vm, message);
                          }
                        },
                        child: _MessageBubble(
                          message: message,
                          sender: sender,
                          isMe: isMe,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(context, vm),
        ],
      ),
    );
  }

  // --- Hàm này giữ nguyên ---
  void _showMessageOptions(BuildContext context, ChatViewModel vm, MessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.undo),
              title: const Text('Thu hồi'),
              onTap: () {
                Navigator.pop(context);
                vm.recallMessage(message.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Xóa'),
              onTap: () {
                Navigator.pop(context);
                vm.deleteMessage(message.id);
              },
            ),
          ],
        );
      },
    );
  }

  // --- HÀM NÀY GIỮ NGUYÊN (TỪ LẦN TRƯỚC) ---
  Widget _buildMessageComposer(BuildContext context, ChatViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Column( // --- Bọc Row trong Column ---
          children: [
            // --- Thêm phần xem trước media (mới) ---
            _buildMediaPreview(vm),
            // --- Row cũ của bạn ---
            Row(
              children: <Widget>[
                // --- Thêm nút chọn ảnh (mới) ---
                IconButton(
                  icon: Icon(Icons.image, color: Theme.of(context).primaryColor),
                  onPressed: vm.isLoading ? null : vm.pickImages,
                ),
                // --- Thêm nút chọn video (mới) ---
                IconButton(
                  icon: Icon(Icons.videocam, color: Theme.of(context).primaryColor),
                  onPressed: vm.isLoading ? null : vm.pickVideo,
                ),
                Expanded(
                  child: TextField(
                    controller: vm.messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // --- Cập nhật nút Gửi (mới) ---
                vm.isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      iconSize: 25.0,
                      color: Theme.of(context).primaryColor,
                      // --- Sửa: disable khi đang loading ---
                      onPressed: vm.isLoading ? null : vm.sendMessage,
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- HÀM NÀY GIỮ NGUYÊN (TỪ LẦN TRƯỚC) ---
  Widget _buildMediaPreview(ChatViewModel viewModel) {
    if (viewModel.selectedMedia.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      height: 100,
      padding: EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.selectedMedia.length,
        itemBuilder: (context, index) {
          final file = viewModel.selectedMedia[index];
          final bool isVideo = file.path.toLowerCase().endsWith('.mp4') ||
              file.path.toLowerCase().endsWith('.mov');

          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.grey[300],
                ),
                child: isVideo
                    ? Container(
                        color: Colors.black,
                        child: Icon(Icons.videocam, color: Colors.white, size: 40),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          File(file.path),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              GestureDetector(
                onTap: () => viewModel.removeMedia(file),
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? sender;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.sender,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (message.status == 'recalled') {
      return _buildRecalledMessageBubble();
    }
    if (message.type == 'share_post' && message.sharedPostId != null) {
      return _buildSharedPostBubble(context);
    }
    return _buildTextBubble(context);
  }

  // --- Hàm này giữ nguyên ---
  Widget _buildRecalledMessageBubble() {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Tin nhắn đã bị thu hồi',
            style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  // --- Hàm này giữ nguyên ---
  Widget _buildSharedPostBubble(BuildContext context) {
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowAlignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final avatarImage = sender?.avatar.isNotEmpty ?? false ? NetworkImage(sender!.avatar.first) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: rowAlignment,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!isMe) ...[
                CircleAvatar(
                  radius: 18.0,
                  backgroundImage: avatarImage,
                  child: avatarImage == null ? const Icon(Icons.person, size: 18) : null,
                ),
                const SizedBox(width: 8.0),
              ],
              Column(
                crossAxisAlignment: alignment,
                children: [
                  if (!isMe && sender != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                      child: Text(sender!.name, style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
                    ),
                  if(message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(message.content, style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                  _SharedPostPreview(postId: message.sharedPostId!),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 52, right: isMe ? 8 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('HH:mm').format(message.createdAt), style: const TextStyle(fontSize: 10.0, color: Colors.grey)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // ===> NÂNG CẤP BONG BÓNG CHAT (GIỮ NGUYÊN TỪ LẦN TRƯỚC) <===
  // ======================================================
  Widget _buildTextBubble(BuildContext context) {
    final Radius messageRadius = const Radius.circular(18.0);
    final avatarImage = sender?.avatar.isNotEmpty ?? false ? NetworkImage(sender!.avatar.first) : null;
    final bool hasText = message.content.isNotEmpty;
    final bool hasMedia = message.mediaIds.isNotEmpty;

    final messageContent = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : Colors.white,
        borderRadius: isMe
            ? BorderRadius.only(topLeft: messageRadius, bottomLeft: messageRadius, topRight: messageRadius)
            : BorderRadius.only(topRight: messageRadius, bottomRight: messageRadius, topLeft: messageRadius),
        boxShadow: [
          if (!isMe)
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2)
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: isMe
            ? BorderRadius.only(topLeft: messageRadius, bottomLeft: messageRadius, topRight: messageRadius)
            : BorderRadius.only(topRight: messageRadius, bottomRight: messageRadius, topLeft: messageRadius),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && sender != null)
              Padding(
                padding: EdgeInsets.only(
                  top: hasMedia ? 8.0 : 10.0,
                  left: 14.0,
                  right: 14.0,
                  bottom: (hasMedia || hasText) ? 4.0 : 10.0
                ),
                child: Text(sender!.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14.0)),
              ),
            if (hasMedia)
              _buildMessageMedia(context, message.mediaIds, hasText),
            if (hasText)
              Padding(
                padding: EdgeInsets.only(
                  top: (hasMedia || (!isMe && sender != null)) ? 8.0 : 10.0,
                  bottom: 10.0,
                  left: 14.0,
                  right: 14.0,
                ),
                child: Text(message.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15.0)),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!isMe) ...[
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 18.0,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: avatarImage,
                    child: avatarImage == null ? const Icon(Icons.person, size: 18, color: Colors.grey) : null,
                  ),
                ),
                const SizedBox(width: 8.0),
              ],
              messageContent,
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: isMe ? 0 : 52, right: isMe ? 8 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('HH:mm').format(message.createdAt), style: const TextStyle(fontSize: 10.0, color: Colors.grey)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Hàm này giữ nguyên ---
  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color color = Colors.grey;
    switch (status) {
      case 'seen':
        iconData = Icons.done_all;
        color = Colors.blue;
        break;
      case 'delivered':
        iconData = Icons.done_all;
        break;
      case 'sent':
      default:
        iconData = Icons.check;
        break;
    }
    return Icon(iconData, size: 14, color: color);
  }

  Widget _buildMessageMedia(BuildContext context, List<String> mediaIds, bool hasText) {
    final double mediaWidth = MediaQuery.of(context).size.width * 0.75;
    final firestoreListener = context.read<FirestoreListener>();
    final int count = mediaIds.length;
    final double spacing = 3.0;
    final double borderRadius = 0.0;

    if (count == 1) {
      final media = firestoreListener.getMediaById(mediaIds.first);
      return _buildMediaItem(
        context: context, // Truyền context
        media: media,
        width: mediaWidth,
        height: 250,
        borderRadius: borderRadius
      );
    }

    if (count == 2) {
      final itemWidth = (mediaWidth - spacing) / 2;
      return Row(
        children: [
          _buildMediaItem(
            context: context, // Truyền context
            media: firestoreListener.getMediaById(mediaIds[0]),
            width: itemWidth,
            height: 180,
            borderRadius: borderRadius
          ),
          SizedBox(width: spacing),
          _buildMediaItem(
            context: context, // Truyền context
            media: firestoreListener.getMediaById(mediaIds[1]),
            width: itemWidth,
            height: 180,
            borderRadius: borderRadius
          ),
        ],
      );
    }

    final itemWidth = (mediaWidth - (2 * spacing)) / 3;
    return Row(
      children: [
         _buildMediaItem(
            context: context, // Truyền context
            media: firestoreListener.getMediaById(mediaIds[0]),
            width: itemWidth,
            height: 120,
            borderRadius: borderRadius
          ),
          SizedBox(width: spacing),
          _buildMediaItem(
            context: context, // Truyền context
            media: firestoreListener.getMediaById(mediaIds[1]),
            width: itemWidth,
            height: 120,
            borderRadius: borderRadius
          ),
          SizedBox(width: spacing),
           _buildMediaItem(
            context: context, // Truyền context
            media: firestoreListener.getMediaById(mediaIds[2]),
            width: itemWidth,
            height: 120,
            borderRadius: borderRadius
          ),
      ],
    );
  }

  // ======================================================
  // ===> NÂNG CẤP MEDIA ITEM (THÊM GESTUREDETECTOR) <===
  // ======================================================
  Widget _buildMediaItem({
    required BuildContext context, // Thêm context
    required MediaModel? media,
    required double width,
    required double height,
    required double borderRadius
  }) {
    // Widget chờ
    if (media == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
      );
    }

    // Ảnh (thêm GestureDetector)
    if (media.type == 'image') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImageViewer(imageUrl: media.url),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CachedNetworkImage(
            imageUrl: media.url,
            width: width,
            height: height,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container( /* Placeholder */ ),
            errorWidget: (context, url, error) => Container( /* Error widget */ ),
          ),
        ),
      );
    }

    // Video (thêm GestureDetector)
    if (media.type == 'video') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenVideoPlayer(videoUrl: media.url),
            ),
          );
        },
        child: _MessageVideoPlayer(
          videoUrl: media.url,
          width: width,
          height: height,
          borderRadius: borderRadius,
        ),
      );
    }

    return SizedBox.shrink();
  }
}

class _MessageVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final double borderRadius;

  const _MessageVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.width,
    required this.height,
    required this.borderRadius,
  }) : super(key: key);

  @override
  _MessageVideoPlayerState createState() => _MessageVideoPlayerState();
}

class _MessageVideoPlayerState extends State<_MessageVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      })
      ..setLooping(true)
      ..addListener(() {
        if (mounted && _controller.value.isPlaying) {
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: _isInitialized
            ? Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  if (!_controller.value.isPlaying)
                    Container(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                ],
              )
            : Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
              ),
      ),
    );
  }
}


// --- Lớp _SharedPostPreview giữ nguyên (bạn đã có) ---
class _SharedPostPreview extends StatelessWidget {
  final String postId;

  const _SharedPostPreview({required this.postId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/post_detail', arguments: postId);
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('Post').doc(postId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Bài viết đã bị xóa hoặc không tồn tại.'),
              );
            }
            final post = PostModel.fromMap(snapshot.data!.id, snapshot.data!.data() as Map<String, dynamic>);
            final author = context.read<FirestoreListener>().getUserById(post.authorId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: (author?.avatar.isNotEmpty ?? false) ? NetworkImage(author!.avatar.first) : null,
                        child: (author?.avatar.isEmpty ?? true) ? const Icon(Icons.person, size: 18) : null,
                      ),
                      const SizedBox(width: 8),
                      Text(author?.name ?? '...', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (post.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                  ),
                if (post.mediaIds.isNotEmpty)
                  _buildMediaPreview(context, post),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context, PostModel post) {
    final media = context.read<FirestoreListener>().getMediaById(post.mediaIds.first);
    if (media == null) return const SizedBox.shrink();

    if (media.type == 'video') {
      return Container(
        height: 150,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
      child: CachedNetworkImage(
        imageUrl: media.url,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}