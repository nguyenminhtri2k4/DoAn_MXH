// FILE: media_preview.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangxahoi/viewmodel/chat_viewmodel.dart';

class MediaPreview extends StatelessWidget {
  final ChatViewModel viewModel;

  const MediaPreview({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.selectedMedia.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 100,
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.selectedMedia.length,
        itemBuilder: (context, index) {
          final file = viewModel.selectedMedia[index];
          final bool isVideo =
              file.path.toLowerCase().endsWith('.mp4') ||
              file.path.toLowerCase().endsWith('.mov');
          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.grey[300],
                ),
                child:
                    isVideo
                        ? Container(
                          alignment: Alignment.center,
                          color: Colors.black,
                          child: const Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 40,
                          ),
                        )
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(File(file.path), fit: BoxFit.cover),
                        ),
              ),
              GestureDetector(
                onTap: () => viewModel.removeMedia(file),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}