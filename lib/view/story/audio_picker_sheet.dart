import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangxahoi/constant/app_colors.dart';
import 'package:mangxahoi/model/model_audio.dart';
import 'package:mangxahoi/request/audio_request.dart';
import 'package:mangxahoi/viewmodel/upload_audio_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

class AudioPickerSheet extends StatelessWidget {
  const AudioPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 5),
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Âm thanh có sẵn'),
                Tab(text: 'Tải lên của bạn'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _AvailableAudioTab(),
                  _UploadAudioTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab 1: Hiển thị danh sách âm thanh có sẵn
class _AvailableAudioTab extends StatefulWidget {
  const _AvailableAudioTab();

  @override
  State<_AvailableAudioTab> createState() => _AvailableAudioTabState();
}

class _AvailableAudioTabState extends State<_AvailableAudioTab> {
  final AudioRequest audioRequest = AudioRequest();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPreview(AudioModel audio) {
    if (_currentlyPlayingId == audio.id) {
      // Đang phát, nhấn lần nữa để dừng
      _audioPlayer.stop();
      setState(() {
        _currentlyPlayingId = null;
      });
    } else {
      // Phát bài mới
      _audioPlayer.play(UrlSource(audio.url));
      setState(() {
        _currentlyPlayingId = audio.id;
      });
      // Tự dừng khi hết
      _audioPlayer.onPlayerComplete.first.then((_) {
        if(mounted) {
          setState(() {
            _currentlyPlayingId = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AudioModel>>(
      stream: audioRequest.getAvailableAudio(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải âm thanh: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Chưa có âm thanh nào.'));
        }

        final audios = snapshot.data!;
        return ListView.builder(
          itemCount: audios.length,
          itemBuilder: (context, index) {
            final audio = audios[index];
            final bool isPlaying = _currentlyPlayingId == audio.id;

            return ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: audio.coverImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(audio.coverImageUrl)
                    : null,
                child: audio.coverImageUrl.isEmpty
                    ? const Icon(Icons.music_note, color: Colors.white)
                    : null,
                backgroundColor: Colors.grey[300],
              ),
              title: Text(audio.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(audio.uploaderId), // Bạn có thể dùng FirestoreListener để lấy tên
              trailing: IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: AppColors.primary),
                onPressed: () => _playPreview(audio),
              ),
              onTap: () {
                // Trả về audio đã chọn
                _audioPlayer.stop(); // Dừng nhạc nền
                Navigator.pop(context, audio);
              },
            );
          },
        );
      },
    );
  }
}


// Tab 2: Giao diện cho phép người dùng tự upload
class _UploadAudioTab extends StatelessWidget {
  const _UploadAudioTab();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UploadAudioViewModel(),
      child: Consumer<UploadAudioViewModel>(
        builder: (context, vm, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ô nhập Tên âm thanh
                TextFormField(
                  controller: vm.nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên âm thanh *',
                    hintText: 'Ví dụ: Nhạc nền chill...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                     focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                   validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nút chọn file âm thanh
                ElevatedButton.icon(
                  onPressed: vm.pickAudioFile,
                  icon: const Icon(Icons.audiotrack_outlined),
                  label: Text(vm.audioFile == null ? 'Chọn file âm thanh *' : 'Đã chọn: ${vm.audioFile!.path.split('/').last}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 16),

                // Nút chọn ảnh bìa (tùy chọn)
                OutlinedButton.icon(
                  onPressed: vm.pickCoverImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(vm.coverFile == null ? 'Chọn ảnh bìa (Tùy chọn)' : 'Đã chọn ảnh bìa'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                if (vm.coverFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(vm.coverFile!, height: 100, width: 100, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 24),

                // Nút Tải lên
                if (vm.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: () async {
                      final newAudio = await vm.uploadAudio(context);
                      if (newAudio != null && context.mounted) {
                        // Tải lên thành công, trả về audio
                        Navigator.pop(context, newAudio);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tải lên và Sử dụng'),
                  ),
                
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}