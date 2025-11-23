import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_message.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangxahoi/constant/app_colors.dart'; 

class LocationMessageBubble extends StatelessWidget {
  final MessageModel message;
  final UserModel? sender;
  final bool isMe;

  const LocationMessageBubble({
    Key? key,
    required this.message,
    required this.sender,
    required this.isMe,
  }) : super(key: key);

  Future<void> _openMap() async {
    final coords = message.content.split(',');
    if (coords.length != 2) return;

    // Tạo URL Google Maps
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=${coords[0]},${coords[1]}");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $googleMapsUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy avatar an toàn: Kiểm tra null, kiểm tra list rỗng, lấy phần tử cuối
    String? avatarUrl;
    if (sender != null && sender!.avatar.isNotEmpty) {
      avatarUrl = sender!.avatar.last;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Hiển thị Avatar nếu không phải là tôi
          if (!isMe) ...[
            if (avatarUrl != null && avatarUrl.isNotEmpty)
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(avatarUrl),
              )
            else
              const CircleAvatar(
                radius: 14,
                child: Icon(Icons.person, size: 14),
              ),
            const SizedBox(width: 8),
          ],
          
          InkWell(
            onTap: _openMap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 200, 
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Bạn có thể thay đổi màu sắc tùy theo theme của app
                color: isMe ? Colors.blue[100] : Colors.grey[200], 
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 18),
                ),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: isMe ? Colors.blue : Colors.red),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Vị trí hiện tại",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/icon/google_logo.png'), // Hoặc dùng icon bản đồ mặc định
                        fit: BoxFit.contain, 
                        opacity: 0.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.map_outlined, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Nhấn để mở Google Maps",
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}