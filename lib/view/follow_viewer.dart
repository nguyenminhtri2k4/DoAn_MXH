
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/viewmodel/follow_view_model.dart';
import 'package:mangxahoi/constant/app_colors.dart';
// Import widget danh sách mới tách ra
import 'package:mangxahoi/view/widgets/follow_list.dart';

class FollowViewer extends StatelessWidget {
  final String userId;
  final int initialIndex;

  const FollowViewer({
    super.key, 
    required this.userId, 
    this.initialIndex = 0
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FollowViewModel(userId: userId),
      child: DefaultTabController(
        length: 2,
        initialIndex: initialIndex,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0.5,
            centerTitle: true,
            leading: const BackButton(color: Colors.black87),
            title: const Text(
              'Theo dõi',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: const TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  tabs: [
                    Tab(text: 'Người theo dõi'),
                    Tab(text: 'Đang theo dõi'),
                  ],
                ),
              ),
            ),
          ),
          body: const TabBarView(
            children: [
              FollowList(isFollowers: true),
              FollowList(isFollowers: false),
            ],
          ),
        ),
      ),
    );
  }
}