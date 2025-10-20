
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/viewmodel/search_view_model.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/notification/notification_service.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider( 
      create: (_) => SearchViewModel(),
      child: const _SearchViewContent(),
    );
  }
}

class _SearchViewContent extends StatelessWidget {
  const _SearchViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: AppColors.background,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Container(
                height: 40,
                child: TextField(
                  controller: vm.searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm trên Mạng Xã Hội',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: vm.searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                            onPressed: () {
                              vm.searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, SearchViewModel vm) {
    final hasQuery = vm.searchController.text.trim().isNotEmpty;
    
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)));
    }

    if (!hasQuery) {
      return Center(
        child: Text(
          'Nhập tên, email hoặc số điện thoại để tìm kiếm.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }
    
    if (vm.errorMessage != null && vm.searchResults.isEmpty) {
      return Center(child: Text(vm.errorMessage!));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0),
      itemCount: vm.searchResults.length,
      itemBuilder: (context, index) {
        final result = vm.searchResults[index];
        return _buildUserResultTile(context, result, vm);
      },
    );
  }

  Widget _buildUserResultTile(
    BuildContext context, 
    SearchUserResult result, 
    SearchViewModel vm
  ) {
    final user = result.user;
    final status = result.status;
    
    Widget actionButton;
    Color buttonColor;
    String buttonText;
    Function? onPressed;

    switch (status) {
      case 'friends':
        buttonText = 'Bạn bè';
        buttonColor = AppColors.backgroundDark;
        break;
      case 'pending_sent':
        buttonText = 'Đã gửi lời mời';
        buttonColor = AppColors.backgroundDark;
        break;
      case 'pending_received':
        buttonText = 'Phản hồi';
        buttonColor = AppColors.success; 
        onPressed = () {
          // Chuyển hướng đến trang bạn bè để xử lý
          Navigator.pushNamed(context, '/friends');
        };
        break;
      case 'self':
        buttonText = 'Hồ sơ';
        buttonColor = AppColors.primaryLight;
        break;
      case 'none':
      default:
        buttonText = 'Kết bạn';
        buttonColor = AppColors.primaryLight;
        onPressed = () async {
          final success = await vm.sendFriendRequest(user.id);

          if (success) {
            NotificationService().showSuccessDialog(
              context: context, 
              title: 'Thành công', 
              message: 'Đã gửi lời mời kết bạn đến ${user.name}!',
            );
             // Thoát trang tìm kiếm sau khi gửi thành công
            Navigator.pop(context); 
          } else {
            NotificationService().showWarningDialog(
              context: context, 
              title: 'Thất bại', 
              message: 'Không thể gửi lời mời. Có thể lời mời đã tồn tại.',
            );
          }
        };
        break;
    }

    actionButton = ElevatedButton(
      onPressed: onPressed != null ? () => onPressed!() : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: (status == 'friends' || status == 'pending_sent' || status == 'pending_received') ? AppColors.textPrimary : AppColors.textWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(100, 36),
      ),
      child: Text(buttonText),
    );

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: (user.avatar.isNotEmpty) ? NetworkImage(user.avatar.first) : null,
        child: (user.avatar.isEmpty) ? const Icon(Icons.person, size: 24) : null,
      ),
      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      //subtitle: Text(user.email.isNotEmpty ? user.email : (user.phone.isNotEmpty ? user.phone : 'Không có thông tin liên hệ')),
      trailing: actionButton,
      onTap: () {
        Navigator.pushNamed(context, '/profile', arguments: user.id);
      },
    );
  }
}