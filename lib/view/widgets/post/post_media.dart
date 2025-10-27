// lib/view/widgets/post/post_media.dart
import 'package:flutter/material.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart'; // Cần để lấy media
import 'package:mangxahoi/model/model_media.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'video_player_item.dart'; // Import widget video vừa tách

// --- Widget PostMedia ---
class PostMedia extends StatelessWidget {
  final List<String> mediaIds;

  const PostMedia({super.key, required this.mediaIds});

  @override
  Widget build(BuildContext context) {
    // Chỉ hiển thị nếu có mediaIds
    if (mediaIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final listener = context.watch<FirestoreListener>(); // Dùng watch để cập nhật nếu media thay đổi
    // Hiện tại chỉ lấy media đầu tiên, có thể mở rộng sau
    final mediaId = mediaIds.first;
    final media = listener.getMediaById(mediaId);

    // Xử lý trường hợp media chưa load kịp hoặc không tồn tại
    if (media == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0), // Padding gốc từ PostWidget
        child: Container(
          height: 250,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Hiển thị Video hoặc Image
    Widget mediaWidget;
    if (media.type == 'video') {
      mediaWidget = VideoPlayerItem(
        // Sử dụng ValueKey để đảm bảo widget được cập nhật đúng khi URL thay đổi
        key: ValueKey('media_video_${media.id}'),
        videoUrl: media.url
      );
    } else { // Mặc định là image
      mediaWidget = CachedNetworkImage(
        imageUrl: media.url,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          height: 250,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 250,
          color: Colors.grey[200],
          child: const Center(
              child: Icon(Icons.error_outline, color: Colors.red)),
        ),
      );
    }

    // Thêm Padding bên ngoài cho cả video và image
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: mediaWidget,
    );
  }
}