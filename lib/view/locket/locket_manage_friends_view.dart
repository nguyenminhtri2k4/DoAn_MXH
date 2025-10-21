// lib/view/locket/locket_manage_friends_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/locket_request.dart';
import 'package:mangxahoi/request/user_request.dart';
import 'package:mangxahoi/services/user_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LocketManageFriendsView extends StatefulWidget {
  const LocketManageFriendsView({super.key});

  @override
  State<LocketManageFriendsView> createState() => _LocketManageFriendsViewState();
}

class _LocketManageFriendsViewState extends State<LocketManageFriendsView> {
  final LocketRequest _locketRequest = LocketRequest();
  final UserRequest _userRequest = UserRequest();

  bool _isLoading = true;
  List<UserModel> _allFriendsDetails = [];
  List<String> _locketFriendIds = [];
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<UserService>().currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.id;
      _locketFriendIds = List.from(currentUser.locketFriends); // Tạo bản sao
      _loadData(currentUser.friends);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData(List<String> allFriendIds) async {
    setState(() => _isLoading = true);
    
    List<UserModel> friendsList = [];
    // Tải song song thông tin bạn bè
    List<Future<UserModel?>> futures = allFriendIds.map((id) => _userRequest.getUserData(id)).toList();
    final results = await Future.wait(futures);
    friendsList = results.whereType<UserModel>().toList();

    setState(() {
      _allFriendsDetails = friendsList;
      _isLoading = false;
    });
  }

  void _toggleFriend(String friendId, bool isSelected) {
    if (isSelected) {
      _locketRequest.addLocketFriend(_currentUserId, friendId);
      setState(() {
        _locketFriendIds.add(friendId);
      });
      context.read<UserService>().currentUser?.locketFriends.add(friendId);

    } else {
      _locketRequest.removeLocketFriend(_currentUserId, friendId);
      setState(() {
        _locketFriendIds.remove(friendId);
      });
      context.read<UserService>().currentUser?.locketFriends.remove(friendId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Locket'),
        backgroundColor: AppColors.backgroundLight,
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allFriendsDetails.isEmpty
              ? const Center(child: Text('Bạn chưa có bạn bè nào.'))
              : ListView.builder(
                  itemCount: _allFriendsDetails.length,
                  itemBuilder: (context, index) {
                    final friend = _allFriendsDetails[index];
                    final bool isLocketFriend = _locketFriendIds.contains(friend.id);
                    final friendAvatar = (friend.avatar.isNotEmpty) ? friend.avatar.first : null;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (friendAvatar != null
                                  ? CachedNetworkImageProvider(friendAvatar)
                                  : const AssetImage('assets/logoapp.png'))
                              as ImageProvider,
                        ),
                        title: Text(friend.name, style: const TextStyle(color: AppColors.textPrimary)),
                        trailing: Checkbox(
                          value: isLocketFriend,
                          onChanged: (bool? newValue) {
                            if (newValue != null) {
                              _toggleFriend(friend.id, newValue);
                            }
                          },
                          activeColor: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}