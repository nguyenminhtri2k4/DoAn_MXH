
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/locket_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class LocketView extends StatelessWidget {
  const LocketView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocketViewModel(), // ✅ Tự động init
      child: const _LocketViewContent(),
    );
  }
}

class _LocketViewContent extends StatelessWidget {
  const _LocketViewContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<LocketViewModel>(
      builder: (context, viewModel, child) {
        // ✅ Hiển thị loading khi đang khởi tạo
        if (viewModel.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Locket', style: TextStyle(color: AppColors.textPrimary)),
              backgroundColor: AppColors.backgroundLight,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải dữ liệu Locket...'),
                ],
              ),
            ),
          );
        }

        // ✅ Hiển thị lỗi nếu không init được
        if (!viewModel.isInitialized) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Locket', style: TextStyle(color: AppColors.textPrimary)),
              backgroundColor: AppColors.backgroundLight,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Không thể tải dữ liệu Locket'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.refreshLocketData(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ Hiển thị loading khi đang upload
        if (viewModel.isUploading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Locket', style: TextStyle(color: AppColors.textPrimary)),
              backgroundColor: AppColors.backgroundLight,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Đang gửi Locket..."),
                ],
              ),
            ),
          );
        }

        // ✅ UI chính
        final currentUserId = viewModel.currentUserId!;
        final myLatestPhoto = viewModel.latestPhotos[currentUserId];
        final friends = viewModel.locketFriends;
        final photos = viewModel.latestPhotos;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Locket', style: TextStyle(color: AppColors.textPrimary)),
            backgroundColor: AppColors.backgroundLight,
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.group_add_outlined, color: AppColors.textPrimary),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/locket_manage_friends');
                  if (context.mounted) {
                    viewModel.refreshLocketData();
                  }
                },
              ),
            ],
          ),
          body: _buildBody(friends, photos, currentUserId, myLatestPhoto),
          floatingActionButton: FloatingActionButton(
            onPressed: () => viewModel.pickAndUploadLocket(),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.camera_alt),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    List friends,
    Map<String, LocketPhoto> photos,
    String currentUserId,
    LocketPhoto? myLatestPhoto,
  ) {
    // Không có bạn bè
    if (friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Không gian Locket của bạn',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Thêm bạn bè thân thiết để bắt đầu chia sẻ khoảnh khắc.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (context) => ElevatedButton.icon(
                  icon: const Icon(Icons.group_add),
                  label: const Text('Quản lý bạn bè'),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/locket_manage_friends');
                    if (context.mounted) {
                      context.read<LocketViewModel>().refreshLocketData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }

    // Có bạn bè nhưng chưa có ảnh
    if (friends.isNotEmpty && photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_enhance_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Bắt đầu Locket ngay!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy là người đầu tiên chia sẻ khoảnh khắc của bạn với ${friends.length} người bạn thân.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Hiển thị grid
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: friends.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Ô của chính mình
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/my_locket_history');
              },
              child: LocketFriendWidget(
                name: "Bạn (Xem lịch sử)",
                avatarUrl: null, // Có thể lấy từ UserService nếu cần
                photo: myLatestPhoto,
              ),
            );
          }

          final friend = friends[index - 1];
          final photo = photos[friend.id];
          final friendAvatar = (friend.avatar.isNotEmpty) ? friend.avatar.first : null;

          return GestureDetector(
            onTap: () {
              if (photo != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenLocketView(
                      photo: photo,
                      userName: friend.name,
                    ),
                  ),
                );
              }
            },
            child: LocketFriendWidget(
              name: friend.name,
              avatarUrl: friendAvatar,
              photo: photo,
            ),
          );
        },
      ),
    );
  }
}

// Widget con để hiển thị từng ô Locket
class LocketFriendWidget extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final LocketPhoto? photo;

  const LocketFriendWidget({
    super.key,
    required this.name,
    this.avatarUrl,
    this.photo,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider displayImage = (photo != null)
        ? CachedNetworkImageProvider(photo!.imageUrl)
        : (avatarUrl != null && avatarUrl!.isNotEmpty)
            ? CachedNetworkImageProvider(avatarUrl!)
            : const AssetImage('assets/logoapp.png') as ImageProvider;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: displayImage,
                fit: BoxFit.cover,
                colorFilter: photo == null
                    ? ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken)
                    : null,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.6, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 2)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (photo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      timeago.format(photo!.timestamp.toDate(), locale: 'vi'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        shadows: [Shadow(blurRadius: 2)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget xem ảnh Locket full màn hình
class FullScreenLocketView extends StatelessWidget {
  final LocketPhoto photo;
  final String userName;

  const FullScreenLocketView({
    super.key,
    required this.photo,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Locket của $userName", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: photo.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Center(child: Icon(Icons.error, color: Colors.red)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                timeago.format(photo.timestamp.toDate(), locale: 'vi'),
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}