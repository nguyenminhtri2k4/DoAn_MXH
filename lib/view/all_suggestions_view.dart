import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/friends_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/friend_request_manager.dart';

class AllSuggestionsView extends StatefulWidget {
  const AllSuggestionsView({super.key});

  @override
  State<AllSuggestionsView> createState() => _AllSuggestionsViewState();
}

class _AllSuggestionsViewState extends State<AllSuggestionsView> {
  final Set<String> _sentRequests = {};
  final Set<String> _loadingRequests = {};

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendsViewModel>();
    final manager = context.read<FriendRequestManager>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Gợi ý kết bạn',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: false,
      ),
      body: SafeArea(
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : vm.suggestions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có gợi ý nào',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Icons.person_add_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Gợi ý kết bạn',
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
                                  '${vm.suggestions.length}',
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
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: vm.suggestions.length,
                              separatorBuilder: (context, index) =>
                                  Divider(
                                    color: Colors.grey[100],
                                    height: 24,
                                  ),
                              itemBuilder: (context, index) {
                                final item = vm.suggestions[index];
                                final user = item['user'] as UserModel;
                                final mutualCount =
                                    item['mutualCount'] as int;
                                final isSent = _sentRequests.contains(user.id);
                                final isLoading =
                                    _loadingRequests.contains(user.id);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/profile',
                                      arguments: user.id,
                                    );
                                  },
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.grey[100],
                                        backgroundImage:
                                            user.avatar.isNotEmpty
                                                ? NetworkImage(
                                                    user.avatar.first,
                                                  )
                                                : null,
                                        child: user.avatar.isEmpty
                                            ? Icon(
                                                Icons.person,
                                                size: 28,
                                                color: Colors.grey[400],
                                              )
                                            : null,
                                      ),
                                    ),
                                    title: Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '$mutualCount bạn chung',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    trailing: isSent
                                        ? _buildSentButton()
                                        : _buildAddButton(
                                            isLoading,
                                            () async {
                                              setState(() {
                                                _loadingRequests
                                                    .add(user.id);
                                              });

                                              try {
                                                await manager.sendRequest(
                                                  vm.currentUserDocId!,
                                                  user.id,
                                                );

                                                if (mounted) {
                                                  setState(() {
                                                    _sentRequests.add(user.id);
                                                    _loadingRequests
                                                        .remove(user.id);
                                                  });

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                          'Đã gửi lời mời kết bạn'),
                                                      backgroundColor:
                                                          Colors.green[600],
                                                      behavior:
                                                          SnackBarBehavior
                                                              .floating,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  setState(() {
                                                    _loadingRequests
                                                        .remove(user.id);
                                                  });

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                          'Lỗi khi gửi lời mời'),
                                                      backgroundColor:
                                                          Colors.red[600],
                                                      behavior:
                                                          SnackBarBehavior
                                                              .floating,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildAddButton(bool isLoading, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(70, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Thêm',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildSentButton() {
    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(70, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Text(
        'Đã gửi',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}