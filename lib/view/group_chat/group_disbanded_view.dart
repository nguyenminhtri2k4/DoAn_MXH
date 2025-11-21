import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:provider/provider.dart';

class GroupDisbandedView extends StatefulWidget {
  final String groupId;
  final String? groupName;

  const GroupDisbandedView({super.key, required this.groupId, this.groupName});

  @override
  State<GroupDisbandedView> createState() => _GroupDisbandedViewState();
}

class _GroupDisbandedViewState extends State<GroupDisbandedView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLeaving = false;
  Future<void> _leaveGroup() async {
    final currentUserId = context.read<UserService>().currentUser?.id;

    if (currentUserId == null) {
      _showSnackBar(
        'Không thể rời khỏi nhóm. Vui lòng thử lại.',
        isError: true,
      );
      return;
    }

    setState(() => _isLeaving = true);

    try {
      print(
        '🔄 [GroupDisbandedView] User $currentUserId đang rời nhóm ${widget.groupId}',
      );
      await _firestore.collection('User').doc(currentUserId).update({
        'groups': FieldValue.arrayRemove([widget.groupId]),
      });
      await _firestore
          .collection('User')
          .doc(currentUserId)
          .collection('disbandedGroups')
          .doc(widget.groupId)
          .delete();
      print('   ✓ Đã xóa document trong subcollection disbandedGroups');

      print('✅ [GroupDisbandedView] Rời nhóm thành công');

      if (mounted) {
        _showSnackBar('Đã rời khỏi nhóm thành công', isError: false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ [GroupDisbandedView] Lỗi khi rời nhóm: $e');
      if (mounted) {
        _showSnackBar('Lỗi khi rời nhóm. Vui lòng thử lại.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLeaving = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.groupName ?? 'này';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Nhóm đã bị giải tán',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.group_off_rounded,
                        size: 64,
                        color: Colors.red[400],
                      ),
                    ),
                    const SizedBox(height: 32),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Nhóm '),
                          TextSpan(
                            text: '"$displayName"',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const TextSpan(text: ' đã bị giải tán'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chủ nhóm đã giải tán nhóm này.\nNhấn nút bên dưới để xóa khỏi danh sách.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLeaving ? null : _leaveGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLeaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.exit_to_app, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Rời khỏi nhóm',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
