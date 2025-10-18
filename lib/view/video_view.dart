// lib/view/video_view.dart
import 'package:flutter/material.dart';

class VideoView extends StatelessWidget {
  const VideoView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: Text('Trang Video')),
      ),
    );
  }
}