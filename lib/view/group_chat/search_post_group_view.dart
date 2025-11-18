import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/viewmodel/search_post_group_viewmodel.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPostGroupView extends StatefulWidget {
  final String groupId;
  final String groupName;

  const SearchPostGroupView({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<SearchPostGroupView> createState() => _SearchPostGroupViewState();
}

class _SearchPostGroupViewState extends State<SearchPostGroupView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Auto focus vào search field khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ Building SearchPostGroupView for group: ${widget.groupId}');

    return ChangeNotifierProvider(
      create: (_) {
        debugPrint(
          '🎨 Creating SearchPostGroupViewModel for group: ${widget.groupId}',
        );
        return SearchPostGroupViewModel(groupId: widget.groupId);
      },
      child: Consumer<SearchPostGroupViewModel>(
        builder: (context, vm, child) {
          debugPrint(
            '👀 Consumer rebuilt - isLoading: ${vm.isLoading}, results: ${vm.searchResults.length}',
          );
          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm trong ${widget.groupName}',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              _searchController.clear();
                              vm.clearSearch();
                              setState(() {}); // Update để ẩn nút clear
                            },
                          )
                          : null,
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  vm.searchPosts(value);
                  setState(() {}); // Update để hiện/ẩn nút clear
                },
                textInputAction: TextInputAction.search,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: Colors.grey[200], height: 1),
              ),
            ),
            body: _buildBody(vm),
          );
        },
      ),
    );
  }

  Widget _buildBody(SearchPostGroupViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Chưa tìm kiếm gì
    if (!vm.hasSearched) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'Tìm kiếm bài viết',
        subtitle: 'Nhập từ khóa để tìm kiếm bài viết trong nhóm',
      );
    }

    // Đã tìm kiếm nhưng không có kết quả
    if (vm.searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'Không tìm thấy kết quả',
        subtitle:
            'Không có bài viết nào phù hợp với từ khóa "${vm.searchQuery}"',
      );
    }

    // Có kết quả tìm kiếm
    return RefreshIndicator(
      onRefresh: vm.refreshSearch,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Header hiển thị số kết quả
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Tìm thấy ${vm.searchResults.length} bài viết',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Danh sách bài viết
          ...vm.searchResults.map((post) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: PostWidget(
                post: post,
                currentUserDocId: FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
