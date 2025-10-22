import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white), // Back button color
      ),
      body: Center(
        child: InteractiveViewer( // Allows zooming and panning
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain, // Show the whole image
            placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Colors.white)),
            errorWidget: (context, url, error) => Center(child: Icon(Icons.error, color: Colors.red)),
          ),
        ),
      ),
    );
  }
}