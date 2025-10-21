// lib/view/locket/my_locket_history_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';
import 'package:mangxahoi/request/locket_request.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

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
}

// Giao diện trang lịch sử
class MyLocketHistoryView extends StatelessWidget {
  const MyLocketHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<UserService>().currentUser?.id;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Locket của tôi')),
        body: const Center(child: Text('Không tìm thấy người dùng.')),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => MyLocketHistoryViewModel()..fetchMyHistory(currentUserId),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CachedNetworkImage(
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
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          timeago.format(photo.timestamp.toDate(), locale: 'vi'),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
}