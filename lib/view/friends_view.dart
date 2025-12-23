
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/viewmodel/friends_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_friend_request.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_friend.dart';
import 'package:mangxahoi/request/friend_request_manager.dart';
import 'package:mangxahoi/view/all_suggestions_view.dart';


class FriendsView extends StatefulWidget {
  final int initialIndex;

  const FriendsView({super.key, this.initialIndex = 0});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FriendRequestManager>(create: (_) => FriendRequestManager()),
        ChangeNotifierProvider(
          create:
              (context) => FriendsViewModel(context.read<FirestoreListener>()),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Bạn bè',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primary,
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 26,
              ),
              onPressed: () => Navigator.pushNamed(context, '/search'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabChip(
                        label: 'Gợi ý',
                        icon: Icons.person_add_outlined,
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabChip(
                        label: 'Bạn bè',
                        icon: Icons.people_outline,
                        isSelected: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: const [_SuggestionsTab(), _AllFriendsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsTab extends StatelessWidget {
  const _SuggestionsTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();

    return vm.isLoading
        ? const Center(child: CircularProgressIndicator())
        : (vm.incomingRequestsStream == null)
            ? const Center(child: Text('Đang chờ dữ liệu người dùng...'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. PHẦN GỢI Ý BẠN BÈ (Chỉ hiện nếu có gợi ý)
                    if (vm.suggestions.isNotEmpty) ...[
                      _buildSuggestionsSection(context, vm),
                      const SizedBox(height: 20),
                    ],

                    // 2. PHẦN LỜI MỜI KẾT BẠN (ĐẾN)
                    _buildRequestSection(
                      context,
                      title: 'Lời mời kết bạn',
                      icon: Icons.person_add_alt_1_rounded,
                      stream: vm.incomingRequestsStream!,
                      vm: vm,
                      isIncoming: true,
                    ),
                    const SizedBox(height: 20),

                    // 3. PHẦN LỜI MỜI ĐÃ GỬI (ĐI)
                    _buildRequestSection(
                      context,
                      title: 'Lời mời đã gửi',
                      icon: Icons.send_rounded,
                      stream: vm.sentRequestsStream!,
                      vm: vm,
                      isIncoming: false,
                    ),
                  ],
                ),
              );
  }

  // --- WIDGET GỢI Ý (HIỆN 3 ĐỨA) ---
  Widget _buildSuggestionsSection(BuildContext context, FriendsViewModel vm) {
    final displayList = vm.suggestions.take(3).toList();
    // Lấy manager hiện tại từ context trước khi chuyển trang
    final manager = context.read<FriendRequestManager>();

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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gợi ý kết bạn',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50)),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    // SỬA TẠI ĐÂY: Bao bọc trang mới bằng MultiProvider.value
                    builder: (_) => MultiProvider(
                      providers: [
                        ChangeNotifierProvider.value(value: vm),
                        Provider.value(value: manager),
                      ],
                      child: const AllSuggestionsView(),
                    ),
                  ),
                ),
                child: const Text('Xem thêm'),
              ),
            ],
          ),
          const Divider(),
          ...displayList.map((item) {
            final user = item['user'] as UserModel;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () =>
                  Navigator.pushNamed(context, '/profile', arguments: user.id),
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: user.avatar.isNotEmpty
                      ? NetworkImage(user.avatar.first)
                      : null,
                  child: user.avatar.isEmpty ? const Icon(Icons.person) : null,
                ),
              ),
              title: Text(user.name,
                  style:
                      const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
              subtitle: Text('${item['mutualCount']} bạn chung',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              trailing: ElevatedButton(
                onPressed: () => manager.sendRequest(vm.currentUserDocId!, user.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(70, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Thêm',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- WIDGET HIỂN THỊ CÁC SECTION LỜI MỜI ---
  Widget _buildRequestSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Stream<List<FriendRequestModel>> stream,
    required FriendsViewModel vm,
    required bool isIncoming,
  }) {
    final listener = context.read<FirestoreListener>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<FriendRequestModel>>(
            stream: stream,
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: count > 0 ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(color: count > 0 ? AppColors.primary : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 16),
          StreamBuilder<List<FriendRequestModel>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(strokeWidth: 2)));
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(isIncoming ? 'Không có lời mời kết bạn nào' : 'Bạn chưa gửi lời mời nào',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ),
                );
              }
              return Column(
                children: requests.map((request) {
                  final targetUserId = isIncoming ? request.fromUserId : request.toUserId;
                  final user = listener.getUserById(targetUserId);
                  return _buildRequestTile(context, request, user, vm, isIncoming);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGET TỪNG DÒNG LỜI MỜI ---
  Widget _buildRequestTile(
    BuildContext context,
    FriendRequestModel request,
    UserModel? user,
    FriendsViewModel vm,
    bool isIncoming,
  ) {
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: user.id,
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[100],
              backgroundImage: user.avatar.isNotEmpty ? NetworkImage(user.avatar.first) : null,
              child: user.avatar.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(isIncoming ? 'Muốn kết bạn' : 'Đang chờ phản hồi', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isIncoming) ...[
              ElevatedButton(
                onPressed: () => vm.acceptRequest(request),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Chấp nhận', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => vm.rejectOrCancelRequest(request.id),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(60, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Xóa', style: TextStyle(fontSize: 12)),
              ),
            ] else
              OutlinedButton(
                onPressed: () => vm.rejectOrCancelRequest(request.id),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Hủy', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _AllFriendsTab extends StatefulWidget {
  const _AllFriendsTab();

  @override
  State<_AllFriendsTab> createState() => _AllFriendsTabState();
}

class _AllFriendsTabState extends State<_AllFriendsTab> {
  final _searchController = TextEditingController();

  void _showFriendOptions(BuildContext context, UserModel friend) {
    final vm = context.read<FriendsViewModel>();
    final friendRequestManager = context.read<FriendRequestManager>();
    final listener = context.read<FirestoreListener>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_remove_outlined,
                    color: Colors.red,
                  ),
                ),
                title: const Text(
                  'Hủy kết bạn',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await friendRequestManager.unfriend(
                    vm.currentUserDocId!,
                    friend.id,
                  );
                  listener.updateLocalFriendship(
                    vm.currentUserDocId!,
                    friend.id,
                    false,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã hủy kết bạn với ${friend.name}'),
                        backgroundColor: Colors.green[600],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.block_outlined,
                    color: Colors.black87,
                  ),
                ),
                title: Text(
                  'Chặn ${friend.name}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await friendRequestManager.blockUser(
                    vm.currentUserDocId!,
                    friend.id,
                  );
                  listener.updateLocalFriendship(
                    vm.currentUserDocId!,
                    friend.id,
                    false,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã chặn ${friend.name}'),
                        backgroundColor: Colors.orange[600],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();
    final listener = context.watch<FirestoreListener>();

    if (vm.currentUserDocId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentUser = listener.getUserById(vm.currentUserDocId!);

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final friendIds = currentUser.friends;

    final allFriends =
        friendIds
            .map((id) => listener.getUserById(id))
            .where((user) => user != null)
            .cast<UserModel>()
            .toList();

    final query = _searchController.text.toLowerCase();
    final filteredFriends =
        allFriends
            .where((friend) => friend.name.toLowerCase().contains(query))
            .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn bè...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey[400],
                  size: 24,
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.people,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tất cả bạn bè',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${allFriends.length}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[200], height: 1),
                  const SizedBox(height: 16),
                  Expanded(
                    child:
                        filteredFriends.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    query.isEmpty
                                        ? Icons.people_outline
                                        : Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    query.isEmpty
                                        ? 'Chưa có bạn bè'
                                        : 'Không tìm thấy "$query"',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: filteredFriends.length,
                              separatorBuilder:
                                  (context, index) => Divider(
                                    color: Colors.grey[100],
                                    height: 24,
                                  ),
                              itemBuilder: (context, index) {
                                final friend = filteredFriends[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/profile',
                                      arguments: friend.id,
                                    );
                                  },
                                  leading: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.grey[100],
                                      backgroundImage:
                                          friend.avatar.isNotEmpty
                                              ? NetworkImage(
                                                friend.avatar.first,
                                              )
                                              : null,
                                      child:
                                          friend.avatar.isEmpty
                                              ? Icon(
                                                Icons.person,
                                                size: 28,
                                                color: Colors.grey[400],
                                              )
                                              : null,
                                    ),
                                  ),
                                  title: Text(
                                    friend.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle:
                                      friend.bio.isNotEmpty
                                          ? Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              friend.bio,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                          : null,
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed:
                                        () =>
                                            _showFriendOptions(context, friend),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}