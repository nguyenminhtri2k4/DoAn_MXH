import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/view/group_chat/group_disbanded_view.dart';
import 'package:mangxahoi/view/group_chat/group_locked_view.dart'; // Import màn hình mới

class GroupStatusCheckWidget extends StatefulWidget {
  final String groupId;
  final Widget child;

  const GroupStatusCheckWidget({
    super.key,
    required this.groupId,
    required this.child,
  });

  @override
  State<GroupStatusCheckWidget> createState() => _GroupStatusCheckWidgetState();
}

class _GroupStatusCheckWidgetState extends State<GroupStatusCheckWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _status = 'activate'; // Lưu trữ status thay vì biến bool đơn lẻ

  @override
  void initState() {
    super.initState();
    _checkGroupStatus();
  }

  Future<void> _checkGroupStatus() async {
    try {
      final doc = await _firestore.collection('Group').doc(widget.groupId).get();

      if (!doc.exists) {
        setState(() {
          _status = 'deleted';
          _isLoading = false;
        });
        return;
      }

      final group = GroupModel.fromMap(doc.id, doc.data()!);

      setState(() {
        _status = group.status;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error checking group status: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Kiểm tra các trạng thái để điều hướng UI tương ứng
    if (_status == 'deleted') {
      return GroupDisbandedView(groupId: widget.groupId);
    } 
    
    if (_status == 'hidden') {
      return GroupLockedView(groupId: widget.groupId);
    }

    return widget.child;
  }
}

class GroupStatusStreamWidget extends StatelessWidget {
  final String groupId;
  final Widget child;

  const GroupStatusStreamWidget({
    super.key,
    required this.groupId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Group')
          .doc(groupId)
          .snapshots(),
      builder: (context, snapshot) {
        // Xử lý trạng thái Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Xử lý lỗi kết nối
        if (snapshot.hasError) {
          return _buildErrorState('Lỗi khi tải thông tin nhóm');
        }

        // Xử lý khi tài liệu không tồn tại (đã bị xóa khỏi DB)
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return GroupDisbandedView(groupId: groupId);
        }

        final groupData = snapshot.data!.data() as Map<String, dynamic>?;
        if (groupData == null) {
          return _buildErrorState('Dữ liệu nhóm không hợp lệ');
        }

        final group = GroupModel.fromMap(snapshot.data!.id, groupData);

        // Logic kiểm tra trạng thái theo thời gian thực (Real-time)
        if (group.status == 'deleted') {
          return GroupDisbandedView(groupId: groupId, groupName: group.name);
        }

        if (group.status == 'hidden') {
          return GroupLockedView(groupId: groupId, groupName: group.name);
        }

        return child;
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}