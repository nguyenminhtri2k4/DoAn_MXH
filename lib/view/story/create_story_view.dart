import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_audio.dart';
import 'package:mangxahoi/view/story/audio_picker_sheet.dart';
import 'package:mangxahoi/viewmodel/create_story_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CreateStoryView extends StatelessWidget {
  const CreateStoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateStoryViewModel(),
      child: Consumer<CreateStoryViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: Colors.black,
            resizeToAvoidBottomInset: false, // Tránh đẩy UI lên khi mở bàn phím
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                // Nút Thêm âm thanh
                IconButton(
                  tooltip: 'Thêm âm thanh',
                  icon: Icon(
                    vm.selectedAudio != null ? Icons.music_note : Icons.music_note_outlined, 
                    color: vm.selectedAudio != null ? AppColors.primary : Colors.white
                  ),
                  onPressed: () async {
                    final AudioModel? selectedAudio = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent, // Nền trong suốt
                      builder: (_) => const AudioPickerSheet(),
                    );
                    if (selectedAudio != null) {
                      vm.setSelectedAudio(selectedAudio);
                    }
                  },
                ),
                // Nút Chọn ảnh/video
                IconButton(
                  tooltip: 'Chọn ảnh/video',
                  icon: Icon(
                    Icons.image_outlined, 
                    color: vm.storyType != StoryType.text ? AppColors.primary : Colors.white
                  ),
                  onPressed: () => vm.pickMedia(ImageSource.gallery, StoryType.image),
                ),
                // Nút Tạo text
                IconButton(
                  tooltip: 'Tạo story chữ',
                  icon: Icon(
                    Icons.text_fields, 
                    color: vm.storyType == StoryType.text ? AppColors.primary : Colors.white
                  ),
                  onPressed: () => vm.setStoryType(StoryType.text),
                ),
              ],
            ),
            body: Stack(
              children: [
                // Nền hiển thị (Ảnh / Text)
                _buildStoryPreview(vm),

                // Nút Đăng Story
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: ElevatedButton.icon(
                    onPressed: vm.isLoading ? null : () async {
                      bool success = await vm.postStory(context);
                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: vm.isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Icon(Icons.send, size: 18),
                    label: Text(vm.isLoading ? 'Đang đăng...' : 'Đăng Story'),
                  ),
                ),

                // Hiển thị chip âm thanh đã chọn
                if (vm.selectedAudio != null)
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Chip(
                      backgroundColor: Colors.black.withOpacity(0.6),
                      avatar: CircleAvatar(
                        backgroundImage: vm.selectedAudio!.coverImageUrl.isNotEmpty 
                            ? CachedNetworkImageProvider(vm.selectedAudio!.coverImageUrl)
                            : null,
                        child: vm.selectedAudio!.coverImageUrl.isEmpty ? const Icon(Icons.music_note, size: 16) : null,
                      ),
                      label: Text(vm.selectedAudio!.name, style: const TextStyle(color: Colors.white)),
                      onDeleted: () {
                        vm.setSelectedAudio(null);
                      },
                      deleteIconColor: Colors.white70,
                    ),
                  ),
                
                // Báo lỗi
                if (vm.errorMessage != null)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Text(
                        vm.errorMessage!, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoryPreview(CreateStoryViewModel vm) {
    if (vm.storyType == StoryType.text) {
      // Giao diện cho Story text
      return Container(
        // Chuyển đổi String màu sang Color
        color: vm.backgroundColor.isNotEmpty 
             ? Color(int.parse(vm.backgroundColor.split('(0x')[1].split(')')[0], radix: 16)) 
             : Colors.blue,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: TextField(
              onChanged: (value) => vm.setStoryContent(value),
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Nhập nội dung...',
                hintStyle: TextStyle(color: Colors.white70, fontSize: 26),
              ),
            ),
          ),
        ),
      );
    }

    // Giao diện cho Story ảnh/video
    if (vm.selectedMedia != null) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.file(
          File(vm.selectedMedia!.path),
          fit: BoxFit.cover,
        ),
      );
    }

    // Giao diện mặc định (chưa chọn gì)
    return InkWell(
      onTap: () => vm.pickMedia(ImageSource.gallery, StoryType.image),
      child: Container(
        color: Colors.grey[900],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, color: Colors.white54, size: 60),
              SizedBox(height: 16),
              Text(
                'Nhấn để chọn ảnh/video',
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}