
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:mangxahoi/model/model_group.dart';
// // import 'package:mangxahoi/model/model_post.dart';
// // import 'package:mangxahoi/constant/app_colors.dart';
// // import 'package:mangxahoi/viewmodel/post_group_viewmodel.dart';
// // import 'package:mangxahoi/view/widgets/post_widget.dart';
// // import 'package:mangxahoi/model/model_user.dart';

// // // --- IMPORT MỚI ĐỂ ĐIỀU HƯỚNG ---
// // import 'package:mangxahoi/view/group_chat/add_members_view.dart';
// // // ---------------------------------

// // class PostGroupView extends StatelessWidget {
// //   final GroupModel group;

// //   const PostGroupView({super.key, required this.group});

// //   @override
// //   Widget build(BuildContext context) {
// //     return ChangeNotifierProvider(
// //       create: (_) => PostGroupViewModel(group: group),
// //       child: const _PostGroupViewContent(),
// //     );
// //   }
// // }

// // class _PostGroupViewContent extends StatelessWidget {
// //   const _PostGroupViewContent();

// //   @override
// //   Widget build(BuildContext context) {
// //     final vm = context.watch<PostGroupViewModel>();

// //     return Scaffold(
// //       backgroundColor: AppColors.background,
// //       body: vm.isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : NestedScrollView(
// //               headerSliverBuilder: (context, innerBoxIsScrolled) {
// //                 return [
// //                   SliverAppBar(
// //                     expandedHeight: 250.0,
// //                     floating: false,
// //                     pinned: true,
// //                     backgroundColor: AppColors.backgroundLight,
// //                     foregroundColor: AppColors.textPrimary,
                    
// //                     // --- THÊM NÚT MỚI VÀO ĐÂY ---
// //                     actions: [
// //                       IconButton(
// //                         icon: const Icon(Icons.person_add),
// //                         onPressed: () {
// //                           // Điều hướng đến màn hình AddMembersView
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(
// //                               builder: (_) => AddMembersView(groupId: vm.group.id),
// //                             ),
// //                           );
// //                         },
// //                       ),
// //                     ],
// //                     // ---------------------------------

// //                     flexibleSpace: FlexibleSpaceBar(
// //                       title: Text(
// //                         vm.group.name,
// //                         style: const TextStyle(
// //                           color: AppColors.textPrimary,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                       background: Container(
// //                         decoration: BoxDecoration(
// //                           gradient: LinearGradient(
// //                             colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
// //                             begin: Alignment.topLeft,
// //                             end: Alignment.bottomRight,
// //                           ),
// //                         ),
// //                         child: const Icon(
// //                           Icons.groups,
// //                           size: 80,
// //                           color: Colors.white,
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ];
// //               },
// //               body: _buildBodyWithPosts(context, vm),
// //             ),
// //     );
// //   }

// //   Widget _buildBodyWithPosts(BuildContext context, PostGroupViewModel vm) {
// //     if (vm.currentUserData == null) {
// //       return const Center(child: Text("Không thể tải dữ liệu người dùng"));
// //     }

// //     return Container(
// //       color: AppColors.background,
// //       child: StreamBuilder<List<PostModel>>(
// //         stream: vm.postsStream,
// //         builder: (context, snapshot) {
// //           if (snapshot.connectionState == ConnectionState.waiting) {
// //             return const Center(child: CircularProgressIndicator());
// //           }
// //           if (snapshot.hasError) {
// //             return Center(child: Text('Lỗi tải bài viết: ${snapshot.error}'));
// //           }

// //           final posts = snapshot.data ?? [];

