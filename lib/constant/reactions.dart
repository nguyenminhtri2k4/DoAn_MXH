// lib/constant/reactions.dart
import 'package:flutter/material.dart';
import 'package:flutter_reaction_button/flutter_reaction_button.dart';
import 'package:mangxahoi/constant/app_colors.dart';

// 1. Định nghĩa các loại reaction
class ReactionType {
  static const String like = 'like';
  static const String love = 'love';
  static const String haha = 'haha';
  static const String wow = 'wow';
  static const String sad = 'sad';
  static const String angry = 'angry';
}

// 2. Tạo danh sách các Reaction cho UI
final List<Reaction<String>> reactions = [
  _buildReaction(ReactionType.like, 'assets/reactions/like.png', Colors.blue),
  _buildReaction(ReactionType.love, 'assets/reactions/love.png', Colors.red),
  _buildReaction(ReactionType.haha, 'assets/reactions/haha.png', Colors.yellow.shade700),
  _buildReaction(ReactionType.wow, 'assets/reactions/wow.png', Colors.yellow.shade700),
  _buildReaction(ReactionType.sad, 'assets/reactions/sad.png', Colors.yellow.shade700),
  _buildReaction(ReactionType.angry, 'assets/reactions/angry.png', Colors.red.shade800),
];

// 3. Helper widget để build từng reaction
Reaction<String> _buildReaction(String value, String imageAsset, Color color) {
  return Reaction<String>(
    value: value,
    title: _buildTitle(value),
    previewIcon: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(imageAsset, width: 40, height: 40),
    ),
    icon: _buildReactionIcon(imageAsset, color),
  );
}

// 4. Helper build title cho popup
Widget _buildTitle(String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.7),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(
      value[0].toUpperCase() + value.substring(1),
      style: const TextStyle(color: Colors.white, fontSize: 10),
    ),
  );
}

// 5. Helper build icon cho nút (khi đã chọn)
Widget _buildReactionIcon(String imageAsset, Color color) {
  if (imageAsset.contains('like')) {
    return Icon(Icons.thumb_up, color: color, size: 20);
  }
  return Image.asset(imageAsset, width: 24, height: 24);
}

// 6. Helper để lấy Text cho nút khi đã chọn
Text getReactionText(String? reactionType) {
  switch (reactionType) {
    case ReactionType.like:
      return const Text('Thích', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600));
    case ReactionType.love:
      return const Text('Yêu thích', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600));
    case ReactionType.haha:
      return Text('Haha', style: TextStyle(color: Colors.yellow.shade700, fontSize: 13, fontWeight: FontWeight.w600));
    case ReactionType.wow:
      return Text('Wow', style: TextStyle(color: Colors.yellow.shade700, fontSize: 13, fontWeight: FontWeight.w600));
    case ReactionType.sad:
      return Text('Buồn', style: TextStyle(color: Colors.yellow.shade700, fontSize: 13, fontWeight: FontWeight.w600));
    case ReactionType.angry:
      return Text('Phẫn nộ', style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w600));
    default:
      return const Text('Thích', style: TextStyle(color: AppColors.textSecondary, fontSize: 13));
  }
}

// 7. Helper để lấy Icon cho nút khi đã chọn
Widget getReactionIcon(String? reactionType, {double size = 20}) {
  String imageAsset;
  
  switch (reactionType) {
    case ReactionType.like:
      return Icon(Icons.thumb_up, color: Colors.blue, size: size);
    case ReactionType.love:
      imageAsset = 'assets/reactions/love.png';
      break;
    case ReactionType.haha:
      imageAsset = 'assets/reactions/haha.png';
      break;
    case ReactionType.wow:
      imageAsset = 'assets/reactions/wow.png';
      break;
    case ReactionType.sad:
      imageAsset = 'assets/reactions/sad.png';
      break;
    case ReactionType.angry:
      imageAsset = 'assets/reactions/angry.png';
      break;
    default:
      return Icon(Icons.thumb_up_outlined, color: AppColors.textSecondary, size: size);
  }
  return Image.asset(imageAsset, width: size, height: size);
}

// 8. Lấy label text thuần cho reaction (dùng trong subtitle)
String getReactionLabel(String? reactionType) {
  switch (reactionType) {
    case ReactionType.like:
      return 'Thích';
    case ReactionType.love:
      return 'Yêu thích';
    case ReactionType.haha:
      return 'Haha';
    case ReactionType.wow:
      return 'Wow';
    case ReactionType.sad:
      return 'Buồn';
    case ReactionType.angry:
      return 'Phẫn nộ';
    default:
      return 'Thích';
  }
}

// 9. Lấy màu của reaction theo type
Color getReactionColor(String? reactionType) {
  switch (reactionType) {
    case ReactionType.like:
      return Colors.blue;
    case ReactionType.love:
      return Colors.red;
    case ReactionType.haha:
    case ReactionType.wow:
    case ReactionType.sad:
      return Colors.yellow.shade700;
    case ReactionType.angry:
      return Colors.red.shade800;
    default:
      return AppColors.textSecondary;
  }
}