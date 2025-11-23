// FILE: group_invite_preview.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/model/model_qr_invite.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/request/group_request.dart';
import 'package:mangxahoi/notification/notification_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupInvitePreview extends StatefulWidget {
  final QRInviteData qrData;
  final String groupId;
  final bool isAlreadyMember;
  final String currentUserId;

  const GroupInvitePreview({
    required this.qrData,
    required this.groupId,
    required this.isAlreadyMember,
    required this.currentUserId,
  });

  @override
  State<GroupInvitePreview> createState() => _GroupInvitePreviewState();
}

class _GroupInvitePreviewState extends State<GroupInvitePreview> {
  bool _isLoading = false;
  final GroupRequest _groupRequest = GroupRequest();

  void _handleJoinGroup() async {
    if (widget.isAlreadyMember || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final groupDoc =
          await FirebaseFirestore.instance
              .collection('Group')
              .doc(widget.groupId)
              .get();

      if (!groupDoc.exists) {
        if (mounted)
          NotificationService().showErrorDialog(
            context: context,
            title: 'Lỗi',
            message: 'Nhóm không còn tồn tại.',
          );
        return;
      }
      final group = GroupModel.fromMap(groupDoc.id, groupDoc.data()!);
      if (group.members.contains(widget.currentUserId)) {
        if (mounted)
          NotificationService().showSuccessDialog(
            context: context,
            title: 'Thông báo',
            message: 'Bạn đã ở trong nhóm này.',
          );
        return;
      }
      await _groupRequest.joinGroup(widget.groupId, widget.currentUserId);
      if (mounted) {
        NotificationService().showSuccessDialog(
          context: context,
          title: 'Thành công',
          message: 'Đã tham gia nhóm "${widget.qrData.groupName}".',
        );
      }
    } catch (e) {
      print('Lỗi tham gia nhóm từ lời mời: $e');
      if (mounted) {
        NotificationService().showErrorDialog(
          context: context,
          title: 'Thất bại',
          message: 'Không thể tham gia nhóm. $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToGroupInfo() {
    Navigator.pushNamed(
      context,
      '/group_management',
      arguments: widget.groupId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCover = widget.qrData.groupCover?.isNotEmpty ?? false;

    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _navigateToGroupInfo,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        hasCover
                            ? CachedNetworkImageProvider(
                              widget.qrData.groupCover!,
                            )
                            : null,
                    child:
                        !hasCover ? const Icon(Icons.groups, size: 24) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.qrData.groupName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lời mời từ ${widget.qrData.inviterName}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap:
                widget.isAlreadyMember
                    ? _navigateToGroupInfo
                    : _handleJoinGroup,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(
                        widget.isAlreadyMember
                            ? 'Xem thông tin'
                            : 'Tham gia nhóm',
                        style: TextStyle(
                             color: 
                             widget.isAlreadyMember 
                             ? Colors.black87 
                             : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}