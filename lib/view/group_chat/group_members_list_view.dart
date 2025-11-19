import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/group_request.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangxahoi/constant/app_colors.dart';

class GroupMembersView extends StatefulWidget {
  final String groupId;

  const GroupMembersView({super.key, required this.groupId});

  @override
  State<GroupMembersView> createState() => _GroupMembersViewState();
}

class _GroupMembersViewState extends State<GroupMembersView> {
  final GroupRequest _groupRequest = GroupRequest();
  final UserRequest _userRequest = UserRequest();

  List<UserModel> _allMembers = [];
  List<UserModel> _filteredMembers = [];

  bool _loading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);

    final group = await _groupRequest.getGroupById(widget.groupId);
    if (group == null) {
      setState(() => _loading = false);
      return;
    }

    // Lấy toàn bộ thành viên
    List<String> userIds = {...group.managers, ...group.members}.toList();

    final users = await _userRequest.getUsersByIds(userIds);

    setState(() {
      _allMembers = users;
      _filteredMembers = users;
      _loading = false;
    });
  }

  void _filterSearch(String value) {
    setState(() {
      _searchQuery = value;
      _filteredMembers =
          _allMembers
              .where((u) => u.name.toLowerCase().contains(value.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Thành viên nhóm",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // ==== Ô tìm kiếm ====
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Tìm thành viên...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: _filterSearch,
                    ),
                  ),

                  // ==== Phần đếm số thành viên ====
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.group,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_filteredMembers.length} thành viên',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child:
                        _filteredMembers.isEmpty
                            ? const Center(
                              child: Text("Không tìm thấy thành viên"),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filteredMembers.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildMemberCard(
                                    _filteredMembers[index],
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  // ====== CARD THÀNH VIÊN (giống y FriendListView) ======
  Widget _buildMemberCard(UserModel user) {
    final hasAvatar = user.avatar.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, "/profile", arguments: user.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ==== Avatar ====
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient:
                        !hasAvatar
                            ? LinearGradient(
                              colors: [Colors.blue[400]!, Colors.blue[600]!],
                            )
                            : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child:
                        hasAvatar
                            ? CachedNetworkImage(
                              imageUrl: user.avatar.first,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => Container(color: Colors.grey[200]),
                              errorWidget:
                                  (_, __, ___) => const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                            )
                            : const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.white,
                            ),
                  ),
                ),

                const SizedBox(width: 16),

                // ==== Thông tin ====
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // ==== BIO ====
                      if (user.bio.isNotEmpty && user.bio != "No") ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user.bio,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Mũi tên
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