// //           return ListView(
// //             padding: const EdgeInsets.all(8.0),
// //             children: [
// //               _buildCreatePostSection(context, vm),
// //               if (posts.isNotEmpty)
// //                 const Padding(
// //                   padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
// //                   child: Text('Bài viết trong nhóm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
// //                 ),
// //               if (posts.isEmpty)
// //                 const Padding(
// //                   padding: EdgeInsets.only(top: 50.0),
// //                   child: Center(child: Text("Chưa có bài viết nào trong nhóm.")),
// //                 ),
// //               ...posts.map((post) => PostWidget(
// //                     post: post,
// //                     currentUserDocId: vm.currentUserData!.id,
// //                   )).toList(),
// //             ],
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   Widget _buildCreatePostSection(BuildContext context, PostGroupViewModel vm) {
// //     return Card(
// //       color: Colors.white,
// //       margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
// //       elevation: 1,
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //       child: Padding(
// //         padding: const EdgeInsets.all(12.0),
// //         child: InkWell(
// //           onTap: () {
// //             // Sửa đổi cách truyền tham số để nó là một Map
// //             Navigator.pushNamed(
// //               context,
// //               '/create_post',
// //               arguments: {
// //                 'currentUser': vm.currentUserData!,
// //                 'groupId': vm.group.id,
// //               },
// //             );
// //           },
// //           child: Row(
// //             children: [
// //               CircleAvatar(
// //                 backgroundImage: vm.currentUserData!.avatar.isNotEmpty
// //                     ? NetworkImage(vm.currentUserData!.avatar.first)
// //                     : null,
// //                 child: vm.currentUserData!.avatar.isEmpty ? const Icon(Icons.person) : null,
// //               ),
// //               const SizedBox(width: 12),
// //               const Expanded(
// //                 child: Text(
// //                   'Viết gì đó trong nhóm...',
// //                   style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
// //                 ),
// //               ),
// //               const Icon(Icons.edit, color: AppColors.primary),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:mangxahoi/model/model_group.dart';
// import 'package:mangxahoi/model/model_post.dart';
// import 'package:mangxahoi/constant/app_colors.dart';
// import 'package:mangxahoi/viewmodel/post_group_viewmodel.dart';
// import 'package:mangxahoi/view/widgets/post_widget.dart';
// import 'package:mangxahoi/model/model_user.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:mangxahoi/view/group_chat/add_members_view.dart';
// import 'package:mangxahoi/view/group_chat/group_management_view.dart';

// class PostGroupView extends StatelessWidget {
//   final GroupModel group;

//   const PostGroupView({super.key, required this.group});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => PostGroupViewModel(group: group),
//       child: const _PostGroupViewContent(),
//     );
//   }
// }

// class _PostGroupViewContent extends StatelessWidget {
//   const _PostGroupViewContent();

//   // Helper method để check xem nhóm có private không
//   bool _isPrivateGroup(String status) {
//     return status.toLowerCase() == 'private';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final vm = context.watch<PostGroupViewModel>();

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: vm.isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : NestedScrollView(
//               headerSliverBuilder: (context, innerBoxIsScrolled) {
//                 return [
//                   SliverAppBar(
//                     expandedHeight: 280.0,
//                     floating: false,
//                     pinned: true,
//                     backgroundColor: Colors.white,
//                     foregroundColor: AppColors.textPrimary,
//                     elevation: 0,
                    
//                     leading: IconButton(
//                       icon: Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(innerBoxIsScrolled ? 0 : 0.9),
//                           shape: BoxShape.circle,
//                           boxShadow: innerBoxIsScrolled ? [] : [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.2),
//                               blurRadius: 8,
//                             ),
//                           ],
//                         ),
//                         child: const Icon(Icons.arrow_back, size: 20),
//                       ),
//                       onPressed: () => Navigator.pop(context),
//                     ),
                    
//                     actions: [
//                       Container(
//                         margin: const EdgeInsets.only(right: 8),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(innerBoxIsScrolled ? 0 : 0.9),
//                           shape: BoxShape.circle,
//                           boxShadow: innerBoxIsScrolled ? [] : [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.2),
//                               blurRadius: 8,
//                             ),
//                           ],
//                         ),
//                         child: IconButton(
//                           icon: const Icon(Icons.search, size: 22),
//                           tooltip: 'Tìm kiếm',
//                           onPressed: () {
//                             // TODO: Implement search
//                           },
//                         ),
//                       ),
//                       Container(
//                         margin: const EdgeInsets.only(right: 12),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(innerBoxIsScrolled ? 0 : 0.9),
//                           shape: BoxShape.circle,
//                           boxShadow: innerBoxIsScrolled ? [] : [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.2),
//                               blurRadius: 8,
//                             ),
//                           ],
//                         ),
//                         child: PopupMenuButton(
//                           icon: const Icon(Icons.more_horiz, size: 22),
//                           tooltip: 'Tùy chọn',
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           itemBuilder: (context) => [
//                             PopupMenuItem(
//                               child: const Row(
//                                 children: [
//                                   Icon(Icons.person_add_outlined, size: 20),
//                                   SizedBox(width: 12),
//                                   Text('Thêm thành viên'),
//                                 ],
//                               ),
//                               onTap: () {
//                                 Future.delayed(Duration.zero, () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => AddMembersView(groupId: vm.group.id),
//                                     ),
//                                   );
//                                 });
//                               },
//                             ),
//                             PopupMenuItem(
//                               child: const Row(
//                                 children: [
//                                   Icon(Icons.info_outline, size: 20),
//                                   SizedBox(width: 12),
//                                   Text('Thông tin nhóm'),
//                                 ],
//                               ),
//                               onTap: () {
//                                 Future.delayed(Duration.zero, () {
//                                   Navigator.pushNamed(
//                                     context,
//                                     '/group_management',
//                                     arguments: vm.group.id,
//                                   );
//                                 });
//                               },
//                             ),
//                             PopupMenuItem(
//                               child: const Row(
//                                 children: [
//                                   Icon(Icons.notifications_outlined, size: 20),
//                                   SizedBox(width: 12),
//                                   Text('Cài đặt thông báo'),
//                                 ],
//                               ),
//                               onTap: () {
//                                 // TODO: Notification settings
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],

//                     flexibleSpace: FlexibleSpaceBar(
//                       centerTitle: false,
//                       titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
//                       title: AnimatedOpacity(
//                         opacity: innerBoxIsScrolled ? 1.0 : 0.0,
//                         duration: const Duration(milliseconds: 200),
//                         child: Text(
//                           vm.group.name,
//                           style: const TextStyle(
//                             color: AppColors.textPrimary,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                           ),
//                         ),
//                       ),
//                       background: Stack(
//                         fit: StackFit.expand,
//                         children: [
//                           // Background image
//                           vm.group.coverImage.isNotEmpty
//                               ? CachedNetworkImage(
//                                   imageUrl: vm.group.coverImage,
//                                   fit: BoxFit.cover,
//                                   placeholder: (context, url) => Container(
//                                     color: Colors.grey[300],
//                                     child: const Center(
//                                       child: CircularProgressIndicator(),
//                                     ),
//                                   ),
//                                   errorWidget: (context, url, error) => Container(
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(
//                                         colors: [
//                                           AppColors.primary,
//                                           AppColors.primary.withOpacity(0.7)
//                                         ],
//                                         begin: Alignment.topLeft,
//                                         end: Alignment.bottomRight,
//                                       ),
//                                     ),
//                                     child: const Center(
//                                       child: Icon(
//                                         Icons.groups,
//                                         size: 80,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               : Container(
//                                   decoration: BoxDecoration(
//                                     gradient: LinearGradient(
//                                       colors: [
//                                         AppColors.primary,
//                                         AppColors.primary.withOpacity(0.7)
//                                       ],
//                                       begin: Alignment.topLeft,
//                                       end: Alignment.bottomRight,
//                                     ),
//                                   ),
//                                   child: const Center(
//                                     child: Icon(
//                                       Icons.groups,
//                                       size: 80,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),
                          
//                           // Gradient overlay
//                           Container(
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [
//                                   Colors.transparent,
//                                   Colors.black.withOpacity(0.7),
//                                 ],
//                                 begin: Alignment.topCenter,
//                                 end: Alignment.bottomCenter,
//                                 stops: const [0.5, 1.0],
//                               ),
//                             ),
//                           ),
                          
//                           // Group info at bottom
//                           Positioned(
//                             left: 16,
//                             right: 16,
//                             bottom: 16,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   vm.group.name,
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                     shadows: [
//                                       Shadow(
//                                         color: Colors.black45,
//                                         blurRadius: 8,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 const SizedBox(height: 6),
//                                 Row(
//                                   children: [
//                                     Icon(
//                                       _isPrivateGroup(vm.group.status)
//                                           ? Icons.lock
//                                           : Icons.public,
//                                       color: Colors.white,
//                                       size: 16,
//                                     ),
//                                     const SizedBox(width: 6),
//                                     Text(
//                                       _isPrivateGroup(vm.group.status) ? 'Nhóm riêng tư' : 'Nhóm công khai',
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500,
//                                         shadows: [
//                                           Shadow(
//                                             color: Colors.black45,
//                                             blurRadius: 4,
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     const Text(
//                                       '•',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 14,
//                                       ),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     Icon(
//                                       Icons.people,
//                                       color: Colors.white,
//                                       size: 16,
//                                     ),
//                                     const SizedBox(width: 6),
//                                     Text(
//                                       '${vm.group.members.length} thành viên',
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w500,
//                                         shadows: [
//                                           Shadow(
//                                             color: Colors.black45,
//                                             blurRadius: 4,
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ];
//               },
//               body: _buildBodyWithPosts(context, vm),
//             ),
//     );
//   }

//   Widget _buildBodyWithPosts(BuildContext context, PostGroupViewModel vm) {
//     if (vm.currentUserData == null) {
//       return const Center(child: Text("Không thể tải dữ liệu người dùng"));
//     }

//     return Container(
//       color: Colors.grey[100],
//       child: StreamBuilder<List<PostModel>>(
//         stream: vm.postsStream,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Lỗi tải bài viết: ${snapshot.error}'));
//           }

//           final posts = snapshot.data ?? [];

//           return ListView(
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             children: [
//               _buildCreatePostSection(context, vm),
//               const SizedBox(height: 8),
//               _buildQuickActions(context, vm),
//               if (posts.isNotEmpty) const SizedBox(height: 8),
//               if (posts.isEmpty)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 40.0),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.article_outlined,
//                         size: 80,
//                         color: Colors.grey[400],
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         "Chưa có bài viết nào trong nhóm",
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         "Hãy là người đầu tiên chia sẻ điều gì đó!",
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey[500],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ...posts.map((post) => Padding(
//                     padding: const EdgeInsets.only(bottom: 8.0),
//                     child: PostWidget(
//                       post: post,
//                       currentUserDocId: vm.currentUserData!.id,
//                     ),
//                   )).toList(),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildCreatePostSection(BuildContext context, PostGroupViewModel vm) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: InkWell(
//         onTap: () {
//           Navigator.pushNamed(
//             context,
//             '/create_post',
//             arguments: {
//               'currentUser': vm.currentUserData!,
//               'groupId': vm.group.id,
//             },
//           );
//         },
//         borderRadius: BorderRadius.circular(8),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 20,
//               backgroundImage: vm.currentUserData!.avatar.isNotEmpty
//                   ? NetworkImage(vm.currentUserData!.avatar.first)
//                   : null,
//               child: vm.currentUserData!.avatar.isEmpty
//                   ? const Icon(Icons.person, size: 20)
//                   : null,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//                 child: const Text(
//                   'Bạn đang nghĩ gì?',
//                   style: TextStyle(
//                     color: Colors.grey,
//                     fontSize: 15,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.image_outlined,
//                 color: AppColors.primary,
//                 size: 20,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickActions(BuildContext context, PostGroupViewModel vm) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12),
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildQuickActionButton(
//               icon: Icons.people_outline,
//               label: 'Thành viên',
//               onTap: () {
//                 Navigator.pushNamed(
//                   context,
//                   '/group_management',
//                   arguments: vm.group.id,
//                 );
//               },
//             ),
//           ),
//           Container(width: 1, height: 24, color: Colors.grey[300]),
//           Expanded(
//             child: _buildQuickActionButton(
//               icon: Icons.event_outlined,
//               label: 'Sự kiện',
//               onTap: () {
//                 // TODO: Events
//               },
//             ),
//           ),
//           Container(width: 1, height: 24, color: Colors.grey[300]),
//           Expanded(
//             child: _buildQuickActionButton(
//               icon: Icons.more_horiz,
//               label: 'Thêm',
//               onTap: () {
//                 // TODO: More options
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 10),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 20, color: Colors.grey[700]),
//             const SizedBox(width: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/viewmodel/post_group_viewmodel.dart';
import 'package:mangxahoi/view/widgets/post_widget.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangxahoi/view/group_chat/add_members_view.dart';
import 'package:mangxahoi/view/group_chat/group_management_view.dart';

class PostGroupView extends StatelessWidget {
  final GroupModel group;

  const PostGroupView({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostGroupViewModel(group: group),
      child: const _PostGroupViewContent(),
    );
  }
}

class _PostGroupViewContent extends StatelessWidget {
  const _PostGroupViewContent();

  // Helper method để check xem nhóm có private không
  bool _isPrivateGroup(String status) {
    return status.toLowerCase() == 'private';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PostGroupViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 280.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(innerBoxIsScrolled ? 0 : 0.9),
                          shape: BoxShape.circle,
                          boxShadow: innerBoxIsScrolled ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(innerBoxIsScrolled ? 0 : 0.9),
                          shape: BoxShape.circle,
                          boxShadow: innerBoxIsScrolled ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.search, size: 22),
                          tooltip: 'Tìm kiếm',
                          onPressed: () {
                            // TODO: Implement search
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(innerBoxIsScrolled ? 0 : 0.9),
                          shape: BoxShape.circle,
                          boxShadow: innerBoxIsScrolled ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: PopupMenuButton(
                          icon: const Icon(Icons.more_horiz, size: 22),
                          tooltip: 'Tùy chọn',
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.person_add_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('Thêm thành viên'),
                                ],
                              ),
                              onTap: () {
                                Future.delayed(Duration.zero, () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddMembersView(groupId: vm.group.id),
                                    ),
                                  );
                                });
                              },
                            ),
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 20),
                                  SizedBox(width: 12),
                                  Text('Thông tin nhóm'),
                                ],
                              ),
                              onTap: () {
                                Future.delayed(Duration.zero, () {
                                  Navigator.pushNamed(
                                    context,
                                    '/group_management',
                                    arguments: vm.group.id,
                                  );
                                });
                              },
                            ),
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.notifications_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('Cài đặt thông báo'),
                                ],
                              ),
                              onTap: () {
                                // TODO: Notification settings
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: AnimatedOpacity(
                        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          vm.group.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background image
                          vm.group.coverImage.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: vm.group.coverImage,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primary.withOpacity(0.7)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.groups,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.7)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.groups,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                          
                          // Group info at bottom
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  vm.group.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      _isPrivateGroup(vm.group.status)
                                          ? Icons.lock
                                          : Icons.public,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isPrivateGroup(vm.group.status) ? 'Nhóm riêng tư' : 'Nhóm công khai',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black45,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.people,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${vm.group.members.length} thành viên',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black45,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: _buildBodyWithPosts(context, vm),
            ),
    );
  }

  Widget _buildBodyWithPosts(BuildContext context, PostGroupViewModel vm) {
    if (vm.currentUserData == null) {
      return const Center(child: Text("Không thể tải dữ liệu người dùng"));
    }

    // Kiểm tra quyền truy cập
    if (!vm.hasAccess) {
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
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nhóm riêng tư',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn cần là thành viên của nhóm này để xem các bài viết.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[100],
      child: StreamBuilder<List<PostModel>>(
        stream: vm.postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải bài viết: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: [
              _buildCreatePostSection(context, vm),
              const SizedBox(height: 8),
              _buildQuickActions(context, vm),
              if (posts.isNotEmpty) const SizedBox(height: 8),
              if (posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Chưa có bài viết nào trong nhóm",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Hãy là người đầu tiên chia sẻ điều gì đó!",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ...posts.map((post) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: PostWidget(
                      post: post,
                      currentUserDocId: vm.currentUserData!.id,
                    ),
                  )).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreatePostSection(BuildContext context, PostGroupViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/create_post',
            arguments: {
              'currentUser': vm.currentUserData!,
              'groupId': vm.group.id,
            },
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: vm.currentUserData!.avatar.isNotEmpty
                  ? NetworkImage(vm.currentUserData!.avatar.first)
                  : null,
              child: vm.currentUserData!.avatar.isEmpty
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Bạn đang nghĩ gì?',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.image_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, PostGroupViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.people_outline,
              label: 'Thành viên',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/group_management',
                  arguments: vm.group.id,
                );
              },
            ),
          ),
          Container(width: 1, height: 24, color: Colors.grey[300]),
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.event_outlined,
              label: 'Sự kiện',
              onTap: () {
                // TODO: Events
              },
            ),
          ),
          Container(width: 1, height: 24, color: Colors.grey[300]),
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.more_horiz,
              label: 'Thêm',
              onTap: () {
                // TODO: More options
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}