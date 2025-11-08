// --- SỬA LỖI Ở DÒNG IMPORT DƯỚI ĐÂY ---
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import 'package:mangxahoi/model/model_user.dart';
import 'package:mangxahoi/request/group_request.dart';
import 'package:mangxahoi/request/user_request.dart';

class AddMembersViewModel extends ChangeNotifier {
  final GroupRequest _groupRequest = GroupRequest();
  final UserRequest _userRequest = UserRequest();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Danh sách master
  List<UserModel> _allAvailableUsers = []; 
  // Danh sách đã lọc để hiển thị
  List<UserModel> _filteredUsers = []; 
  
  // Getter này trả về danh sách đã lọc
  List<UserModel> get availableUsers => _filteredUsers; 

  final Set<UserModel> _selectedUsers = {};
  Set<UserModel> get selectedUsers => _selectedUsers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadUsers(String groupId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // 1. Lấy thành viên hiện tại của nhóm
      final groupDoc = await _firestore.collection('Group').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Không tìm thấy nhóm');
      }
      final currentMemberIds = List<String>.from(groupDoc.data()?['members'] ?? []);
      final currentMemberIdSet = Set<String>.from(currentMemberIds);

      // 2. Lấy tất cả user (dùng hàm từ user_request.dart)
      final allUsers = await _userRequest.getAllUsersForCache();

      // 3. Lọc ra những người chưa có trong nhóm
      _allAvailableUsers = allUsers.where((user) {
        return !currentMemberIdSet.contains(user.id);
      }).toList();

      // 4. Ban đầu, danh sách lọc chính là danh sách đầy đủ
      _filteredUsers = List.from(_allAvailableUsers);

    } catch (e) {
      _errorMessage = 'Lỗi tải danh sách: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Hàm mới để tìm kiếm
  void searchUsers(String query) {
    if (query.isEmpty) {
      // Nếu không tìm kiếm, hiển thị lại đầy đủ
      _filteredUsers = List.from(_allAvailableUsers);
    } else {
      // Nếu có tìm kiếm, lọc từ danh sách master
      _filteredUsers = _allAvailableUsers
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  // Chọn hoặc bỏ chọn một người dùng
  void toggleUserSelection(UserModel user) {
    if (_selectedUsers.contains(user)) {
      _selectedUsers.remove(user);
    } else {
      _selectedUsers.add(user);
    }
    notifyListeners();
  }

  // Thêm các thành viên đã chọn vào nhóm
  Future<bool> addSelectedMembers(String groupId) async {
    if (_selectedUsers.isEmpty) {
      _errorMessage = 'Vui lòng chọn ít nhất một thành viên';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _groupRequest.addMembersToGroup(groupId, _selectedUsers.toList());
      _selectedUsers.clear();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Thêm thành viên thất bại: $e';
      _setLoading(false);
      return false;
    }
  }
}