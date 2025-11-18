
import 'package:flutter/material.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/model/model_media.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'video_player_item.dart';
import 'package:mangxahoi/view/widgets/post/full_screen_gallery_viewer.dart';

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
        bool isVideo = media.type == 'video'; // Kiểm tra có phải video không

        if (isVideo) {
          mediaWidget = VideoPlayerItem(
            key: ValueKey('media_video_${media.id}'),
            videoUrl: media.url,
          );
        } else {
          // Là ảnh
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

        Widget finalWidget; // Widget cuối cùng sẽ được trả về

        // Lớp phủ hiển thị số lượng ảnh còn lại (+N)
        if (moreCount != null && moreCount > 0) {
          finalWidget = Stack(
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
        else if (isVideo && height != null) {
           finalWidget = Stack(
             fit: StackFit.expand,
             children: [
               mediaWidget,
               const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40)),
             ],
           );
        }

        // Chỉ là media đơn thuần (không có lớp phủ)
        else {
          finalWidget = mediaWidget;
        }


        // --- BẮT ĐẦU CODE MỚI ---
        // Nếu media là ẢNH (!isVideo), bọc nó bằng GestureDetector
        if (!isVideo) {
          return GestureDetector(
            onTap: () {
              // Lấy listener (dùng context.read để không bị rebuild)
              final listener = context.read<FirestoreListener>();
              
              // 1. Lấy tất cả các MediaModel là ẢNH từ mediaIds của bài post
              final List<MediaModel> imageMediaModels = [];
              // mediaIds là biến final của class PostMedia
              for (String id in mediaIds) { 
                final m = listener.getMediaById(id);
                // Chỉ thêm nếu media tồn tại và là ảnh
                if (m != null && m.type == 'image') {
                  imageMediaModels.add(m);
                }
              }
              
              // 2. Tạo danh sách các URL từ các model đã lọc
              final List<String> imageUrls = imageMediaModels.map((m) => m.url).toList();

              // 3. Tìm vị trí (index) của ảnh vừa nhấn trong danh sách ảnh
              int initialIndex = imageMediaModels.indexWhere((m) => m.id == media.id);
              if (initialIndex == -1) initialIndex = 0; // Fallback

              // 4. Điều hướng đến màn hình xem ảnh (chỉ khi có ảnh để xem)
              if (imageUrls.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenGalleryViewer( // Sử dụng Widget mới
                      imageUrls: imageUrls,
                      initialIndex: initialIndex,
                    ),
                  ),
                );
              }
            },
            child: finalWidget, // Bọc widget cuối cùng (có thể là Stack hoặc chỉ là ảnh)
          );
        }

        return finalWidget;
      },
    );
  }
}