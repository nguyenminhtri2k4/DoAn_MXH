import 'package:mangxahoi/model/model_post.dart';
import 'package:mangxahoi/model/model_group.dart';
import 'package:mangxahoi/model/model_user.dart';

/// Helper class để kiểm tra quyền xem bài viết
/// 
/// Sử dụng: PostPrivacyHelper.canViewPost(...)
class PostPrivacyHelper {
  /// Kiểm tra xem user có quyền xem bài viết này không
  /// 
  /// Rules:
  /// 1. Bài viết cá nhân (không có groupId): luôn hiển thị
  /// 2. Bài viết trong nhóm công khai: luôn hiển thị
  /// 3. Bài viết trong nhóm riêng tư: chỉ hiển thị nếu user là thành viên
  /// 
  /// Example:
  /// ```dart
  /// final canView = PostPrivacyHelper.canViewPost(
  ///   post: post,
  ///   currentUser: currentUser,
  ///   group: group,
  /// );
  /// ```
  static bool canViewPost({
    required PostModel post,
    required UserModel currentUser,
    GroupModel? group,
  }) {
    // Nếu bài viết không thuộc nhóm nào, ai cũng xem được
    if (post.groupId == null || post.groupId!.isEmpty) {
      return true;
    }

    // Nếu không có thông tin nhóm, mặc định cho phép xem
    // (sẽ cần load thông tin nhóm từ Firestore nếu cần kiểm tra chặt chẽ hơn)
    if (group == null) {
      return true;
    }

    // Nếu nhóm công khai (status != 'private'), ai cũng xem được
    if (group.status != 'private') {
      return true;
    }

    // Nếu nhóm riêng tư, kiểm tra xem user có phải thành viên không
    return group.members.contains(currentUser.id);
  }

  /// Filter danh sách bài viết dựa trên quyền truy cập
  /// 
  /// Example:
  /// ```dart
  /// final filteredPosts = PostPrivacyHelper.filterPosts(
  ///   posts: allPosts,
  ///   currentUser: currentUser,
  ///   groupsMap: groupsCache,
  /// );
  /// ```
  static List<PostModel> filterPosts({
    required List<PostModel> posts,
    required UserModel currentUser,
    required Map<String, GroupModel> groupsMap,
  }) {
    return posts.where((post) {
      // Nếu không có groupId, luôn hiển thị
      if (post.groupId == null || post.groupId!.isEmpty) {
        return true;
      }

      // Lấy thông tin nhóm từ map
      final group = groupsMap[post.groupId];
      
      return canViewPost(
        post: post,
        currentUser: currentUser,
        group: group,
      );
    }).toList();
  }

  /// Kiểm tra xem user có phải thành viên của nhóm không
  static bool isMemberOfGroup(GroupModel group, String userId) {
    return group.members.contains(userId);
  }

  /// Kiểm tra xem nhóm có phải là nhóm riêng tư không
  static bool isPrivateGroup(GroupModel group) {
    return group.status == 'private';
  }

  /// Kiểm tra xem user có quyền đăng bài trong nhóm không
  static bool canPostInGroup(GroupModel group, String userId) {
    // Phải là thành viên mới được đăng bài
    if (!group.members.contains(userId)) {
      return false;
    }

    // TODO: Thêm logic kiểm tra quyền đăng bài dựa trên settings
    // Ví dụ: chỉ admin/manager mới được đăng bài
    
    return true;
  }
}