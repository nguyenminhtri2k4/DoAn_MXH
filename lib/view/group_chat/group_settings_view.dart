import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/model_group.dart';
import '../../viewmodel/group_settings_viewmodel.dart';
import '../../constant/app_colors.dart';

class GroupSettingsView extends StatefulWidget {
  final GroupModel group;
  const GroupSettingsView({Key? key, required this.group}) : super(key: key);

  @override
  State<GroupSettingsView> createState() => _GroupSettingsViewState();
}

class _GroupSettingsViewState extends State<GroupSettingsView> {
  late String _currentJoinPermission;
  late String _currentPostPermission;

  @override
  void initState() {
    super.initState();
    _currentJoinPermission = widget.group.settings['join_permission'] ?? 'requires_approval';
    _currentPostPermission = widget.group.settings['post_permission'] ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupSettingsViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Cài đặt nhóm"),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
        ),
        body: Consumer<GroupSettingsViewModel>(
          builder: (context, vm, child) {
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ==================== QUYỀN THAM GIA ====================
                    const Text(
                      "Quyền tham gia",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Kiểm soát cách thành viên mới tham gia nhóm của bạn.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    _buildRadioOption(
                      title: "Cần phê duyệt",
                      subtitle: "Thành viên phải gửi yêu cầu và chờ quản trị viên duyệt.",
                      value: 'requires_approval',
                      currentValue: _currentJoinPermission,
                      onChanged: (newValue) async {
                        setState(() {
                          _currentJoinPermission = newValue;
                        });
                        await vm.updateJoinPermission(widget.group, newValue);
                      },
                      isLoading: vm.isLoading,
                    ),

                    _buildRadioOption(
                      title: "Không cần phê duyệt",
                      subtitle: "Bất kỳ ai cũng có thể tham gia ngay lập tức.",
                      value: 'open',
                      currentValue: _currentJoinPermission,
                      onChanged: (newValue) async {
                        setState(() {
                          _currentJoinPermission = newValue;
                        });
                        await vm.updateJoinPermission(widget.group, newValue);
                      },
                      isLoading: vm.isLoading,
                    ),

                    _buildRadioOption(
                      title: "Không cho tham gia",
                      subtitle: "Tạm khóa nhóm, không nhận thêm thành viên mới.",
                      value: 'closed',
                      currentValue: _currentJoinPermission,
                      onChanged: (newValue) async {
                        setState(() {
                          _currentJoinPermission = newValue;
                        });
                        await vm.updateJoinPermission(widget.group, newValue);
                      },
                      isLoading: vm.isLoading,
                    ),

                    const SizedBox(height: 32),

                    // ==================== QUYỀN ĐĂNG BÀI (Chỉ hiện với type = 'post') ====================
                    if (widget.group.type == 'post') ...[
                      const Text(
                        "Quyền đăng bài",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Kiểm soát ai có thể đăng bài trong nhóm.",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      _buildRadioOption(
                        title: "Tất cả thành viên",
                        subtitle: "Bất kỳ thành viên nào cũng có thể đăng bài.",
                        value: 'all',
                        currentValue: _currentPostPermission,
                        onChanged: (newValue) async {
                          setState(() {
                            _currentPostPermission = newValue;
                          });
                          await vm.updatePostPermission(widget.group, newValue);
                        },
                        isLoading: vm.isLoading,
                      ),

                      _buildRadioOption(
                        title: "Chỉ quản trị viên",
                        subtitle: "Chỉ chủ nhóm và quản trị viên mới có thể đăng bài.",
                        value: 'managers',
                        currentValue: _currentPostPermission,
                        onChanged: (newValue) async {
                          setState(() {
                            _currentPostPermission = newValue;
                          });
                          await vm.updatePostPermission(widget.group, newValue);
                        },
                        isLoading: vm.isLoading,
                      ),

                      _buildRadioOption(
                        title: "Chỉ chủ nhóm",
                        subtitle: "Chỉ chủ nhóm mới có thể đăng bài.",
                        value: 'owner',
                        currentValue: _currentPostPermission,
                        onChanged: (newValue) async {
                          setState(() {
                            _currentPostPermission = newValue;
                          });
                          await vm.updatePostPermission(widget.group, newValue);
                        },
                        isLoading: vm.isLoading,
                      ),
                    ],
                  ],
                ),

                if (vm.isLoading)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required String value,
    required String currentValue,
    required Function(String) onChanged,
    required bool isLoading,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentValue == value ? AppColors.primary : Colors.grey.shade300,
          width: currentValue == value ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: currentValue == value ? AppColors.primary : Colors.black,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        value: value,
        groupValue: currentValue,
        activeColor: AppColors.primary,
        //enabled: !isLoading,
        onChanged: (newValue) {
          if (newValue != null && !isLoading) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
}