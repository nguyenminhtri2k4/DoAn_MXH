import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/view/group_chat/group_disbanded_view.dart';

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
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    _checkGroupStatus();
  }

  Future<void> _checkGroupStatus() async {
    try {
      final doc =
          await _firestore.collection('Group').doc(widget.groupId).get();

      if (!doc.exists) {
        setState(() {
          _isDeleted = true;
          _isLoading = false;
        });
        return;
      }

      final group = GroupModel.fromMap(doc.id, doc.data()!);

      setState(() {
        _isDeleted = group.status == 'deleted';
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
    if (_isDeleted) {
      return GroupDisbandedView(groupId: widget.groupId);
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
      stream:
          FirebaseFirestore.instance
              .collection('Group')
              .doc(groupId)
              .snapshots(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi khi tải thông tin nhóm',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy nhóm',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }
        final groupData = snapshot.data!.data() as Map<String, dynamic>?;
        if (groupData == null) {
          return const Scaffold(
            body: Center(child: Text('Dữ liệu nhóm không hợp lệ')),
          );
        }

        final group = GroupModel.fromMap(snapshot.data!.id, groupData);
        if (group.status == 'deleted') {
          return GroupDisbandedView(groupId: groupId);
        }
        return child;
      },
    );
  }
}
