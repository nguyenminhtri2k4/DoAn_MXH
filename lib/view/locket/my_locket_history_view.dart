
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';
import 'package:mangxahoi/request/locket_request.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:mangxahoi/view/locket/locket_viewer_view.dart'; // Import để điều hướng
import 'package:mangxahoi/model/model_user.dart'; // Import UserModel

// ViewModel cho trang lịch sử
class MyLocketHistoryViewModel extends ChangeNotifier {
  final LocketRequest _locketRequest = LocketRequest();
  List<LocketPhoto> _myPhotos = [];
  bool _isLoading = true;

  List<LocketPhoto> get myPhotos => _myPhotos;
  bool get isLoading => _isLoading;

  Future<void> fetchMyHistory(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _myPhotos = await _locketRequest.getMyLocketHistory(userId);
      print("MyLocketHistoryVM: Tải xong ${_myPhotos.length} ảnh.");
    } catch (e) {
      print("Lỗi khi tải lịch sử Locket: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  // === HÀM XÓA MỚI ===
  Future<void> deletePhoto(String photoId) async {
    try {
      await _locketRequest.deleteLocketPhotoSoft(photoId);
      // Xóa khỏi danh sách local và cập nhật UI
      _myPhotos.removeWhere((photo) => photo.id == photoId);
      notifyListeners();
    } catch (e) {
      print("Lỗi khi xóa Locket từ history: $e");
      // Có thể ném lỗi lại để UI hiển thị SnackBar lỗi
    }
  }
}

// Giao diện trang lịch sử
class MyLocketHistoryView extends StatelessWidget {
  const MyLocketHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<UserService>().currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Locket của tôi')),
        body: const Center(child: Text('Không tìm thấy người dùng.')),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => MyLocketHistoryViewModel()..fetchMyHistory(currentUser.id),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Locket của tôi'),
          backgroundColor: AppColors.backgroundLight,
        ),
        backgroundColor: AppColors.background,
        body: Consumer<MyLocketHistoryViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.myPhotos.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_back_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Bạn chưa đăng Locket nào',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Hãy chụp một tấm ảnh để bắt đầu!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: viewModel.myPhotos.length,
              itemBuilder: (context, index) {
                final photo = viewModel.myPhotos[index];
                
                return Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Stack( // <-- SỬ DỤNG STACK ĐỂ ĐẶT NÚT XÓA LÊN TRÊN
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // GestureDetector để nhấn vào vẫn xem được ảnh
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LocketViewerView(
                                    initialPhoto: photo,
                                    targetUser: currentUser, // Vì đây là lịch sử của mình
                                  ),
                                ),
                              );
                            },
                            child: CachedNetworkImage(
                              imageUrl: photo.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 350,
                              placeholder: (context, url) => Container(
                                height: 350,
                                color: AppColors.backgroundDark,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 350,
                                color: AppColors.backgroundDark,
                                child: const Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              timeago.format(photo.timestamp.toDate(), locale: 'vi'),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      // === NÚT XÓA ĐƯỢC THÊM VÀO ===
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            onPressed: () {
                              // Gọi dialog xác nhận
                              _showDeleteConfirmation(context, viewModel, photo);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // === DIALOG XÁC NHẬN XÓA ===
  void _showDeleteConfirmation(BuildContext context, MyLocketHistoryViewModel viewModel, LocketPhoto photo) {
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
                Navigator.of(dialogContext).pop(); // Đóng dialog
                try {
                  await viewModel.deletePhoto(photo.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã chuyển Locket vào thùng rác.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xóa Locket: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}