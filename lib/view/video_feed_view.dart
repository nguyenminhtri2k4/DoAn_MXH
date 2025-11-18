
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
// import 'package:mangxahoi/viewmodel/home_view_model.dart'; // <-- SỬA LỖI: Xóa
import 'package:mangxahoi/viewmodel/video_feed_view_model.dart';
import 'package:mangxahoi/services/user_service.dart';
// Import widget mới vừa tạo
import 'package:mangxahoi/view/widgets/tiktok_video_item.dart';

class VideoFeedView extends StatelessWidget {
  const VideoFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoFeedViewModel(),
      child: const _VideoFeedBody(),
    );
  }
}

class _VideoFeedBody extends StatefulWidget {
  const _VideoFeedBody();

  @override
  State<_VideoFeedBody> createState() => _VideoFeedBodyState();
}

class _VideoFeedBodyState extends State<_VideoFeedBody> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  // --- SỬA LỖI: Xóa HomeViewModel ---
  // late HomeViewModel _homeViewModel; 
  
  // Controller cho PageView
  final PageController _pageController = PageController();
  int _focusedIndex = 0; // Theo dõi video nào đang được hiển thị

  @override
  void initState() {
    super.initState();
    // --- SỬA LỖI: Xóa toàn bộ logic khỏi initState ---
    // (VideoFeedViewModel giờ sẽ tự động tải)
  }

  @override
  void dispose() {
    // --- SỬA LỖI: Xóa listener ---
    // _homeViewModel.removeListener(_onHomeDataChanged);
    _pageController.dispose();
    super.dispose();
  }

  // --- SỬA LỖI: Xóa hàm này ---
  // void _onHomeDataChanged() {
  //   ...
  // }

  // Hàm xử lý khi lướt sang video khác
  void _onPageChanged(int index) {
    setState(() {
      _focusedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // --- SỬA LỖI: Chỉ cần watch 2 provider này ---
    final userService = context.watch<UserService>();
    final videoVM = context.watch<VideoFeedViewModel>(); 
    final currentUser = userService.currentUser;

    // --- SỬA LỖI: currentUser có thể null lúc ban đầu, nhưng videoVM cũng cần nó.
    // Chúng ta sẽ dựa vào isLoading của videoVM, vì nó cũng kiểm tra currentUser.
    if (videoVM.isLoading && videoVM.videoPosts.isEmpty) {
       return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    // --- SỬA LỖI: Đã chuyển sang kiểm tra trong videoVM.isLoading ---
    // if (currentUser == null) {
    //   return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    // }

    return Scaffold(
      // Nền đen cho trải nghiệm xem video tốt hơn
      backgroundColor: Colors.black, 
      // Mở rộng body ra sau AppBar (nếu có)
      extendBodyBehindAppBar: true, 
      // --- SỬA LỖI: Logic tải đã nằm trong videoVM ---
      body: videoVM.videoPosts.isEmpty
              ? _buildEmptyState()
              // SỬ DỤNG PAGEVIEW THAY VÌ LISTVIEW
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical, // Lướt dọc
                  itemCount: videoVM.videoPosts.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final post = videoVM.videoPosts[index];
                    return TikTokVideoItem(
                      // Key quan trọng để tránh lỗi khi danh sách thay đổi
                      key: ValueKey('tiktok_post_${post.id}'),
                      post: post,
                      // Lấy currentUserId từ videoVM (an toàn hơn)
                      currentUserDocId: videoVM.currentUserId ?? '', 
                      // Chỉ video đang hiển thị mới được play
                      isFocused: index == _focusedIndex,
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_outlined, size: 80, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          const Text(
            'Không có video nào để xem',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}