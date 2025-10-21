
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/locket_request.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class LocketViewerViewModel extends ChangeNotifier {
  final LocketRequest _locketRequest = LocketRequest();
  final String targetUserId;
  late PageController pageController; // Sửa lỗi: Khai báo ở đây

  List<LocketPhoto> _photos = [];
  bool _isLoading = true;
  int _initialIndex = 0;

  List<LocketPhoto> get photos => _photos;
  bool get isLoading => _isLoading;
  int get initialIndex => _initialIndex;

  LocketViewerViewModel(this.targetUserId, LocketPhoto initialPhoto) {
    _photos.add(initialPhoto);
    pageController = PageController(initialPage: _initialIndex); // Sửa lỗi: Khởi tạo ở đây
    _loadHistory();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    _isLoading = true;
    try {
      // SỬA LỖI: Đổi tên hàm
      final history = await _locketRequest.getMyLocketHistory(targetUserId); 
      if (history.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      final initialPhotoId = _photos.first.id;
      _initialIndex = history.indexWhere((p) => p.id == initialPhotoId);
      if (_initialIndex == -1) _initialIndex = 0;

      _photos = history;
      if (pageController.hasClients && pageController.initialPage != _initialIndex) {
        pageController.jumpToPage(_initialIndex);
      } else if (!pageController.hasClients) {
        pageController = PageController(initialPage: _initialIndex);
      }
    } catch (e) {
      print("Lỗi tải lịch sử Locket Viewer: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deletePhoto(String photoId, String currentUserId) async {
    if (targetUserId != currentUserId) return;
    try {
      await _locketRequest.deleteLocketPhotoSoft(photoId);
      final deletedIndex = _photos.indexWhere((p) => p.id == photoId);
      if (deletedIndex != -1) {
        _photos.removeAt(deletedIndex);
        notifyListeners();
      }
    } catch (e) {
      print("Lỗi xóa mềm Locket: $e");
    }
  }
}

class LocketViewerView extends StatefulWidget {
  final LocketPhoto initialPhoto;
  final UserModel targetUser;

  const LocketViewerView({
    super.key,
    required this.initialPhoto,
    required this.targetUser,
  });

  @override
  State<LocketViewerView> createState() => _LocketViewerState();
}

class _LocketViewerState extends State<LocketViewerView> {
  late LocketViewerViewModel _viewModel;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = LocketViewerViewModel(widget.targetUser.id, widget.initialPhoto);
    _currentPageIndex = _viewModel.initialIndex;

    _viewModel.pageController.addListener(() {
      final newIndex = _viewModel.pageController.page?.round();
      if (newIndex != null && newIndex != _currentPageIndex) {
        setState(() {
          _currentPageIndex = newIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<UserService>().currentUser?.id;
    final bool isMyLocket = currentUserId == widget.targetUser.id;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<LocketViewerViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.photos.length <= 1) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (viewModel.photos.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.pop(context);
              });
              return const Center(child: Text("Không có ảnh nào", style: TextStyle(color: Colors.white)));
            }

            return Stack(
              children: [
                PageView.builder(
                  controller: viewModel.pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: viewModel.photos.length,
                  itemBuilder: (context, index) {
                    final photo = viewModel.photos[index];
                    return InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: photo.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white70)),
                        errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.red)),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: (widget.targetUser.avatar.isNotEmpty ? CachedNetworkImageProvider(widget.targetUser.avatar.first) : const AssetImage('assets/logoapp.png')) as ImageProvider,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.targetUser.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(blurRadius: 1)]),
                            ),
                            if (_currentPageIndex < viewModel.photos.length)
                              Text(
                                timeago.format(viewModel.photos[_currentPageIndex].timestamp.toDate(), locale: 'vi'),
                                style: const TextStyle(color: Colors.white70, fontSize: 13, shadows: [Shadow(blurRadius: 1)]),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.3)),
                      ),
                      if (isMyLocket)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                          onPressed: () {
                            if (_currentPageIndex < viewModel.photos.length) {
                              final photoToDelete = viewModel.photos[_currentPageIndex];
                              _showDeleteConfirmation(context, viewModel, photoToDelete.id, currentUserId!);
                            }
                          },
                          style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.3)),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 70,
                  right: 20,
                  child: AnimatedSmoothIndicator(
                    activeIndex: _currentPageIndex,
                    count: viewModel.photos.length,
                    axisDirection: Axis.vertical,
                    effect: const ScrollingDotsEffect(
                      dotColor: Colors.white54,
                      activeDotColor: Colors.white,
                      dotHeight: 7,
                      dotWidth: 7,
                      spacing: 10,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, LocketViewerViewModel viewModel, String photoId, String currentUserId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa Locket'),
          content: const Text('Bạn có chắc muốn xóa ảnh này không? Nó sẽ được chuyển vào thùng rác.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await viewModel.deletePhoto(photoId, currentUserId);
              },
            ),
          ],
        );
      },
    );
  }
}