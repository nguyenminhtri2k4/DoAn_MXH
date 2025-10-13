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

class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FriendRequestManager>(create: (_) => FriendRequestManager()),
        ChangeNotifierProvider(
          create: (context) => FriendsViewModel(context.read<FirestoreListener>()),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Bạn bè', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.background,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
              onPressed: () => Navigator.pushNamed(context, '/search'),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Custom Chip-style Tab Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabChip(
                        label: 'Gợi ý',
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      const SizedBox(width: 10),
                      _buildTabChip(
                        label: 'Bạn bè',
                        isSelected: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab Content
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: const [
                    _SuggestionsTab(),
                    _AllFriendsTab(),
                  ],
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
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
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
                    _buildRequestSection(
                      context,
                      title: 'Lời mời kết bạn',
                      stream: vm.incomingRequestsStream!,
                      vm: vm,
                      isIncoming: true,
                    ),
                    const SizedBox(height: 20),
                    _buildRequestSection(
                      context,
                      title: 'Lời mời đã gửi',
                      stream: vm.sentRequestsStream!,
                      vm: vm,
                      isIncoming: false,
                    ),
                  ],
                ),
              );
  }
  
  Widget _buildRequestSection(
    BuildContext context, {
    required String title,
    required Stream<List<FriendRequestModel>> stream,
    required FriendsViewModel vm,
    required bool isIncoming,
  }) {
    final listener = context.read<FirestoreListener>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<FriendRequestModel>>(
            stream: stream,
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Text('$title ($count)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (count > 0 && isIncoming) 
                          TextButton(onPressed: () {}, child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primary))),
                  ],
              );
            }
        ),
        const Divider(),
        StreamBuilder<List<FriendRequestModel>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(isIncoming ? 'Bạn không có lời mời kết bạn nào.' : 'Bạn chưa gửi lời mời kết bạn nào.', style: TextStyle(color: Colors.grey[600])),
              );
            }
            
            return Column(
              children: requests.map((request) {
                final targetUserId = isIncoming ? request.fromUserId : request.toUserId; 
                final user = listener.getUserById(targetUserId);

                return _buildRequestTile(
                  context,
                  request,
                  user,
                  vm,
                  isIncoming,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRequestTile(
    BuildContext context,
    FriendRequestModel request,
    UserModel? user,
    FriendsViewModel vm,
    bool isIncoming,
  ) {
    if (user == null) {
      return const ListTile(
        leading: CircleAvatar(radius: 30, child: Icon(Icons.person)),
        title: Text('Đang tải thông tin...', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Vui lòng chờ'),
      ); 
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: user.avatar.isNotEmpty ? NetworkImage(user.avatar.first) : null,
            child: user.avatar.isEmpty ? const Icon(Icons.person, size: 30) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  user.bio.isNotEmpty ? user.bio : (isIncoming ? 'Gửi lời mời kết bạn' : 'Chờ chấp nhận'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          isIncoming
              ? Row(
                  children: [
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => vm.acceptRequest(request),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text('Chấp nhận'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () => vm.rejectOrCancelRequest(request.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.divider),
                          backgroundColor: AppColors.backgroundDark,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text('Xóa'),
                      ),
                    ),
                  ],
                )
              : SizedBox( 
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => vm.rejectOrCancelRequest(request.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      backgroundColor: AppColors.backgroundDark,
                    ),
                    child: const Text('Hủy lời mời'),
                  ),
                ),
        ],
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

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.red),
              title: const Text('Hủy kết bạn'),
              onTap: () async {
                Navigator.pop(context);
                await friendRequestManager.unfriend(vm.currentUserDocId!, friend.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã hủy kết bạn với ${friend.name}')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.black),
              title: Text('Chặn ${friend.name}'),
              onTap: () async {
                Navigator.pop(context);
                await friendRequestManager.blockUser(vm.currentUserDocId!, friend.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã chặn ${friend.name}')),
                  );
                }
              },
            ),
          ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('User').doc(vm.currentUserDocId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return const Expanded(child: Center(child: Text('Lỗi tải danh sách bạn bè.')));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Expanded(child: Center(child: Text('Không tìm thấy dữ liệu người dùng.')));
              }

              final currentUser = UserModel.fromFirestore(snapshot.data!);
              final friendIds = currentUser.friends;

              final allFriends = friendIds
                  .map((id) => listener.getUserById(id))
                  .where((user) => user != null)
                  .cast<UserModel>()
                  .toList();
                  
              final query = _searchController.text.toLowerCase();
              final filteredFriends = allFriends
                  .where((friend) => friend.name.toLowerCase().contains(query))
                  .toList();

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${allFriends.length} bạn bè',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Sắp xếp', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filteredFriends.isEmpty
                          ? Center(
                              child: Text(
                                query.isEmpty
                                    ? 'Bạn chưa có người bạn nào.'
                                    : 'Không tìm thấy bạn bè nào có tên "$query"',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filteredFriends.length,
                              itemBuilder: (context, index) {
                                final friend = filteredFriends[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: friend.avatar.isNotEmpty ? NetworkImage(friend.avatar.first) : null,
                                    child: friend.avatar.isEmpty ? const Icon(Icons.person, size: 28, color: Colors.grey) : null,
                                  ),
                                  title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.more_horiz),
                                    onPressed: () => _showFriendOptions(context, friend),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}