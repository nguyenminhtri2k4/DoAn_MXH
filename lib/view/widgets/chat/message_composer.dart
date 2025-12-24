import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangxahoi/viewmodel/chat_viewmodel.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/view/widgets/chat/media_preview.dart';

class MessageComposer extends StatelessWidget {
  final ChatViewModel vm;

  const MessageComposer({required this.vm});

  void _showMediaOptions(BuildContext context, ChatViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Chọn tệp đính kèm',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMediaOption(
                        icon: Icons.image_outlined,
                        label: 'Hình ảnh',
                        onTap: () {
                          Navigator.pop(context);
                          vm.pickImages();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMediaOption(
                        icon: Icons.videocam_outlined,
                        label: 'Video',
                        onTap: () {
                          Navigator.pop(context);
                          vm.pickVideo();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMediaOption(
                        icon: Icons.file_present_outlined,
                        label: 'Tài liệu',
                        onTap: () {
                          Navigator.pop(context);
                          vm.pickFile();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: const BoxDecoration(color: AppColors.backgroundLight),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            MediaPreview(viewModel: vm),
            Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.image_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: vm.isLoading ? null : () => _showMediaOptions(context, vm),
                ),
                IconButton(
                  icon: Icon(
                    Icons.location_on_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: vm.isLoading ? null : () async {
                    await vm.sendCurrentLocation();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: vm.messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                vm.isLoading
                    ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : IconButton(
                      icon: const Icon(Icons.send),
                      iconSize: 25.0,
                      color: Theme.of(context).primaryColor,
                      onPressed: vm.isLoading ? null : vm.sendMessage,
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}