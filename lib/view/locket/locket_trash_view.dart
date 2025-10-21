
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';
import 'package:mangxahoi/request/locket_request.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

// ViewModel cho thùng rác Locket
class LocketTrashViewModel extends ChangeNotifier {
  final LocketRequest _locketRequest = LocketRequest();
  Stream<List<LocketPhoto>>? _deletedPhotosStream;
  bool _isLoading = true;

  Stream<List<LocketPhoto>>? get deletedPhotosStream => _deletedPhotosStream;
  bool get isLoading => _isLoading;

  Future<void> fetchDeletedPhotos(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _deletedPhotosStream = _locketRequest.getDeletedLocketPhotos(userId);
    } catch(e) {
      print("Lỗi tải Locket đã xóa: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> restorePhoto(String photoId) async {
    try {
      await _locketRequest.restoreLocketPhoto(photoId);
      // StreamBuilder sẽ tự cập nhật
    } catch (e) {
      print("Lỗi khôi phục Locket: $e");
    }
  }

  Future<void> deletePermanently(String photoId, String imageUrl) async {
    try {
      // Truyền cả imageUrl để xóa trên Storage
      await _locketRequest.deleteLocketPhotoPermanently(photoId, imageUrl);
      // StreamBuilder sẽ tự cập nhật
    } catch (e) {
      print("Lỗi xóa vĩnh viễn Locket: $e");
    }
  }
}

// Giao diện thùng rác Locket
class LocketTrashView extends StatelessWidget {
  const LocketTrashView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<UserService>().currentUser?.id;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thùng rác Locket')),
        body: const Center(child: Text('Không tìm thấy người dùng.')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => LocketTrashViewModel()..fetchDeletedPhotos(currentUserId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thùng rác Locket'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        backgroundColor: AppColors.background,
        body: Consumer<LocketTrashViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<List<LocketPhoto>>(
              stream: viewModel.deletedPhotosStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Thùng rác Locket trống.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final deletedPhotos = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: deletedPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = deletedPhotos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 9/16, // Tỷ lệ phổ biến của ảnh Locket
                              child: CachedNetworkImage(
                                imageUrl: photo.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.red)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              // Đảm bảo photo.deletedAt không null
                              'Đã xóa: ${photo.deletedAt != null ? timeago.format(photo.deletedAt!.toDate(), locale: 'vi') : 'Không rõ'}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.restore_from_trash, color: AppColors.primary),
                                  label: const Text('Khôi phục', style: TextStyle(color: AppColors.primary)),
                                  onPressed: () async {
                                    await viewModel.restorePhoto(photo.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã khôi phục Locket.')),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_forever, color: AppColors.error),
                                  label: const Text('Xóa vĩnh viễn', style: TextStyle(color: AppColors.error)),
                                  onPressed: () async {
                                    // Thêm dialog xác nhận
                                    _showPermanentDeleteConfirmation(context, viewModel, photo.id, photo.imageUrl);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Hàm hiển thị dialog xác nhận xóa vĩnh viễn
  void _showPermanentDeleteConfirmation(BuildContext context, LocketTrashViewModel viewModel, String photoId, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xóa vĩnh viễn'),
          content: const Text('Bạn có chắc muốn xóa vĩnh viễn Locket này không? Hành động này không thể hoàn tác.'),
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
                Navigator.of(dialogContext).pop(); // Đóng dialog trước
                await viewModel.deletePermanently(photoId, imageUrl); // Truyền cả imageUrl
                 if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa vĩnh viễn Locket.')),
                      );
                    }
              },
            ),
          ],
        );
      },
    );
  }
}