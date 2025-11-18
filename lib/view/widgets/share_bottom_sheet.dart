
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/notification/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/services/user_service.dart';

class ShareBottomSheet extends StatelessWidget {
  final PostModel post;
  
  const ShareBottomSheet({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<UserService>().currentUser;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Wrap(
        children: <Widget>[
          const ListTile(
            title: Text('Chia sẻ bài viết', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dynamic_feed, color: Colors.blue),
            title: const Text('Chia sẻ lên Bảng feed'),
            onTap: () {
              Navigator.pop(context); 
              if (currentUser != null) {
                Navigator.pushNamed(
                  context,
                  '/share_post',
                  arguments: {
                    'originalPost': post,
                    'currentUser': currentUser,
                  },
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.send, color: Colors.green),
            title: const Text('Gửi trong Messenger'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/share_to_messenger',
                arguments: post,
              );
            },
          ),
           ListTile(
            leading: const Icon(Icons.link, color: Colors.grey),
            title: const Text('Sao chép liên kết'),
            onTap: () {
              Navigator.pop(context);
              NotificationService().showSuccessDialog(context: context, title: 'Thành công', message: 'Đã sao chép liên kết!');
            },
          ),
        ],
      ),
    );
  }
}