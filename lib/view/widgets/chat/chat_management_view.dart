import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangxahoi/model/model_media.dart';
import 'package:mangxahoi/view/widgets/full_screen_image_viewer.dart';
import 'package:mangxahoi/view/widgets/full_screen_video_player.dart';

class ChatManagementView extends StatelessWidget {
  final String chatId;
  final bool isGroup;
  final String chatName;

  const ChatManagementView({
    super.key,
    required this.chatId,
    required this.isGroup,
    required this.chatName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quản lý trò chuyện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(chatName, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.normal)),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Ảnh & Video'),
              Tab(text: 'Tệp tin'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MediaTab(chatId: chatId),
            _FileTab(chatId: chatId),
          ],
        ),
      ),
    );
  }
}

// --- TAB 1: KHO ẢNH & VIDEO (DẠNG GRID) ---
class _MediaTab extends StatelessWidget {
  final String chatId;
  const _MediaTab({required this.chatId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Lấy các tin nhắn có chứa mediaIds (không rỗng)
      stream: FirebaseFirestore.instance
          .collection('Chat')
          .doc(chatId)
          .collection('messages')
          .where('mediaIds', isNotEqualTo: [])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Trích xuất tất cả mediaIds từ các tài liệu tin nhắn
        List<String> allMediaIds = [];
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final mediaIds = List<String>.from(data['mediaIds'] ?? []);
            allMediaIds.addAll(mediaIds);
          }
        }

        if (allMediaIds.isEmpty) {
          return _buildEmptyState(Icons.photo_library_outlined, 'Chưa có ảnh hoặc video nào');
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: allMediaIds.length,
          itemBuilder: (context, index) => _MediaThumbnail(mediaId: allMediaIds[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// Widget con fetch dữ liệu từng Media từ Collection 'Media'
class _MediaThumbnail extends StatelessWidget {
  final String mediaId;
  const _MediaThumbnail({required this.mediaId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Media').doc(mediaId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(color: Colors.grey[200]);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        
        // ✅ FIX: Kiểm tra nếu MediaModel có constructor từ Map
        // Nếu không, dùng cách này để tạo media object
        final mediaUrl = data['url'] as String? ?? '';
        final mediaType = data['type'] as String? ?? 'image';

        return GestureDetector(
          onTap: () {
            if (mediaType == 'image') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: mediaUrl)));
            } else if (mediaType == 'video') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenVideoPlayer(videoUrl: mediaUrl)));
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: mediaUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image),
              ),
              if (mediaType == 'video')
                const Center(child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 36)),
            ],
          ),
        );
      },
    );
  }
}

// --- TAB 2: KHO TỆP TIN (DẠNG LIST) ---
class _FileTab extends StatelessWidget {
  final String chatId;
  const _FileTab({required this.chatId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Lọc các tin nhắn có type là 'file'
      stream: FirebaseFirestore.instance
          .collection('Chat')
          .doc(chatId)
          .collection('messages')
          .where('type', isEqualTo: 'file')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insert_drive_file_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Chưa có tệp tin nào', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final fileName = data['content'] ?? 'Tệp không tên';
            final timestamp = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  // ✅ FIX: Thay .withOpacity() bằng .withValues()
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description, color: Colors.blue),
              ),
              title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
              subtitle: Text(
                '${timestamp.day}/${timestamp.month}/${timestamp.year} • ${(data['fileSize'] ?? 'N/A')}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // Logic mở file hoặc tải xuống
              },
            );
          },
        );
      },
    );
  }
}