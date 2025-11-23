import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserQRMessageBubble extends StatelessWidget {
  final String qrDataString;
  final bool isMe;

  const UserQRMessageBubble({
    Key? key,
    required this.qrDataString,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse JSON
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(qrDataString);
    } catch (e) {
      return const Text('Lỗi hiển thị mã QR');
    }

    final String name = data['name'] ?? 'Người dùng';
    final String avatar = data['avatar'] ?? '';
    final String userId = data['id'] ?? '';

    return GestureDetector(
      onTap: () {
         // Khi bấm vào thẻ thì chuyển sang trang Profile
         if (userId.isNotEmpty) {
           Navigator.pushNamed(context, '/profile', arguments: userId);
         }
      },
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe ? AppColors.primary.withOpacity(0.3) : Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Avatar + Tên
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: avatar.isNotEmpty 
                      ? CachedNetworkImageProvider(avatar) 
                      : null,
                  child: avatar.isEmpty 
                      ? const Icon(Icons.person, size: 16, color: Colors.grey) 
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Mã QR nhỏ
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: qrDataString,
                version: QrVersions.auto,
                size: 150.0,
                backgroundColor: Colors.white,
                gapless: false,
              ),
            ),
            const SizedBox(height: 12),

            // Nút hành động
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Xem trang cá nhân',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}