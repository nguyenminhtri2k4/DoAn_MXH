import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_locket_photo.dart';
import 'package:mangxahoi/request/locket_request.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    } catch (e) {
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
      rethrow;
    }
  }

  Future<void> deletePermanently(String photoId, String imageUrl) async {
    try {
      // Truyền cả imageUrl để xóa trên Storage
      await _locketRequest.deleteLocketPhotoPermanently(photoId, imageUrl);
      // StreamBuilder sẽ tự cập nhật
    } catch (e) {
      print("Lỗi xóa vĩnh viễn Locket: $e");
      rethrow;
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
      return const Center(child: Text('Không tìm thấy người dùng.'));
    }

    return ChangeNotifierProvider(
      create: (_) => LocketTrashViewModel()..fetchDeletedPhotos(currentUserId),
      child: const _LocketTrashContent(),
    );
  }
}

class _LocketTrashContent extends StatefulWidget {
  const _LocketTrashContent();

  @override
  State<_LocketTrashContent> createState() => _LocketTrashContentState();
}

class _LocketTrashContentState extends State<_LocketTrashContent> {
  final Set<String> _selectedLocketIds = {};

  void _toggleLocketSelection(String locketId) {
    setState(() {
      if (_selectedLocketIds.contains(locketId)) {
        _selectedLocketIds.remove(locketId);
      } else {
        _selectedLocketIds.add(locketId);
      }
    });
  }

  void _selectAll(List<LocketPhoto> lockets) {
    setState(() {
      if (_selectedLocketIds.length == lockets.length) {
        _selectedLocketIds.clear();
      } else {
        _selectedLocketIds.clear();
        _selectedLocketIds.addAll(lockets.map((l) => l.id));
      }
    });
  }

  Future<void> _deleteSelectedLockets(
    LocketTrashViewModel vm,
    List<LocketPhoto> lockets,
  ) async {
    if (_selectedLocketIds.isEmpty) return;

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                // Warning message with red background
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          color: Colors.red.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bạn có chắc chắn muốn xóa vĩnh viễn ${_selectedLocketIds.length} locket?',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Xóa vĩnh viễn',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
    );

    if (confirm == true) {
      final count = _selectedLocketIds.length;
      for (final locketId in _selectedLocketIds) {
        final locket = lockets.firstWhere((l) => l.id == locketId);
        await vm.deletePermanently(locketId, locket.imageUrl);
      }
      if (mounted) {
        setState(() => _selectedLocketIds.clear());
        _showSnackBar('Đã xóa vĩnh viễn $count locket', isError: true);
      }
    }
  }

  Future<void> _restoreSelectedLockets(LocketTrashViewModel vm) async {
    if (_selectedLocketIds.isEmpty) return;

    final count = _selectedLocketIds.length;
    for (final locketId in _selectedLocketIds) {
      await vm.restorePhoto(locketId);
    }
    if (mounted) {
      setState(() => _selectedLocketIds.clear());
      _showSnackBar('Đã khôi phục $count locket');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.delete_forever : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocketTrashViewModel>();

    return vm.isLoading
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<List<LocketPhoto>>(
          stream: vm.deletedPhotosStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text('Lỗi: ${snapshot.error}'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_sweep_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Thùng rác trống',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Các locket đã xóa sẽ xuất hiện ở đây',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final deletedLockets = snapshot.data!;

            return Column(
              children: [
                // Select all bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value:
                            _selectedLocketIds.length ==
                                deletedLockets.length &&
                            deletedLockets.isNotEmpty,
                        tristate:
                            _selectedLocketIds.isNotEmpty &&
                            _selectedLocketIds.length < deletedLockets.length,
                        onChanged: (value) => _selectAll(deletedLockets),
                      ),
                      const Text(
                        'Tất cả',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedLocketIds.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.restore_rounded),
                          color: AppColors.primary,
                          onPressed: () => _restoreSelectedLockets(vm),
                          tooltip: 'Khôi phục',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_rounded),
                          color: AppColors.error,
                          onPressed:
                              () => _deleteSelectedLockets(vm, deletedLockets),
                          tooltip: 'Xóa vĩnh viễn',
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Lockets list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: deletedLockets.length,
                    itemBuilder: (context, index) {
                      final locket = deletedLockets[index];
                      final isSelected = _selectedLocketIds.contains(locket.id);

                      return _LocketCard(
                        locket: locket,
                        isSelected: isSelected,
                        onToggleSelect: () => _toggleLocketSelection(locket.id),
                        onRestore: () async {
                          await vm.restorePhoto(locket.id);
                          if (context.mounted) {
                            _showSnackBar('Đã khôi phục locket');
                          }
                        },
                        onDelete: () async {
                          final confirm = await showModalBottomSheet<bool>(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder:
                                (context) => Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 16),
                                      // Warning message with red background
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.warning_rounded,
                                                color: Colors.red.shade700,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Locket sẽ bị xóa vĩnh viễn và không thể khôi phục. Bạn có chắc chắn?',
                                                style: TextStyle(
                                                  color: Colors.red.shade900,
                                                  fontSize: 14,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Action buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              style: TextButton.styleFrom(
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                foregroundColor: Colors.black87,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Hủy',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.red.shade600,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Xóa vĩnh viễn',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(
                                              context,
                                            ).padding.bottom,
                                      ),
                                    ],
                                  ),
                                ),
                          );

                          if (confirm == true) {
                            await vm.deletePermanently(
                              locket.id,
                              locket.imageUrl,
                            );
                            if (context.mounted) {
                              _showSnackBar('Đã xóa vĩnh viễn', isError: true);
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
  }
}

// ==================== LOCKET CARD ====================
class _LocketCard extends StatelessWidget {
  final LocketPhoto locket;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _LocketCard({
    required this.locket,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onRestore,
    required this.onDelete,
  });

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with checkbox overlay
              if (locket.imageUrl.isNotEmpty)
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: locket.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error, size: 50),
                          ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : Colors.grey[400]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                    ),
                  ],
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locket Photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Đã xóa ${_getTimeAgo(locket.deletedAt!.toDate())}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey[100]),
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.restore_rounded,
                        label: 'Khôi phục',
                        color: AppColors.primary,
                        onPressed: onRestore,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.delete_forever_rounded,
                        label: 'Xóa vĩnh viễn',
                        color: AppColors.error,
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
