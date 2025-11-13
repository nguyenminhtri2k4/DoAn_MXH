import 'package:flutter/material.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/user_request.dart';

class TagFriendsView extends StatefulWidget {
  final List<String> friendIds;
  final List<String> previouslySelectedIds;

  const TagFriendsView({
    super.key,
    required this.friendIds,
    required this.previouslySelectedIds,
  });

  @override
  State<TagFriendsView> createState() => _TagFriendsViewState();
}

class _TagFriendsViewState extends State<TagFriendsView> {
  late List<String> _selectedIds;
  List<UserModel> _friendData = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sao chép danh sách đã chọn để có thể chỉnh sửa
    _selectedIds = List<String>.from(widget.previouslySelectedIds);
    _fetchFriendData();
  }

  Future<void> _fetchFriendData() async {
    if (widget.friendIds.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    List<UserModel> friends = [];
    final userRequest = UserRequest();

    for (String id in widget.friendIds) {
      try {
        final user = await userRequest.getUserData(id);
        if (user != null) {
          friends.add(user);
        }
      } catch (e) {
        print("Lỗi khi tải thông tin bạn bè $id: $e");
      }
    }

    if (mounted) {
      setState(() {
        _friendData = friends;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredFriends {
    if (_searchQuery.isEmpty) {
      return _friendData;
    }
    return _friendData
        .where((user) =>
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gắn thẻ bạn bè'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedIds);
            },
            child: const Text(
              'Xong',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn bè...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.backgroundDark,
                contentPadding: EdgeInsets.zero,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _buildFriendList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friendData.isEmpty) {
      return const Center(child: Text('Bạn chưa có bạn bè nào.'));
    }

    final displayedFriends = _filteredFriends;

    if (displayedFriends.isEmpty) {
      return const Center(child: Text('Không tìm thấy bạn bè nào.'));
    }

    return ListView.builder(
      itemCount: displayedFriends.length,
      itemBuilder: (context, index) {
        final friend = displayedFriends[index];
        final isSelected = _selectedIds.contains(friend.id);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedIds.add(friend.id);
              } else {
                _selectedIds.remove(friend.id);
              }
            });
          },
          secondary: CircleAvatar(
            backgroundImage: friend.avatar.isNotEmpty
                ? NetworkImage(friend.avatar.first)
                : null,
            child: friend.avatar.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(friend.name),
        );
      },
    );
  }
}