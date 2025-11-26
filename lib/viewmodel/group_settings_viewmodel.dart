import 'package:flutter/material.dart';
import '../model/model_group.dart';
import '../request/group_request.dart';

class GroupSettingsViewModel extends ChangeNotifier {
  final GroupRequest _groupRequest = GroupRequest();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Hàm thay đổi quyền tham gia
  Future<void> updateJoinPermission(GroupModel group, String permissionType) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sao chép settings cũ để giữ các cài đặt khác
      Map<String, dynamic> updatedSettings = Map.from(group.settings);
      
      // Cập nhật key 'join_permission'
      updatedSettings['join_permission'] = permissionType;

      // Gọi Request để update Firestore
      await _groupRequest.updateJoinPermission(group.id, permissionType);
      
    } catch (e) {
      print("❌ Lỗi update join permission: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
   Future<void> updatePostPermission(GroupModel group, String permissionType) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sao chép settings cũ để giữ các cài đặt khác
      Map<String, dynamic> updatedSettings = Map.from(group.settings);
      
      // Cập nhật key 'post_permission'
      updatedSettings['post_permission'] = permissionType;

      // Gọi Request để update Firestore
      await _groupRequest.updatePostPermission(group.id, permissionType);
      
    } catch (e) {
      print("❌ Lỗi update post permission: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}