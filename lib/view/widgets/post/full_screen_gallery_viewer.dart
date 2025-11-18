import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenGalleryViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenGalleryViewer({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white), // Back button color
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = imageUrls[index];
          // Tái sử dụng logic từ FullScreenImageViewer của bạn
          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain, // Hiển thị toàn bộ ảnh
                placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (context, url, error) => Center(child: Icon(Icons.error, color: Colors.red)),
              ),
            ),
          );
        },
      ),
    );
  }
}