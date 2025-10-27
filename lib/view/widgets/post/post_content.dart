// lib/view/widgets/post/post_content.dart
import 'package:flutter/material.dart';

// --- Widget PostContent ---
class PostContent extends StatelessWidget {
  final String content;

  const PostContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    // Chỉ hiển thị nếu content không rỗng
    return content.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(right: 8.0), // Padding gốc từ PostWidget
            child: Text(content, style: const TextStyle(fontSize: 16)),
          )
        : const SizedBox.shrink(); // Không hiển thị gì nếu content rỗng
  }
}