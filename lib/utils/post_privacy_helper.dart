
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
  /// 1. Bài viết của người dùng đã bị chặn: luôn ẩn
  /// 2. Bài viết cá nhân (không có groupId): hiển thị (nếu tác giả không bị chặn)
  /// 3. Bài viết trong nhóm công khai: hiển thị (nếu tác giả không bị chặn)
  /// 4. Bài viết trong nhóm riêng tư: chỉ hiển thị nếu user là thành viên (và tác giả không bị chặn)
  ///
  /// Example:
  /// ```dart
  /// final canView = PostPrivacyHelper.canViewPost(
  ///   post: post,
  ///   currentUser: currentUser,
  ///   group: group,
  ///   blockedUserIds: myBlockedList, // <-- Mới
  /// );
  /// ```
  static bool canViewPost({
    required PostModel post,
    required UserModel currentUser,
    GroupModel? group,
    required Set<String> blockedUserIds, // <-- THÊM MỚI
  }) {
    // Rule 1: Nếu tác giả bài viết nằm trong danh sách bị chặn, ẩn ngay
    if (blockedUserIds.contains(post.authorId)) {
      return false;
    }

    // Nếu bài viết không thuộc nhóm nào, ai cũng xem được (đã qua kiểm tra chặn)
    if (post.groupId == null || post.groupId!.isEmpty) {
      return true;
    }

    // Nếu không có thông tin nhóm, mặc định cho phép xem
    // (sẽ cần load thông tin nhóm từ Firestore nếu cần kiểm tra chặt chẽ hơn)
    if (group == null) {
      return true;
    }

    // Nếu nhóm công khai (status != 'private'), ai cũng xem được (đã qua kiểm tra chặn)
    if (group.status != 'private') {
      return true;
    }

    // Nếu nhóm riêng tư, kiểm tra xem user có phải thành viên không
    return group.members.contains(currentUser.id);
  }

  /// Filter danh sách bài viết dựa trên quyền truy cập và danh sách chặn
  ///
  /// Example:
  /// ```dart
  /// final filteredPosts = PostPrivacyHelper.filterPosts(
  ///   posts: allPosts,
  ///   currentUser: currentUser,
  ///   groupsMap: groupsCache,
  ///   blockedUserIds: myBlockedList, // <-- Mới
  /// );
  /// ```
  static List<PostModel> filterPosts({
    required List<PostModel> posts,
    required UserModel currentUser,
    required Map<String, GroupModel> groupsMap,
    required Set<String> blockedUserIds, // <-- THÊM MỚI
  }) {
    return posts.where((post) {
      // Lấy thông tin nhóm từ map
      final group = groupsMap[post.groupId];

      return canViewPost(
        post: post,
        currentUser: currentUser,
        group: group,
        blockedUserIds: blockedUserIds, // <-- THÊM MỚI
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