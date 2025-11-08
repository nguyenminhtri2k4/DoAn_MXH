// // lib/view/widgets/post/post_media.dart
// import 'package:flutter/material.dart';
// import 'package:mangxahoi/authanet/firestore_listener.dart'; // Cần để lấy media
// import 'package:mangxahoi/model/model_media.dart';
// import 'package:provider/provider.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'video_player_item.dart'; // Import widget video vừa tách

// // --- Widget PostMedia ---
// class PostMedia extends StatelessWidget {
//   final List<String> mediaIds;

//   const PostMedia({super.key, required this.mediaIds});

//   @override
//   Widget build(BuildContext context) {
//     // Chỉ hiển thị nếu có mediaIds
//     if (mediaIds.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     final listener = context.watch<FirestoreListener>(); // Dùng watch để cập nhật nếu media thay đổi
//     // Hiện tại chỉ lấy media đầu tiên, có thể mở rộng sau
//     final mediaId = mediaIds.first;
//     final media = listener.getMediaById(mediaId);

//     // Xử lý trường hợp media chưa load kịp hoặc không tồn tại
//     if (media == null) {
//       return Padding(
//         padding: const EdgeInsets.only(top: 12.0), // Padding gốc từ PostWidget
//         child: Container(
//           height: 250,
//           color: Colors.grey[200],
//           child: const Center(child: CircularProgressIndicator()),
//         ),
//       );
//     }

//     // Hiển thị Video hoặc Image
//     Widget mediaWidget;
//     if (media.type == 'video') {
//       mediaWidget = VideoPlayerItem(
//         // Sử dụng ValueKey để đảm bảo widget được cập nhật đúng khi URL thay đổi
//         key: ValueKey('media_video_${media.id}'),
//         videoUrl: media.url
//       );
//     } else { // Mặc định là image
//       mediaWidget = CachedNetworkImage(
//         imageUrl: media.url,
//         fit: BoxFit.cover,
//         width: double.infinity,
//         placeholder: (context, url) => Container(
//           height: 250,
//           color: Colors.grey[200],
//           child: const Center(child: CircularProgressIndicator()),
//         ),
//         errorWidget: (context, url, error) => Container(
//           height: 250,
//           color: Colors.grey[200],
//           child: const Center(
//               child: Icon(Icons.error_outline, color: Colors.red)),
//         ),
//       );
//     }

//     // Thêm Padding bên ngoài cho cả video và image
//     return Padding(
//       padding: const EdgeInsets.only(top: 12.0),
//       child: mediaWidget,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/model/model_media.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'video_player_item.dart';

class PostMedia extends StatelessWidget {
  final List<String> mediaIds;

  const PostMedia({super.key, required this.mediaIds});

  @override
  Widget build(BuildContext context) {
    if (mediaIds.isEmpty) return const SizedBox.shrink();
    final int count = mediaIds.length;

    // NẾU CHỈ CÓ 1 MEDIA: Hiển thị như cũ (không giới hạn chiều cao)
    if (count == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: _buildMediaItem(context, mediaIds[0], width: double.infinity),
      );
    }

    // NẾU CÓ > 1 MEDIA: Sử dụng bố cục lưới với chiều cao cố định
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: SizedBox(
        height: _calculateHeight(count),
        child: _buildMediaLayout(context, count),
      ),
    );
  }

  double _calculateHeight(int count) {
    if (count == 2) return 250; // 2 ảnh cao 250
    return 380; // 3 ảnh trở lên cao 380 cho thoáng
  }

  Widget _buildMediaLayout(BuildContext context, int count) {
    switch (count) {
      case 2:
        return Row(
          children: [
            Expanded(child: _buildMediaItem(context, mediaIds[0], height: double.infinity)),
            const SizedBox(width: 4),
            Expanded(child: _buildMediaItem(context, mediaIds[1], height: double.infinity)),
          ],
        );
      case 3:
        return Column(
          children: [
            Expanded(flex: 2, child: _buildMediaItem(context, mediaIds[0], width: double.infinity)),
            const SizedBox(height: 4),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(context, mediaIds[1], height: double.infinity)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildMediaItem(context, mediaIds[2], height: double.infinity)),
                ],
              ),
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(context, mediaIds[0], height: double.infinity)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildMediaItem(context, mediaIds[1], height: double.infinity)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(context, mediaIds[2], height: double.infinity)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildMediaItem(context, mediaIds[3], height: double.infinity)),
                ],
              ),
            ),
          ],
        );
      default: // 5 ảnh trở lên
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(context, mediaIds[0], height: double.infinity)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildMediaItem(context, mediaIds[1], height: double.infinity)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(context, mediaIds[2], height: double.infinity)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildMediaItem(
                      context,
                      mediaIds[3],
                      height: double.infinity,
                      moreCount: count - 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildMediaItem(BuildContext context, String mediaId, {double? width, double? height, int? moreCount}) {
    // Sử dụng Selector để chỉ rebuild widget con này khi media cụ thể thay đổi
    return Selector<FirestoreListener, MediaModel?>(
      selector: (_, listener) => listener.getMediaById(mediaId),
      builder: (context, media, child) {
        if (media == null) {
          return Container(
            width: width,
            height: height ?? 200, // Chiều cao mặc định khi đang load
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        Widget mediaWidget;
        if (media.type == 'video') {
          mediaWidget = VideoPlayerItem(
            key: ValueKey('media_video_${media.id}'),
            videoUrl: media.url,
          );
        } else {
          mediaWidget = CachedNetworkImage(
            imageUrl: media.url,
            // Nếu có height cố định (trong lưới) thì dùng cover, ngược lại để tự nhiên
            fit: height != null ? BoxFit.cover : BoxFit.fitWidth,
            width: width,
            height: height,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              height: height,
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              height: height,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          );
        }

        // Lớp phủ hiển thị số lượng ảnh còn lại (+N)
        if (moreCount != null && moreCount > 0) {
          return Stack(
            fit: StackFit.expand,
            children: [
              mediaWidget,
              Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Text(
                  '+$moreCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }
        
        // Icon play nếu là video nằm trong lưới ảnh
        if (media.type == 'video' && height != null) {
           return Stack(
             fit: StackFit.expand,
             children: [
               mediaWidget,
               const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40)),
             ],
           );
        }

        return mediaWidget;
      },
    );
  }
}