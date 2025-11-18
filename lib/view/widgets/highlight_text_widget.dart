import 'package:flutter/material.dart';
import 'package:mangxahoi/constant/app_colors.dart';

/// Widget để highlight text với từ khóa tìm kiếm
class HighlightText extends StatelessWidget {
  final String text;
  final String? highlightQuery;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const HighlightText({
    super.key,
    required this.text,
    this.highlightQuery,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (highlightQuery == null || highlightQuery!.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    final query = highlightQuery!.toLowerCase();
    final textLower = text.toLowerCase();

    if (!textLower.contains(query)) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final index = textLower.indexOf(query, start);
      if (index == -1) {
        // Thêm phần text còn lại
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      // Thêm text trước từ khóa
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // Thêm từ khóa được highlight
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            backgroundColor: AppColors.primary.withOpacity(0.3),
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(
        style: style ?? const TextStyle(color: Colors.black),
        children: spans,
      ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
