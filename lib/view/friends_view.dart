import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mangxahoi/viewmodel/friends_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_friend_request.dart';
import 'package:mangxahoi/authanet/firestore_listener.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/model/model_friend.dart';

class FriendsView extends StatelessWidget {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FriendsViewModel(context.read<FirestoreListener>()),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Bạn bè', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.background,
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.textPrimary),
                onPressed: () => Navigator.pushNamed(context, '/search'),
              ),
            ],
            bottom: const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3.0,
              tabs: [
                Tab(text: 'Gợi ý'),
                Tab(text: 'Tất cả bạn bè'),
              ],
            ),
          ),
          body: const SafeArea(
            child: TabBarView(
              children: [
                _SuggestionsTab(),
                _AllFriendsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// _SuggestionsTab và các hàm con không thay đổi
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


// Widget cho tab "Tất cả bạn bè" (ĐÃ CẬP NHẬT HOÀN TOÀN)
class _AllFriendsTab extends StatefulWidget {
  const _AllFriendsTab();

  @override
  State<_AllFriendsTab> createState() => _AllFriendsTabState();
}

class _AllFriendsTabState extends State<_AllFriendsTab> {
  final _searchController = TextEditingController();
  late Stream<List<UserModel>> _friendsStream;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));

    // Lấy viewModel và khởi tạo stream
    final vm = context.read<FriendsViewModel>();
    if (vm.currentUserDocId != null) {
      _friendsStream = _getFriendsStream(vm.currentUserDocId!);
    } else {
      // Nếu chưa có ID, tạo một stream rỗng
      _friendsStream = Stream.value([]);
    }
  }

  // Hàm tạo stream để lấy danh sách bạn bè
  Stream<List<UserModel>> _getFriendsStream(String userId) {
    final firestore = FirebaseFirestore.instance;
    final listener = context.read<FirestoreListener>();

    // Query 1: Tìm document mà user hiện tại là user1
    Stream<QuerySnapshot> stream1 = firestore
        .collection('Friend')
        .where('user1', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots();

    // Query 2: Tìm document mà user hiện tại là user2
    Stream<QuerySnapshot> stream2 = firestore
        .collection('Friend')
        .where('user2', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
    
    // Kết hợp kết quả từ hai stream
    return Stream<List<UserModel>>.multi((controller) {
      final Set<String> friendIds = {};
      
      void processSnapshots(List<QueryDocumentSnapshot> docs) {
        for (var doc in docs) {
          final friendData = FriendModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          friendIds.add(friendData.user1 == userId ? friendData.user2 : friendData.user1);
        }

        final userModels = friendIds
            .map((id) => listener.getUserById(id))
            .where((user) => user != null)
            .cast<UserModel>()
            .toList();
        userModels.sort((a,b) => a.name.compareTo(b.name));
        controller.add(userModels);
      }

      final sub1 = stream1.listen((snapshot) => processSnapshots(snapshot.docs));
      final sub2 = stream2.listen((snapshot) => processSnapshots(snapshot.docs));

      controller.onCancel = () {
        sub1.cancel();
        sub2.cancel();
      };
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _friendsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi tải danh sách bạn bè.'));
                }

                final allFriends = snapshot.data ?? [];
                final query = _searchController.text.toLowerCase();
                final filteredFriends = allFriends
                    .where((friend) => friend.name.toLowerCase().contains(query))
                    .toList();

                return Column(
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
                                    onPressed: () {},
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}