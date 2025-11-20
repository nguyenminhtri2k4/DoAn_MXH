import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:provider/provider.dart';

class GroupDisbandedView extends StatefulWidget {
  final String groupId;

  const GroupDisbandedView({super.key, required this.groupId});

  @override
  State<GroupDisbandedView> createState() => _GroupDisbandedViewState();
}

class _GroupDisbandedViewState extends State<GroupDisbandedView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLeaving = false;
  GroupModel? _group;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    try {
      final doc =
          await _firestore.collection('Group').doc(widget.groupId).get();
      if (doc.exists) {
        setState(() {
          _group = GroupModel.fromMap(doc.id, doc.data()!);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading group: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveGroup() async {
    final currentUserId = context.read<UserService>().currentUser?.id;

    if (currentUserId == null || _group == null) {
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
      final groupDoc =
          await _firestore.collection('Group').doc(widget.groupId).get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;
      final managers = List<String>.from(groupData['managers'] ?? []);
      final members = List<String>.from(groupData['members'] ?? []);
      final isManager = managers.contains(currentUserId);
      managers.remove(currentUserId);
      members.remove(currentUserId);
      print('   └─ Còn ${members.length} thành viên sau khi user này rời');
      if (members.isEmpty) {
        print('🔥 [GroupDisbandedView] Đây là người cuối cùng → XÓA HẲN NHÓM');
        await _firestore.collection('User').doc(currentUserId).update({
          'groups': FieldValue.arrayRemove([widget.groupId]),
        });
        print('   ✓ Đã xóa groupId khỏi User collection');
        final chatQuery =
            await _firestore
                .collection('Chat')
                .where('groupId', isEqualTo: widget.groupId)
                .get();

        for (var doc in chatQuery.docs) {
          await doc.reference.delete();
        }
        print('   ✓ Đã xóa ${chatQuery.docs.length} chat documents');
        await _firestore.collection('Group').doc(widget.groupId).delete();
        print('   ✓ Đã xóa hẳn Group document');

        print('✅ [GroupDisbandedView] Xóa nhóm hoàn tất (người cuối rời)');

        if (mounted) {
          _showSnackBar('Đã rời khỏi nhóm thành công', isError: false);
          Navigator.of(context).pop();
        }
        return;
      }
      print('   └─ Còn thành viên khác, chỉ xóa user này');

      final Map<String, dynamic> updateData = {'members': members};

      if (isManager) {
        updateData['managers'] = managers;
      }

      await _firestore
          .collection('Group')
          .doc(widget.groupId)
          .update(updateData);
      print('   ✓ Đã xóa khỏi Group collection');
      await _firestore.collection('User').doc(currentUserId).update({
        'groups': FieldValue.arrayRemove([widget.groupId]),
      });
      print('   ✓ Đã xóa groupId khỏi User collection');

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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
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
                    if (_group != null) ...[
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
                              text: '"${_group!.name}"',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            const TextSpan(text: ' đã bị giải tán'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
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
                        child:
                            _isLeaving
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
