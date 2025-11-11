
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/group_management_viewmodel.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangxahoi/view/group_chat/add_members_view.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:intl/intl.dart'; // Import để định dạng ngày
// Thêm vào phần import của group_management_view.dart
import 'package:mangxahoi/view/group_chat/group_qr_code_view.dart';

class GroupManagementView extends StatelessWidget {
  final String groupId;

  const GroupManagementView({Key? key, required this.groupId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = context.watch<UserService>().currentUser?.id;

    return ChangeNotifierProvider(
      create: (_) => GroupManagementViewModel(
        groupId: groupId,
        currentUserId: currentUserId,
      ),
      child: const _GroupManagementContent(),
    );
  }
}

class _GroupManagementContent extends StatelessWidget {
  const _GroupManagementContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GroupManagementViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không tìm thấy nhóm')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, vm),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildGroupInfo(context, vm),
                const SizedBox(height: 12),
                _buildActionButtons(context, vm),
                const SizedBox(height: 12),
                _buildSettingsSection(context, vm),
                const SizedBox(height: 12),
                _buildMembersSection(context, vm),
                const SizedBox(height: 12),
                if (vm.isOwner) _buildDangerZone(context, vm),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, GroupManagementViewModel vm) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            vm.group!.coverImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: vm.group!.coverImage,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            if (vm.canEdit)
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: AppColors.primary),
                    onPressed: () => vm.updateCoverImage(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInfo(BuildContext context, GroupManagementViewModel vm) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vm.group!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (vm.canEdit)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    onPressed: () => _showEditGroupNameDialog(context, vm),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  vm.group!.description.isNotEmpty
                      ? vm.group!.description
                      : (vm.canEdit ? 'Thêm mô tả cho nhóm...' : 'Nhóm này chưa có mô tả.'),
                  style: TextStyle(
                    fontSize: 14,
                    color: vm.group!.description.isNotEmpty 
                        ? Colors.grey[600] 
                        : Colors.grey[400],
                    height: 1.4,
                    fontStyle: vm.group!.description.isNotEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
              if (vm.canEdit)
                Container(
                  width: 48, 
                  height: 48,
                  margin: const EdgeInsets.only(left: 8.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                    onPressed: () => _showEditGroupDescriptionDialog(context, vm), 
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column( 
              children: [
                Row( 
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded( 
                      child: _buildInfoItem(
                        Icons.people_outline,
                        '${vm.members.length}',
                        'Thành viên',
                        AppColors.primary,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded( 
                      child: _buildInfoItem(
                        vm.isPrivate ? Icons.lock_outline : Icons.public,
                        vm.isPrivate ? 'Riêng tư' : 'Công khai',
                        'Quyền riêng tư',
                        vm.isPrivate ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
                
                if (vm.group?.createdAt != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(height: 1, color: Colors.grey[300]), 
                  ),
                  _buildInfoItem(
                    Icons.calendar_today_outlined,
                    DateFormat('dd/MM/yyyy').format(vm.group!.createdAt!),
                    'Ngày tạo',
                    Colors.purple,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, GroupManagementViewModel vm) {
    final bool isMember = vm.group!.members.contains(vm.currentUserId);

    // Nếu không phải là thành viên, không hiển thị bất kỳ nút nào
    if (!isMember) {
      return const SizedBox.shrink(); // Trả về một widget rỗng
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
         Expanded(
          child: _buildActionButton(
            icon: Icons.qr_code,
            label: 'Mã QR',
            gradient: LinearGradient(
              colors: [Colors.purple[400]!, Colors.purple[600]!],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupQRCodeView(
                    group: vm.group!,
                    // SỬA LẠI DÒNG NÀY
                    currentUserName: vm.currentUser?.name ?? 'Người dùng',
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
          if (vm.canInviteMembers)
            Expanded(
              child: _buildActionButton(
                icon: Icons.person_add_outlined,
                label: 'Thêm thành viên',
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMembersView(groupId: vm.groupId),
                    ),
                  );
                },
              ),
            ),
          // if (vm.canInviteMembers) const SizedBox(width: 12),
          // Expanded(
          //   child: _buildActionButton(
          //     icon: Icons.notifications_outlined,
          //     label: 'Thông báo',
          //     gradient: LinearGradient(
          //       colors: [Colors.orange[400]!, Colors.orange[600]!],
          //     ),
          //     onPressed: () {
          //       // TODO: Implement notification settings
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, GroupManagementViewModel vm) {
    if (!vm.isOwner) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Cài đặt nhóm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildSettingTile(
            icon: Icons.lock_outline,
            iconColor: Colors.orange,
            title: 'Nhóm riêng tư',
            subtitle: 'Chỉ thành viên được mời mới có thể tham gia',
            value: vm.isPrivate,
            onChanged: vm.isOwner ? vm.togglePrivacy : null,
          ),
          Divider(height: 1, color: Colors.grey[200], indent: 72),
          _buildSettingTile(
            icon: Icons.message_outlined,
            iconColor: Colors.blue,
            title: 'Ai có thể nhắn tin',
            subtitle: vm.messagingPermission == 'all'
                ? 'Tất cả thành viên'
                : vm.messagingPermission == 'managers'
                    ? 'Chỉ quản lý'
                    : 'Chỉ chủ nhóm',
            trailing: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                onPressed: () => _showMessagingPermissionDialog(context, vm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool? value,
    ValueChanged<bool>? onChanged,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ),
      trailing: trailing ??
          (value != null
              ? Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                )
              : null),
    );
  }

  Widget _buildMembersSection(BuildContext context, GroupManagementViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thành viên (${vm.members.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Show all members
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vm.members.length > 5 ? 5 : vm.members.length,
            itemBuilder: (context, index) {
              final member = vm.members[index];
              return _buildMemberTile(context, vm, member);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    GroupManagementViewModel vm,
    UserModel member,
  ) {
    final isOwner = member.id == vm.group!.ownerId;
    final isManager = vm.group!.managers.contains(member.id);
    final isMuted = vm.mutedMembers.contains(member.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isOwner 
                    ? Colors.amber.withOpacity(0.3)
                    : isManager
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: member.avatar.isNotEmpty
                  ? NetworkImage(member.avatar.first)
                  : null,
              child: member.avatar.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
          ),
          if (isOwner)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          if (!isOwner && isManager)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          if (isMuted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text(
                'Bị tắt tiếng',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          isOwner
              ? 'Chủ nhóm'
              : isManager
                  ? 'Quản lý'
                  : 'Thành viên',
          style: TextStyle(
            fontSize: 13,
            color: isOwner
                ? Colors.amber[700]
                : isManager
                    ? AppColors.primary
                    : Colors.grey[600],
            fontWeight: isOwner || isManager ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
      trailing: vm.canManageMembers && member.id != vm.currentUserId
          ? Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton(
                icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[700]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  if (vm.isOwner && !isManager)
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                          const SizedBox(width: 12),
                          const Text('Cấp quyền quản lý'),
                        ],
                      ),
                      onTap: () => vm.promoteToManager(member.id),
                    ),
                  if (vm.isOwner && isManager && !isOwner)
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.remove_circle_outline, size: 20, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('Gỡ quyền quản lý'),
                        ],
                      ),
                      onTap: () => vm.demoteFromManager(member.id),
                    ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(
                          isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                          size: 20,
                          color: isMuted ? Colors.green : Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        Text(isMuted ? 'Bỏ tắt tiếng' : 'Tắt tiếng'),
                      ],
                    ),
                    onTap: () => vm.toggleMuteMember(member.id),
                  ),
                  if (!isOwner)
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.person_remove_outlined, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Xóa khỏi nhóm', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      onTap: () => _confirmRemoveMember(context, vm, member),
                    ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildDangerZone(BuildContext context, GroupManagementViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                SizedBox(width: 8),
                Text(
                  'Vùng nguy hiểm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.red.withOpacity(0.2)),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 22),
            ),
            title: const Text(
              'Giải tán nhóm',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Hành động này không thể hoàn tác',
                style: TextStyle(fontSize: 13),
              ),
            ),
            onTap: () => _confirmDisbandGroup(context, vm),
          ),
        ],
      ),
    );
  }

  // --- SỬA ĐỔI DIALOG TÊN NHÓM ---
  void _showEditGroupNameDialog(
      BuildContext context, GroupManagementViewModel vm) {
    final controller = TextEditingController(text: vm.group!.name);
    final formKey = GlobalKey<FormState>(); // Thêm key để validation

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đổi tên nhóm'),
        content: Form( // Bọc trong Form
          key: formKey,
          child: TextFormField( // Đổi thành TextFormField
            controller: controller,
            autofocus: true,
            validator: (value) { // Thêm validation
              if (value == null || value.trim().isEmpty) {
                return 'Tên không được để trống';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Nhập tên nhóm mới',
              filled: true, // Thêm màu nền
              fillColor: Colors.grey[100],
              border: OutlineInputBorder( // Xóa viền
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder( // Xóa viền khi enabled
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder( // Chỉ hiện viền khi focus
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              // Kiểm tra validation trước khi lưu
              if (formKey.currentState!.validate()) {
                vm.updateGroupName(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
  // --- KẾT THÚC SỬA ĐỔI ---

  // --- SỬA ĐỔI DIALOG MÔ TẢ ---
  void _showEditGroupDescriptionDialog(
      BuildContext context, GroupManagementViewModel vm) {
    final controller = TextEditingController(text: vm.group!.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sửa mô tả nhóm'),
        content: TextFormField( // Đổi thành TextFormField
          controller: controller,
          autofocus: true,
          maxLines: 5, 
          minLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập mô tả cho nhóm...',
            filled: true, // Thêm màu nền
            fillColor: Colors.grey[100],
            border: OutlineInputBorder( // Xóa viền
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder( // Xóa viền khi enabled
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder( // Chỉ hiện viền khi focus
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16), // Thêm padding
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              vm.updateGroupDescription(controller.text.trim()); 
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
  // --- KẾT THÚC SỬA ĐỔI ---

  void _showMessagingPermissionDialog(
      BuildContext context, GroupManagementViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ai có thể nhắn tin?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tất cả thành viên'),
              value: 'all',
              groupValue: vm.messagingPermission,
              activeColor: AppColors.primary,
              onChanged: (value) {
                if (value != null) vm.updateMessagingPermission(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Chỉ quản lý'),
              value: 'managers',
              groupValue: vm.messagingPermission,
              activeColor: AppColors.primary,
              onChanged: (value) {
                if (value != null) vm.updateMessagingPermission(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Chỉ chủ nhóm'),
              value: 'owner',
              groupValue: vm.messagingPermission,
              activeColor: AppColors.primary,
              onChanged: (value) {
                if (value != null) vm.updateMessagingPermission(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(
      BuildContext context, GroupManagementViewModel vm, UserModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa thành viên'),
        content: Text('Bạn có chắc muốn xóa ${member.name} khỏi nhóm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              vm.removeMember(member.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _confirmDisbandGroup(
      BuildContext context, GroupManagementViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Giải tán nhóm'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn giải tán nhóm này? Tất cả dữ liệu sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              vm.disbandGroup();
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Giải tán'),
          ),
        ],
      ),
    );
  }
}